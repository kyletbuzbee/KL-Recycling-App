#!/usr/bin/env python3
"""
KL Recycling ML Data Processor
===============================

Comprehensive data collection, processing, and validation pipeline for scrap metal
weight prediction training. Handles image collection, quality assessment, labeling
support, and dataset preparation.

Usage:
    python data_processor.py --collect --materials steel aluminum copper brass
    python data_processor.py --process --input data/raw_images/ --output data/scrap_dataset/
    python data_processor.py --validate --dataset data/scrap_dataset/
"""

import argparse
import json
import os
import shutil
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
import logging
from dataclasses import dataclass
from datetime import datetime

import cv2
import numpy as np
import pandas as pd
from PIL import Image
import yaml
from tqdm import tqdm
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split
import albumentations as A

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('data_processing.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


@dataclass
class ImageQualityMetrics:
    """Quality assessment metrics for training images."""
    brightness: float
    contrast: float
    blurriness: float
    saturation: float
    resolution_width: int
    resolution_height: int
    aspect_ratio: float
    has_reference_object: bool
    overall_score: float


@dataclass
class ScrapMetalAnnotation:
    """Annotation data structure for scrap metal objects."""
    material_type: str
    bounding_box: Tuple[int, int, int, int]  # x, y, w, h
    weight_pounds: float
    confidence: float
    reference_object: Optional[Dict[str, Any]] = None


class ScrapMetalDataProcessor:
    """
    Main data processing engine for KL Recycling scrap metal dataset.
    """

    def __init__(self, config_path: str = "config/training_config.yaml"):
        self.config = self._load_config(config_path)
        self.quality_thresholds = self.config['quality_control']
        self.materials = self.config['dataset']['materials']

        # Initialize data directories
        self._setup_directories()

        # Data augmentation pipeline
        self.augmentor = self._setup_augmentation()

        logger.info("ScrapMetalDataProcessor initialized")

    def _load_config(self, config_path: str) -> Dict[str, Any]:
        """Load training configuration."""
        with open(config_path, 'r') as f:
            config = yaml.safe_load(f)
        logger.info(f"Configuration loaded from {config_path}")
        return config

    def _setup_directories(self):
        """Create necessary directory structure."""
        directories = [
            "data/raw_images",
            "data/processed_images",
            "data/augmented_images",
            "data/annotations",
            "data/metrics",
            "data/scrap_dataset/train",
            "data/scrap_dataset/val",
            "data/scrap_dataset/test",
            "models/checkpoints",
            "logs"
        ]

        for dir_path in directories:
            Path(dir_path).mkdir(parents=True, exist_ok=True)

        logger.info("Directory structure created")

    def _setup_augmentation(self) -> A.Compose:
        """Setup data augmentation pipeline."""
        aug_config = self.config['dataset']['augmentation']

        transforms = [
            A.HorizontalFlip(p=0.5) if aug_config['flip_horizontal'] else None,
            A.VerticalFlip(p=0.5) if aug_config['flip_vertical'] else None,
            A.Rotate(limit=tuple(aug_config['rotation_range']), p=0.7),
            A.RandomBrightnessContrast(
                brightness_limit=tuple(aug_config['brightness_range']),
                contrast_limit=tuple(aug_config['contrast_range']),
                p=0.8
            ),
            A.HueSaturationValue(
                hue_shift_limit=tuple(aug_config['hue_range']),
                sat_shift_limit=tuple(aug_config['saturation_range']),
                val_shift_limit=[-10, 10],
                p=0.7
            ),
            A.Blur(blur_limit=3, p=aug_config['blur_prob']),
            A.GaussNoise(var_limit=(10, 50), p=aug_config['noise_prob']),
        ]

        # Filter out None values
        transforms = [t for t in transforms if t is not None]

        return A.Compose(transforms, bbox_params=A.BboxParams(format='pascal_voc'))

    def collect_images(self, materials: List[str], count_per_material: int = 100):
        """
        Collect images for specified materials using camera input.
        This creates a interface for photographing scrap metal samples.
        """
        logger.info(f"Starting image collection for materials: {materials}")

        collection_stats = {}

        for material in materials:
            if material not in self.materials:
                logger.warning(f"Material {material} not in configured materials")
                continue

            logger.info(f"Collecting {count_per_material} images for {material}")

            material_dir = Path(f"data/raw_images/{material}")
            material_dir.mkdir(parents=True, exist_ok=True)

            collected = 0
            skipped = 0

            # In a real implementation, this would interface with camera SDK
            # For now, we'll create placeholder logic
            for i in range(count_per_material * 2):  # Collect extra for filtering
                image_path = self._capture_image(material, i)

                if image_path and self._validate_image_quality(image_path):
                    collected += 1
                    logger.info(f"Collected {collected}/{count_per_material} for {material}")
                else:
                    skipped += 1

                if collected >= count_per_material:
                    break

            collection_stats[material] = {
                'collected': collected,
                'skipped': skipped,
                'target': count_per_material
            }

        self._save_collection_report(collection_stats)
        logger.info("Image collection completed")

    def _capture_image(self, material: str, index: int) -> Optional[str]:
        """Simulate image capture - would interface with actual camera hardware."""
        # Placeholder implementation
        # In real usage, this would:
        # 1. Open camera stream
        # 2. Show live preview with guidelines
        # 3. Capture image on user input
        # 4. Save to appropriate directory
        return f"data/raw_images/{material}/sample_{index}.jpg"

    def process_dataset(self, input_dir: str, output_dir: str, generate_labels: bool = True):
        """
        Process raw images into training-ready dataset.
        """
        logger.info("Processing dataset...")

        input_path = Path(input_dir)
        output_path = Path(output_dir)

        image_files = list(input_path.rglob("*.jpg")) + list(input_path.rglob("*.png"))

        processed_data = []
        quality_stats = []

        for image_file in tqdm(image_files, desc="Processing images"):
            try:
                # Assess image quality
                quality_metrics = self._assess_image_quality(str(image_file))

                if quality_metrics.overall_score >= 0.7:  # Quality threshold
                    # Copy to processed directory
                    processed_path = self._copy_to_processed(image_file, output_path)

                    # Generate or validate annotations
                    if generate_labels:
                        annotation = self._generate_annotation(str(image_file), quality_metrics)
                        self._save_annotation(processed_path, annotation)

                    processed_data.append({
                        'original_path': str(image_file),
                        'processed_path': str(processed_path),
                        'quality_score': quality_metrics.overall_score,
                        'material_type': self._detect_material_type(str(image_file))
                    })

                quality_stats.append(quality_metrics)

            except Exception as e:
                logger.error(f"Error processing {image_file}: {e}")
                continue

        # Generate dataset splits
        self._create_dataset_splits(processed_data)

        # Save processing report
        self._save_processing_report(processed_data, quality_stats)

        logger.info(f"Dataset processing completed. Processed {len(processed_data)} images")

    def _assess_image_quality(self, image_path: str) -> ImageQualityMetrics:
        """Assess comprehensive image quality metrics."""
        try:
            # Load image
            image = cv2.imread(image_path)
            if image is None:
                raise ValueError("Could not load image")

            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

            # Brightness assessment
            brightness = np.mean(gray) / 255.0

            # Contrast assessment
            contrast = gray.std() / 255.0

            # Blurriness using Laplacian variance
            blurriness = cv2.Laplacian(gray, cv2.CV_64F).var()

            # Saturation assessment
            hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
            saturation = np.mean(hsv[:, :, 1]) / 255.0

            # Basic reference object detection (placeholder)
            has_reference = self._detect_reference_object(image)

            # Calculate overall quality score
            quality_score = self._calculate_quality_score(
                brightness, contrast, blurriness, saturation, has_reference
            )

            return ImageQualityMetrics(
                brightness=brightness,
                contrast=contrast,
                blurriness=blurriness,
                saturation=saturation,
                resolution_width=image.shape[1],
                resolution_height=image.shape[0],
                aspect_ratio=image.shape[1] / image.shape[0],
                has_reference_object=has_reference,
                overall_score=quality_score
            )

        except Exception as e:
            logger.error(f"Quality assessment failed for {image_path}: {e}")
            return ImageQualityMetrics(
                brightness=0.0, contrast=0.0, blurriness=0.0,
                saturation=0.0, resolution_width=0, resolution_height=0,
                aspect_ratio=0.0, has_reference_object=False, overall_score=0.0
            )

    def _calculate_quality_score(self, brightness: float, contrast: float,
                               blurriness: float, saturation: float,
                               has_reference: bool) -> float:
        """Calculate overall quality score from individual metrics."""
        thresholds = self.quality_thresholds['image_quality_checks']

        # Normalize individual scores
        brightness_score = min(brightness / thresholds['brightness_threshold'][1], 1.0)
        contrast_score = min(contrast / thresholds['contrast_threshold'], 1.0)
        blur_score = min(blurriness / thresholds['blur_threshold'], 1.0)
        saturation_score = min(saturation / thresholds['saturation_threshold'], 1.0)
        reference_score = 1.0 if has_reference else 0.5

        # Weighted average
        weights = [0.2, 0.2, 0.3, 0.2, 0.1]
        scores = [brightness_score, contrast_score, blur_score,
                 saturation_score, reference_score]

        return np.average(scores, weights=weights)

    def _detect_reference_object(self, image: np.ndarray) -> bool:
        """Basic reference object detection (placeholder implementation)."""
        # This would implement actual reference object detection
        # For now, return True if image dimensions suggest potential reference object
        return image.shape[1] > self.config['dataset']['min_resolution']

    def _generate_annotation(self, image_path: str, quality_metrics: ImageQualityMetrics) -> ScrapMetalAnnotation:
        """Generate annotation for image (semi-automated)."""
        material_type = self._detect_material_type(image_path)

        # Placeholder bounding box - would be manually labeled or ML-assisted
        bounding_box = (50, 50, 200, 200)  # x, y, w, h

        # Placeholder weight estimation
        weight = self._estimate_weight_from_material(material_type)

        return ScrapMetalAnnotation(
            material_type=material_type,
            bounding_box=bounding_box,
            weight_pounds=weight,
            confidence=quality_metrics.overall_score
        )

    def _detect_material_type(self, image_path: str) -> str:
        """Detect material type from filename or directory structure."""
        path_parts = Path(image_path).parts

        for part in reversed(path_parts):
            if part in self.materials:
                return part

        return "unknown"

    def _estimate_weight_from_material(self, material_type: str) -> float:
        """Basic weight estimation based on material properties."""
        material_props = self.config['materials'].get(material_type, {})
        base_density = material_props.get('density_kg_m3', 7800)  # Default steel density

        # Convert to typical scrap weight range
        weight_kg = base_density * 0.0001  # Rough volumetric estimate
        return weight_kg * 2.20462  # Convert to pounds

    def _copy_to_processed(self, source_path: Path, output_dir: Path) -> Path:
        """Copy image to processed directory with new filename."""
        material = self._detect_material_type(str(source_path))
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

        output_name = f"{material}_{timestamp}_{source_path.name}"
        output_path = output_dir / output_name

        shutil.copy2(source_path, output_path)
        return output_path

    def _save_annotation(self, image_path: Path, annotation: ScrapMetalAnnotation):
        """Save annotation to file."""
        annotation_file = image_path.with_suffix('.json')

        annotation_data = {
            'image_path': str(image_path),
            'material_type': annotation.material_type,
            'bounding_box': annotation.bounding_box,
            'weight_pounds': annotation.weight_pounds,
            'confidence': annotation.confidence,
            'timestamp': datetime.now().isoformat()
        }

        with open(annotation_file, 'w') as f:
            json.dump(annotation_data, f, indent=2)

    def _create_dataset_splits(self, processed_data: List[Dict[str, Any]]):
        """Create train/val/test splits."""
        df = pd.DataFrame(processed_data)

        # Stratified split by material type
        train_df, temp_df = train_test_split(
            df, train_size=self.config['dataset']['train_split'],
            stratify=df['material_type'], random_state=42
        )

        val_df, test_df = train_test_split(
            temp_df,
            train_size=self.config['dataset']['val_split'] /
            (self.config['dataset']['val_split'] + self.config['dataset']['test_split']),
            stratify=temp_df['material_type'], random_state=42
        )

        # Move files to respective directories
        self._move_files_to_splits(train_df, 'train')
        self._move_files_to_splits(val_df, 'val')
        self._move_files_to_splits(test_df, 'test')

        logger.info("Dataset splits created")

    def _move_files_to_splits(self, df: pd.DataFrame, split_name: str):
        """Move files to split directories."""
        split_dir = Path(f"data/scrap_dataset/{split_name}")
        split_dir.mkdir(exist_ok=True)

        for _, row in df.iterrows():
            src_path = Path(row['processed_path'])
            annotation_path = src_path.with_suffix('.json')

            # Move image
            dst_image = split_dir / src_path.name
            shutil.copy2(src_path, dst_image)

            # Move annotation if exists
            if annotation_path.exists():
                dst_annotation = split_dir / annotation_path.name
                shutil.copy2(annotation_path, dst_annotation)

    def validate_dataset(self, dataset_path: str):
        """Validate dataset quality and completeness."""
        logger.info(f"Validating dataset at {dataset_path}")

        dataset_path = Path(dataset_path)
        validation_results = {
            'total_images': 0,
            'valid_images': 0,
            'invalid_images': 0,
            'quality_scores': [],
            'material_distribution': {},
            'issues': []
        }

        image_files = list(dataset_path.rglob("*.jpg")) + list(dataset_path.rglob("*.png"))

        for image_file in tqdm(image_files, desc="Validating images"):
            validation_results['total_images'] += 1

            try:
                # Re-assess quality
                quality_metrics = self._assess_image_quality(str(image_file))

                # Check annotation exists
                annotation_file = image_file.with_suffix('.json')
                has_annotation = annotation_file.exists()

                if quality_metrics.overall_score >= 0.7 and has_annotation:
                    validation_results['valid_images'] += 1
                    validation_results['quality_scores'].append(quality_metrics.overall_score)

                    # Update material distribution
                    material = self._detect_material_type(str(image_file))
                    validation_results['material_distribution'][material] = \
                        validation_results['material_distribution'].get(material, 0) + 1
                else:
                    validation_results['invalid_images'] += 1
                    if quality_metrics.overall_score < 0.7:
                        validation_results['issues'].append({
                            'file': str(image_file),
                            'issue': 'poor_quality',
                            'score': quality_metrics.overall_score
                        })
                    elif not has_annotation:
                        validation_results['issues'].append({
                            'file': str(image_file),
                            'issue': 'missing_annotation'
                        })

            except Exception as e:
                validation_results['invalid_images'] += 1
                validation_results['issues'].append({
                    'file': str(image_file),
                    'issue': str(e)
                })

        # Generate validation report
        self._save_validation_report(validation_results)

        logger.info(f"Validation completed: {validation_results['valid_images']}/{validation_results['total_images']} valid images")

        return validation_results

    def _save_collection_report(self, stats: Dict[str, Dict[str, int]]):
        """Save image collection statistics."""
        report_path = Path("data/metrics/collection_report.json")

        report = {
            'collection_date': datetime.now().isoformat(),
            'statistics': stats,
            'total_collected': sum(s['collected'] for s in stats.values()),
            'total_target': sum(s['target'] for s in stats.values()),
            'success_rate': sum(s['collected'] for s in stats.values()) /
                          max(1, sum(s['target'] for s in stats.values()))
        }

        with open(report_path, 'w') as f:
            json.dump(report, f, indent=2, default=str)

        logger.info(f"Collection report saved to {report_path}")

    def _save_processing_report(self, processed_data: List[Dict[str, Any]], quality_stats: List[ImageQualityMetrics]):
        """Save data processing report."""
        report_path = Path("data/metrics/processing_report.json")

        report = {
            'processing_date': datetime.now().isoformat(),
            'total_processed': len(processed_data),
            'quality_stats': {
                'mean_score': np.mean([q.overall_score for q in quality_stats]),
                'min_score': min([q.overall_score for q in quality_stats] or [0]),
                'max_score': max([q.overall_score for q in quality_stats] or [0]),
                'std_score': np.std([q.overall_score for q in quality_stats] or [0])
            }
        }

        with open(report_path, 'w') as f:
            json.dump(report, f, indent=2, default=str)

        logger.info(f"Processing report saved to {report_path}")

    def _save_validation_report(self, results: Dict[str, Any]):
        """Save dataset validation report."""
        report_path = Path("data/metrics/validation_report.json")

        with open(report_path, 'w') as f:
            json.dump(results, f, indent=2, default=str)

        logger.info(f"Validation report saved to {report_path}")


def main():
    parser = argparse.ArgumentParser(description="KL Recycling ML Data Processor")
    parser.add_argument("--collect", action="store_true", help="Collect new training images")
    parser.add_argument("--process", action="store_true", help="Process raw images into training dataset")
    parser.add_argument("--validate", action="store_true", help="Validate existing dataset")
    parser.add_argument("--materials", nargs="+", help="Materials to collect/process")
    parser.add_argument("--input", help="Input directory for processing")
    parser.add_argument("--output", help="Output directory for processed data")
    parser.add_argument("--dataset", help="Dataset directory for validation")
    parser.add_argument("--count", type=int, default=100, help="Number of images per material")

    args = parser.parse_args()

    # Initialize processor
    processor = ScrapMetalDataProcessor()

    if args.collect:
        materials = args.materials or ["steel", "aluminum", "copper", "brass"]
        processor.collect_images(materials, args.count)

    elif args.process:
        if not args.input or not args.output:
            logger.error("Must specify --input and --output directories for processing")
            sys.exit(1)
        processor.process_dataset(args.input, args.output)

    elif args.validate:
        if not args.dataset:
            logger.error("Must specify --dataset directory for validation")
            sys.exit(1)
        processor.validate_dataset(args.dataset)

    else:
        logger.error("Must specify one of --collect, --process, or --validate")
        parser.print_help()
        sys.exit(1)


if __name__ == "__main__":
    main()
