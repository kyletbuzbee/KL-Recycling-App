#!/usr/bin/env python3
"""
Data Processing Script for Scrap Metal Detection
===============================================

Converts Scrap Metal Dataset to YOLO Format

Usage:
    python process_data.py --input data/raw_images --output data/scrap_dataset

This script:
- Converts JSON annotations to YOLO .txt format
- Creates proper train/val/test splits
- Generates data.yaml configuration
- Validates data integrity
"""

import argparse
import json
import shutil
from pathlib import Path
import yaml
from sklearn.model_selection import train_test_split
import pandas as pd

class ScrapMetalDataProcessor:
    """Process and format scrap metal detection dataset for YOLO training."""

    def __init__(self, raw_data_dir: str, output_dir: str):
        self.raw_data_dir = Path(raw_data_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # YOLO class mapping
        self.class_mapping = {
            'steel': 0,
            'aluminum': 1,
            'copper': 2,
            'brass': 3
        }

        # Image dimensions (typical mobile photo)
        self.img_width = 640
        self.img_height = 480

    def process_dataset(self):
        """Process complete dataset for YOLO training."""
        print("🏭 Processing Scrap Metal Dataset for YOLO Training")
        print("=" * 60)

        # Collect all data
        all_data = self._collect_data()

        if len(all_data) < 20:
            print(f"❌ Insufficient data: {len(all_data)} images found (need 20+)")
            return False

        print(f"✅ Collected {len(all_data)} total images")

        # Convert to YOLO format
        print("\\n🔄 Converting to YOLO format...")
        yolo_data = []
        for item in all_data:
            yolo_item = self._convert_to_yolo_format(item)
            if yolo_item:
                yolo_data.append(yolo_item)

        if len(yolo_data) < 10:
            print(f"❌ Insufficient valid annotations: {len(yolo_data)} found")
            return False

        print(f"✅ Converted {len(yolo_data)} images to YOLO format")

        # Create train/val/test splits
        print("\\n📊 Creating data splits...")
        df = pd.DataFrame(yolo_data)
        train_df, temp_df = train_test_split(df, test_size=0.3, stratify=df['material'], random_state=42)
        val_df, test_df = train_test_split(temp_df, test_size=0.33, stratify=temp_df['material'], random_state=42)

        print(f"📦 Train: {len(train_df)}, Val: {len(val_df)}, Test: {len(test_df)}")

        # Copy files and create labels
        self._create_split('train', train_df)
        self._create_split('val', val_df)
        self._create_split('test', test_df)

        # Generate YOLO data configuration
        self._create_data_yaml()

        print("\\n✅ Dataset processing complete!")
        print(f"📁 Output: {self.output_dir}")

        # Show summary
        self._print_dataset_summary()

        return True

    def _collect_data(self):
        """Collect all image and annotation data."""
        data = []

        for material_dir in self.raw_data_dir.iterdir():
            if material_dir.is_dir() and not any(x in ['train', 'val', 'test'] for x in str(material_dir)):
                material = material_dir.name

                print(f"📂 Processing {material}: ", end="")

                images = list(material_dir.glob('*.jpg'))
                print(f"{len(images)} images")

                for img_path in images:
                    json_path = img_path.with_suffix('.json')

                    if json_path.exists():
                        try:
                            with open(json_path, 'r') as f:
                                annotation = json.load(f)

                            data.append({
                                'image_path': img_path,
                                'json_path': json_path,
                                'material': material,
                                'annotation': annotation
                            })
                        except:
                            print(f"❌ Error reading {json_path}")

        return data

    def _convert_to_yolo_format(self, item):
        """Convert JSON annotation to YOLO format."""
        try:
            annotation = item['annotation']

            # Extract bounding box (YOLO format: normalized to 0-1)
            bbox = annotation.get('bounding_box', [80, 60, 480, 360])

            # Convert absolute coordinates to normalized
            x_min, y_min, x_max, y_max = bbox

            # Calculate center and dimensions
            x_center = (x_min + x_max) / 2 / self.img_width
            y_center = (y_min + y_max) / 2 / self.img_height
            width = (x_max - x_min) / self.img_width
            height = (y_max - y_min) / self.img_height

            # Class ID
            class_id = self.class_mapping.get(annotation.get('material_type', item['material']), 0)

            return {
                'image_path': item['image_path'],
                'material': annotation.get('material_type', item['material']),
                'weight': annotation.get('weight_pounds', 0),
                'bbox_data': f"{class_id} {x_center:.6f} {y_center:.6f} {width:.6f} {height:.6f}",
                'annotation': annotation
            }

        except Exception as e:
            print(f"❌ Error converting {item['image_path'].name}: {e}")
            return None

    def _create_split(self, split_name: str, df: pd.DataFrame):
        """Create a data split with images and labels."""
        split_dir = self.output_dir / split_name
        split_dir.mkdir(exist_ok=True)

        print(f"📝 Creating {split_name} split...")

        for _, row in df.iterrows():
            # Copy image
            img_dest = split_dir / row['image_path'].name
            shutil.copy2(str(row['image_path']), str(img_dest))

            # Create label file
            label_file = img_dest.with_suffix('.txt')
            with open(label_file, 'w') as f:
                f.write(row['bbox_data'] + '\\n')

    def _create_data_yaml(self):
        """Create YOLO data configuration."""
        data_config = {
            'path': str(self.output_dir.absolute()),
            'train': 'train',
            'val': 'val',
            'test': 'test',
            'names': {v: k for k, v in self.class_mapping.items()},  # Reverse mapping
            'nc': len(self.class_mapping)
        }

        config_path = self.output_dir / 'data.yaml'
        with open(config_path, 'w') as f:
            yaml.dump(data_config, f, default_flow_style=False)

        print(f"✅ Created YOLO config: {config_path}")

    def _print_dataset_summary(self):
        """Print dataset statistics."""
        print("\\n📊 Dataset Summary:")
        print("=" * 30)

        total_images = 0
        total_labels = 0

        for split in ['train', 'val', 'test']:
            split_dir = self.output_dir / split
            if split_dir.exists():
                images = list(split_dir.glob('*.jpg'))
                labels = list(split_dir.glob('*.txt'))

                total_images += len(images)
                total_labels += len(labels)

                print(f"{split.capitalize()}: {len(images)} images, {len(labels)} labels")

        # Material breakdown
        material_counts = {}
        for split in ['train', 'val', 'test']:
            split_dir = self.output_dir / split
            if split_dir.exists():
                for label_file in split_dir.glob('*.txt'):
                    try:
                        with open(label_file, 'r') as f:
                            line = f.read().strip()
                            if line:
                                class_id = int(line.split()[0])
                                material = list(self.class_mapping.keys())[class_id]
                                material_counts[material] = material_counts.get(material, 0) + 1
                    except:
                        pass

        print("\\n📦 Material Distribution:")
        for material, count in material_counts.items():
            print(f"  {material}: {count} instances")

        print(f"\\n🎯 Ready for YOLO training: {total_images} images, {total_labels} annotations")


def main():
    parser = argparse.ArgumentParser(description="Process Scrap Metal Dataset for YOLO")
    parser.add_argument('--input', default='data/raw_images', help='Raw data directory')
    parser.add_argument('--output', default='data/scrap_dataset', help='Output dataset directory')

    args = parser.parse_args()

    processor = ScrapMetalDataProcessor(args.input, args.output)
    success = processor.process_dataset()

    if success:
        print("\\n🚀 Ready to train!")
        print(f"YOLO command: yolo train data='{args.output}/data.yaml' model=yolov8m.pt epochs=50")
    else:
        print("\\n❌ Processing failed. Check data and try again.")


if __name__ == "__main__":
    main()
