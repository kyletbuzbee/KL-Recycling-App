#!/usr/bin/env python3
"""
KL Recycling Model Trainer
===========================

Advanced training pipeline for scrap metal detection and weight prediction models.
Supports multiple architectures (YOLOv8, EfficientDet, ResNet) with comprehensive
experiment tracking and optimization.

Usage:
    python train_model.py --model yolo_v8 --dataset data/scrap_dataset/ --name scrap_detector_v1
    python train_model.py --model resnet50 --task weight_prediction --dataset data/scrap_dataset/
"""

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
import logging
from datetime import datetime

import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
import torchvision.transforms as transforms
from torch.optim.lr_scheduler import CosineAnnealingLR

import numpy as np
import pandas as pd
import yaml
from tqdm import tqdm
import wandb
from ultralytics import YOLO
import mlflow
import mlflow.pytorch

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('training.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


class ScrapMetalDataset(Dataset):
    """Custom dataset for scrap metal detection and weight prediction."""

    def __init__(self, data_dir: str, transform=None, task: str = "detection"):
        self.data_dir = Path(data_dir)
        self.transform = transform
        self.task = task

        # Load annotations
        self.annotations = self._load_annotations()

    def _load_annotations(self) -> List[Dict[str, Any]]:
        """Load JSON annotations from data directory."""
        annotations = []

        for json_file in self.data_dir.glob("*.json"):
            try:
                with open(json_file, 'r') as f:
                    annotation = json.load(f)
                    annotations.append(annotation)
            except Exception as e:
                logger.warning(f"Failed to load annotation {json_file}: {e}")

        logger.info(f"Loaded {len(annotations)} annotations from {self.data_dir}")
        return annotations

    def __len__(self):
        return len(self.annotations)

    def __getitem__(self, idx):
        annotation = self.annotations[idx]

        # Load image
        image_path = Path(annotation['image_path'])
        if not image_path.exists():
            # Try different path variations
            image_path = self.data_dir / annotation.get('filename', annotation['image_path'].split('/')[-1])

        if not image_path.exists():
            raise FileNotFoundError(f"Image not found: {image_path}")

        image = Image.open(image_path).convert('RGB')

        if self.task == "detection":
            # Return object detection format (YOLO format)
            targets = self._prepare_detection_targets(annotation)
            if self.transform:
                image, targets = self._apply_transform(image, targets)
            return image, targets

        elif self.task == "weight_prediction":
            # Return weight prediction format
            weight = annotation['weight_pounds']
            if self.transform:
                image = self.transform(image)
            return image, torch.tensor([weight], dtype=torch.float32)

    def _prepare_detection_targets(self, annotation: Dict[str, Any]) -> Dict[str, Any]:
        """Prepare targets for object detection."""
        # Convert from pascal_voc format to YOLO format
        bbox = annotation['bounding_box']  # [x, y, w, h]
        material_idx = self._material_to_idx(annotation['material_type'])

        return {
            'boxes': torch.tensor([bbox], dtype=torch.float32),
            'labels': torch.tensor([material_idx], dtype=torch.int64),
            'weights': torch.tensor([annotation['weight_pounds']], dtype=torch.float32)
        }

    def _material_to_idx(self, material: str) -> int:
        """Convert material name to class index."""
        material_map = {
            'steel': 0,
            'aluminum': 1,
            'copper': 2,
            'brass': 3,
            'mixed_scrap': 4
        }
        return material_map.get(material, 0)


class ModelTrainer:
    """
    Main training engine supporting multiple model architectures and tasks.
    """

    def __init__(self, config_path: str = "config/training_config.yaml"):
        self.config = self._load_config(config_path)

        # Device configuration
        self.device = self._setup_device()

        # Setup monitoring
        if self.config['monitoring']['wandb'].get('enabled', False):
            self._setup_wandb()

        logger.info(f"ModelTrainer initialized on device: {self.device}")

    def _load_config(self, config_path: str) -> Dict[str, Any]:
        """Load training configuration."""
        with open(config_path, 'r') as f:
            config = yaml.safe_load(f)
        return config

    def _setup_device(self) -> torch.device:
        """Setup training device (GPU/CPU)."""
        if torch.cuda.is_available() and self.config['training']['device'] != 'cpu':
            device = torch.device('cuda')
            logger.info(f"Using GPU: {torch.cuda.get_device_name()}")
            torch.cuda.empty_cache()
        else:
            device = torch.device('cpu')
            logger.info("Using CPU for training")

        return device

    def _setup_wandb(self):
        """Setup Weights & Biases monitoring."""
        wandb_config = self.config['monitoring']['wandb']
        wandb.init(
            project=wandb_config['project'],
            entity=wandb_config['entity'],
            name=f"scrap_metal_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        )

    def train_yolo_v8(self, dataset_path: str, model_size: str = "medium", epochs: int = 100):
        """
        Train YOLOv8 model for scrap metal object detection.
        """
        logger.info(f"Training YOLOv8 ({model_size}) model for {epochs} epochs")

        # Load model
        model = YOLO(f'yolov8{model_size}.pt')  # Load pretrained weights

        # Training configuration
        training_config = {
            'data': str(Path(dataset_path) / 'data.yaml'),  # Create data config
            'epochs': epochs,
            'batch': self.config['models']['object_detection']['yolo_v8']['batch_size'],
            'imgsz': self.config['models']['object_detection']['yolo_v8']['input_size'],
            'optimizer': 'adam',
            'lr0': self.config['models']['object_detection']['yolo_v8']['learning_rate'],
            'weight_decay': self.config['models']['object_detection']['yolo_v8']['weight_decay'],
            'momentum': self.config['models']['object_detection']['yolo_v8']['momentum'],
            'augment': True,
            'mosaic': 1.0,  # Enable mosaic augmentation
            'mixup': 0.1,   # Enable mixup augmentation
            'project': 'models/detection',
            'name': f'scrap_detector_{datetime.now().strftime("%Y%m%d_%H%M%S")}',
            'save': True,
            'save_period': 5,
            'verbose': True
        }

        # Train the model
        results = model.train(**training_config)

        # Save model in various formats
        model_path = f"models/detection/scrap_detector_{model_size}/weights/best.pt"
        tflite_path = f"models/detection/scrap_detector_{model_size}/scrap_detector_{model_size}.tflite"

        # Convert to TFLite for mobile deployment
        self._convert_yolo_to_tflite(model_path, tflite_path)

        return {
            'model_path': model_path,
            'tflite_path': tflite_path,
            'results': results
        }

    def _convert_yolo_to_tflite(self, model_path: str, tflite_path: str):
        """Convert YOLOv8 model to TensorFlow Lite format."""
        logger.info(f"Converting YOLO model to TFLite: {model_path} -> {tflite_path}")

        # This would implement actual conversion
        # For now, this is a placeholder for the conversion process
        pass

    def train_weight_predictor(self, dataset_path: str, architecture: str = "resnet50", epochs: int = 50):
        """
        Train CNN model for weight prediction.
        """
        logger.info(f"Training weight predictor with {architecture} for {epochs} epochs")

        # Create datasets
        train_dataset = self._create_weight_dataset(dataset_path, 'train')
        val_dataset = self._create_weight_dataset(dataset_path, 'val')

        train_loader = DataLoader(train_dataset, batch_size=32, shuffle=True)
        val_loader = DataLoader(val_dataset, batch_size=32, shuffle=False)

        # Create model
        model = self._build_weight_predictor(architecture)
        model.to(self.device)

        # Training setup
        optimizer = optim.Adam(model.parameters(), lr=0.001, weight_decay=1e-4)
        scheduler = CosineAnnealingLR(optimizer, T_max=epochs)
        criterion = nn.MSELoss()

        # Training loop
        best_val_loss = float('inf')
        patience_counter = 0

        for epoch in range(epochs):
            # Train
            train_loss = self._train_epoch(model, train_loader, optimizer, criterion)

            # Validate
            val_loss = self._validate_epoch(model, val_loader, criterion)

            # Logging
            self._log_training_progress(epoch, train_loss, val_loss)

            # Early stopping
            if val_loss < best_val_loss:
                best_val_loss = val_loss
                patience_counter = 0
                self._save_checkpoint(model, f"models/weight_estimator/{architecture}_best.pth")
            else:
                patience_counter += 1

            if patience_counter >= self.config['training'].get('patience', 10):
                logger.info("Early stopping triggered")
                break

            scheduler.step()

        # Save final model
        final_path = f"models/weight_estimator/{architecture}_final.pth"
        torch.save(model.state_dict(), final_path)

        # Convert to TFLite
        tflite_path = self._convert_weight_model_to_tflite(model, architecture)

        return {
            'model_path': final_path,
            'tflite_path': tflite_path,
            'final_val_loss': best_val_loss
        }

    def _create_weight_dataset(self, dataset_path: str, split: str) -> ScrapMetalDataset:
        """Create weight prediction dataset."""
        split_path = Path(dataset_path) / split

        transform = transforms.Compose([
            transforms.Resize(self.config['models']['weight_prediction']['cnn_regressor']['input_size']),
            transforms.ToTensor(),
            transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
        ])

        return ScrapMetalDataset(split_path, transform=transform, task="weight_prediction")

    def _build_weight_predictor(self, architecture: str) -> nn.Module:
        """Build weight prediction model."""
        if architecture == "resnet50":
            model = torch.hub.load('pytorch/vision:v0.10.0', 'resnet50', pretrained=True)

            # Modify for regression
            num_features = model.fc.in_features
            model.fc = nn.Sequential(
                nn.Linear(num_features, 512),
                nn.ReLU(),
                nn.Dropout(0.3),
                nn.Linear(512, 128),
                nn.ReLU(),
                nn.Dropout(0.2),
                nn.Linear(128, 1)
            )

        else:
            raise ValueError(f"Unsupported architecture: {architecture}")

        return model

    def _train_epoch(self, model: nn.Module, train_loader: DataLoader,
                    optimizer: optim.Optimizer, criterion: nn.Module) -> float:
        """Train for one epoch."""
        model.train()
        total_loss = 0.0

        for images, targets in tqdm(train_loader, desc="Training"):
            images, targets = images.to(self.device), targets.to(self.device)

            optimizer.zero_grad()
            outputs = model(images)
            loss = criterion(outputs, targets)
            loss.backward()
            optimizer.step()

            total_loss += loss.item()

        return total_loss / len(train_loader)

    def _validate_epoch(self, model: nn.Module, val_loader: DataLoader,
                       criterion: nn.Module) -> float:
        """Validate for one epoch."""
        model.eval()
        total_loss = 0.0

        with torch.no_grad():
            for images, targets in tqdm(val_loader, desc="Validating"):
                images, targets = images.to(self.device), targets.to(self.device)

                outputs = model(images)
                loss = criterion(outputs, targets)

                total_loss += loss.item()

        return total_loss / len(val_loader)

    def _log_training_progress(self, epoch: int, train_loss: float, val_loss: float):
        """Log training progress."""
        logger.info(f"Epoch {epoch+1}: Train Loss = {train_loss:.4f}, Val Loss = {val_loss:.4f}")

        if wandb.run:
            wandb.log({
                "epoch": epoch,
                "train_loss": train_loss,
                "val_loss": val_loss
            })

    def _save_checkpoint(self, model: nn.Module, path: str):
        """Save model checkpoint."""
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        torch.save(model.state_dict(), path)

    def _convert_weight_model_to_tflite(self, model: nn.Module, architecture: str) -> str:
        """Convert PyTorch model to TensorFlow Lite."""
        # Placeholder for model conversion
        tflite_path = f"models/weight_estimator/{architecture}.tflite"
        logger.info(f"Model conversion placeholder: {tflite_path}")
        return tflite_path

    def create_data_config(self, dataset_path: str, output_path: str):
        """Create YOLO format data configuration file."""
        config = {
            'path': str(Path(dataset_path).parent),
            'train': 'scrap_dataset/train',
            'val': 'scrap_dataset/val',
            'test': 'scrap_dataset/test',
            'names': {
                0: 'steel',
                1: 'aluminum',
                2: 'copper',
                3: 'brass',
                4: 'mixed_scrap'
            },
            'nc': 5,  # number of classes
            'download': False
        }

        with open(output_path, 'w') as f:
            yaml.dump(config, f)

        logger.info(f"Data config created: {output_path}")


def main():
    parser = argparse.ArgumentParser(description="KL Recycling Model Trainer")
    parser.add_argument("--model", required=True,
                       choices=["yolo_v8", "efficient_det", "resnet50", "vgg16"],
                       help="Model architecture to train")
    parser.add_argument("--task", choices=["detection", "weight_prediction"],
                       default="detection", help="Training task")
    parser.add_argument("--dataset", required=True, help="Path to dataset directory")
    parser.add_argument("--name", default=None, help="Model name for saving")
    parser.add_argument("--epochs", type=int, default=None, help="Number of training epochs")
    parser.add_argument("--batch_size", type=int, default=None, help="Batch size")
    parser.add_argument("--config", default="config/training_config.yaml",
                       help="Path to training configuration file")

    args = parser.parse_args()

    # Initialize trainer
    trainer = ModelTrainer(args.config)

    # Generate model name if not provided
    model_name = args.name or f"{args.model}_{args.task}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

    logger.info(f"Starting training: {args.model} for {args.task} task")

    try:
        if args.model == "yolo_v8" and args.task == "detection":
            # Create data config for YOLO
            data_config_path = Path(args.dataset) / "data.yaml"
            trainer.create_data_config(args.dataset, str(data_config_path))

            # Train YOLO model
            epochs = args.epochs or trainer.config['models']['object_detection']['yolo_v8']['epochs']
            result = trainer.train_yolo_v8(args.dataset, epochs=epochs)

        elif args.model in ["resnet50", "vgg16"] and args.task == "weight_prediction":
            # Train weight predictor
            epochs = args.epochs or trainer.config['models']['weight_prediction']['cnn_regressor']['epochs']
            result = trainer.train_weight_predictor(args.dataset, args.model, epochs=epochs)

        else:
            raise ValueError(f"Unsupported model/task combination: {args.model}/{args.task}")

        logger.info("Training completed successfully!")

        # Print results
        print("\n" + "="*60)
        print("TRAINING RESULTS")
        print("="*60)
        for key, value in result.items():
            if isinstance(value, dict):
                print(f"{key}:")
                for sub_key, sub_value in value.items():
                    print(f"  {sub_key}: {sub_value}")
            else:
                print(f"{key}: {value}")
        print("="*60)

    except Exception as e:
        logger.error(f"Training failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
