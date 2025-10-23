#!/usr/bin/env python3
"""
Generate Demo Training Data for Scrap Metal Detection
======================================================

Creates synthetic training images with drawn scrap metal objects for demonstration
and testing of the ML training pipeline.

Usage:
    python generate_demo_data.py --count 100 --materials steel aluminum copper brass
"""

import argparse
import os
import cv2
import numpy as np
from pathlib import Path
import json
from datetime import datetime
import uuid
from tqdm import tqdm


class ScrapMetalDemoGenerator:
    """Generate synthetic scrap metal images for training demonstration."""

    def __init__(self, output_dir: str = "data/raw_images"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Material colors
        self.material_colors = {
            'steel': (128, 128, 128),      # Gray
            'aluminum': (192, 192, 192),  # Silver
            'copper': (184, 115, 51),     # Brown-orange
            'brass': (181, 166, 66)       # Goldish
        }

        # Weight ranges for realistic estimation
        self.weight_ranges = {
            'steel': (5, 50),
            'aluminum': (2, 20),
            'copper': (3, 30),
            'brass': (4, 25)
        }

    def generate_demo_dataset(self, count_per_material: int = 50,
                            materials: list = ['steel', 'aluminum', 'copper', 'brass']):
        """Generate complete demo dataset."""

        print("🏭 Generating Scrap Metal Demo Dataset...")
        print(f"Target: {count_per_material} images per material")
        print(f"Materials: {', '.join(materials)}")

        total_images = 0

        for material in materials:
            material_dir = self.output_dir / material
            material_dir.mkdir(exist_ok=True)

            existing_images = len(list(material_dir.glob('*.jpg')))
            print(f"\n{material}: {existing_images} existing, generating {count_per_material} new images")

            # Generate new images
            for i in tqdm(range(count_per_material), desc=f"Generating {material}"):

                # Create image
                img_name = f"{material}_demo_{i:03d}_{uuid.uuid4().hex[:6]}.jpg"
                img_path = material_dir / img_name

                # Generate image
                self._generate_scrap_image(material, img_path, i)

                total_images += 1

        print(f"\n✅ Generated {total_images} total images!")
        print(f"📁 Located in: {self.output_dir}")

        # Generate statistics
        self._generate_dataset_summary()

        return total_images

    def _generate_scrap_image(self, material: str, output_path: Path, variation: int):
        """Generate a single scrap metal image."""

        # Create base image (640x480 - mobile photo dimensions)
        img = np.full((480, 640, 3), 255, dtype=np.uint8)  # White background

        # Add some background texture
        self._add_background_texture(img)

        # Add reference object (coin)
        self._add_reference_coin(img, variation)

        # Add main scrap metal object
        bbox, weight = self._add_scrap_object(img, material, variation)

        # Save image
        cv2.imwrite(str(output_path), cv2.cvtColor(img, cv2.COLOR_RGB2BGR))

        # Create annotation
        annotation = {
            'filename': output_path.name,
            'material_type': material,
            'weight_pounds': round(weight, 2),
            'bounding_box': bbox,
            'confidence': 1.0,
            'timestamp': datetime.now().isoformat(),
            'has_reference_object': True,
            'generated_demo': True,
            'variation': variation
        }

        # Save annotation
        annotation_path = output_path.with_suffix('.json')
        with open(annotation_path, 'w') as f:
            json.dump(annotation, f, indent=2)

    def _add_background_texture(self, img: np.ndarray):
        """Add realistic background texture."""

        # Add some noise
        noise = np.random.normal(0, 25, img.shape).astype(np.uint8)
        img[:] = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)

        # Add some dirt/grime effects
        for _ in range(np.random.randint(3, 8)):
            # Random dark spots
            x = np.random.randint(0, img.shape[1])
            y = np.random.randint(0, img.shape[0])
            size = np.random.randint(2, 8)
            cv2.circle(img, (x, y), size, (80, 80, 80), -1)

    def _add_reference_coin(self, img: np.ndarray, variation: int):
        """Add a reference coin for scale."""

        # Coin specifications (US Quarter = ~24mm diameter)
        coin_center = (50, img.shape[0] - 50)  # Bottom left
        coin_radius = 25  # ~24mm at typical distances

        # Draw coin
        cv2.circle(img, coin_center, coin_radius, (184, 115, 51), -1)  # Copper color
        cv2.circle(img, coin_center, coin_radius, (0, 0, 0), 2)  # Black border

        # Add relief effect
        cv2.circle(img, (coin_center[0] - 8, coin_center[1] - 8), 3, (200, 200, 200), -1)
        cv2.circle(img, (coin_center[0] + 6, coin_center[1] + 6), 2, (60, 60, 60), -1)

    def _add_scrap_object(self, img: np.ndarray, material: str, variation: int) -> tuple:
        """Add main scrap metal object."""

        # Generate random position (centered but random)
        center_x = img.shape[1] // 2 + np.random.randint(-100, 100)
        center_y = img.shape[0] // 2 + np.random.randint(-80, 80)

        # Object types by material
        if material == 'steel':
            shapes = ['pipe', 'sheet', 'bar']
        elif material == 'aluminum':
            shapes = ['sheet', 'tube', 'can']
        elif material == 'copper':
            shapes = ['wire', 'pipe', 'sheet']
        else:  # brass
            shapes = ['fixture', 'pipe', 'casting']

        shape = shapes[variation % len(shapes)]
        color = self.material_colors[material]

        # Generate bounding box and weight based on shape
        if shape == 'pipe':
            # Circular pipe
            radius = np.random.randint(30, 80)
            cv2.circle(img, (center_x, center_y), radius, color, -1)
            cv2.circle(img, (center_x, center_y), radius, (0, 0, 0), 2)
            bbox = [center_x - radius, center_y - radius, radius*2, radius*2]
            weight = self._estimate_weight(material, 'pipe', radius*2)

        elif shape == 'sheet':
            # Rectangular sheet
            width = np.random.randint(100, 200)
            height = np.random.randint(80, 150)
            x1, y1 = center_x - width//2, center_y - height//2
            cv2.rectangle(img, (x1, y1), (x1+width, y1+height), color, -1)
            cv2.rectangle(img, (x1, y1), (x1+width, y1+height), (0, 0, 0), 2)
            bbox = [x1, y1, width, height]
            weight = self._estimate_weight(material, 'sheet', width * height)

        elif shape == 'bar':
            # Long rectangular bar
            width = np.random.randint(20, 50)
            height = np.random.randint(120, 200)
            x1, y1 = center_x - width//2, center_y - height//2
            cv2.rectangle(img, (x1, y1), (x1+width, y1+height), color, -1)
            cv2.rectangle(img, (x1, y1), (x1+width, y1+height), (0, 0, 0), 2)
            bbox = [x1, y1, width, height]
            weight = self._estimate_weight(material, 'bar', width * height * 1.5)

        elif shape == 'wire':
            # Thin wire/coil
            thickness = np.random.randint(3, 8)
            length = np.random.randint(150, 250)
            x1, y1 = center_x - length//2, center_y - thickness//2
            cv2.rectangle(img, (x1, y1), (x1+length, y1+thickness*2), color, -1)
            bbox = [x1, y1, length, thickness*2]
            weight = self._estimate_weight(material, 'wire', length * thickness)

        elif shape == 'can':
            # Aluminum can
            can_height = np.random.randint(60, 100)
            can_width = np.random.randint(30, 50)
            x1, y1 = center_x - can_width//2, center_y - can_height//2
            cv2.rectangle(img, (x1, y1), (x1+can_width, y1+can_height), color, -1)
            cv2.rectangle(img, (x1, y1), (x1+can_width, y1+can_height), (0, 0, 0), 1)
            bbox = [x1, y1, can_width, can_height]
            weight = self._estimate_weight(material, 'can', can_width * can_height * 0.3)

        else:
            # Default rectangular object
            width = np.random.randint(80, 150)
            height = np.random.randint(80, 150)
            x1, y1 = center_x - width//2, center_y - height//2
            cv2.rectangle(img, (x1, y1), (x1+width, y1+height), color, -1)
            cv2.rectangle(img, (x1, y1), (x1+width, y1+height), (0, 0, 0), 2)
            bbox = [x1, y1, width, height]
            weight = self._estimate_weight(material, 'other', width * height)

        # Add texture/shadows for realism
        self._add_realistic_details(img, bbox, color)

        return bbox, weight

    def _estimate_weight(self, material: str, shape: str, area: int) -> float:
        """Estimate realistic weight based on material properties."""
        base_density = {'steel': 1.0, 'aluminum': 0.35, 'copper': 0.95, 'brass': 0.9}[material]
        weight_mult = {'pipe': 0.8, 'sheet': 1.0, 'bar': 1.2, 'wire': 0.3, 'can': 0.9, 'other': 1.0}[shape]

        # Base weight calculation
        weight = base_density * (area / 10000) * weight_mult * 2

        # Add some realistic variation
        weight *= np.random.uniform(0.8, 1.3)

        # Keep within material ranges
        min_weight, max_weight = self.weight_ranges[material]
        weight = np.clip(weight, min_weight, max_weight)

        return round(weight, 2)

    def _add_realistic_details(self, img: np.ndarray, bbox: list, color: tuple):
        """Add shadows, highlights, and texture for realism."""
        x, y, w, h = bbox

        # Add shadow effect
        shadow_offset = 3
        shadow_color = tuple(max(0, c - 60) for c in color)
        cv2.rectangle(img, (x + shadow_offset, y + shadow_offset),
                     (x + w + shadow_offset, y + h + shadow_offset), shadow_color, -1)

        # Draw main object again over shadow
        cv2.rectangle(img, (x, y), (x+w, y+h), color, -1)
        cv2.rectangle(img, (x, y), (x+w, y+h), (0, 0, 0), 2)

        # Add highlight
        highlight_color = tuple(min(255, c + 40) for c in color)
        cv2.rectangle(img, (x+2, y+2), (x+w-10, y+h-10), highlight_color, -1)

    def _generate_dataset_summary(self):
        """Generate dataset statistics summary."""
        summary = {
            'generation_date': datetime.now().isoformat(),
            'dataset_type': 'synthetic_demo',
            'materials': {},
            'total_images': 0,
            'quality_metrics': {
                'resolution': '640x480',
                'format': 'RGB',
                'has_reference_objects': True
            }
        }

        # Count images per material
        for material_dir in self.output_dir.iterdir():
            if material_dir.is_dir() and not any(x in str(material_dir) for x in ['train', 'val', 'test']):
                images = list(material_dir.glob('*.jpg'))
                summary['materials'][material_dir.name] = len(images)
                summary['total_images'] += len(images)

        # Weight statistics
        weights = []
        for json_file in self.output_dir.rglob('*.json'):
            try:
                with open(json_file, 'r') as f:
                    data = json.load(f)
                    weights.append(data['weight_pounds'])
            except:
                pass

        if weights:
            summary['weight_stats'] = {
                'mean': round(np.mean(weights), 2),
                'min': min(weights),
                'max': max(weights),
                'count': len(weights)
            }

        # Save summary
        with open(self.output_dir.parent / 'dataset_summary.json', 'w') as f:
            json.dump(summary, f, indent=2)

        print(f"\n📊 Dataset Summary:")
        print(f"   Total Images: {summary['total_images']}")
        print(f"   Materials: {', '.join(f'{k}({v})' for k, v in summary['materials'].items())}")
        if 'weight_stats' in summary:
            ws = summary['weight_stats']
            print(f"   Weight Range: {ws['min']}-{ws['max']} lbs (avg {ws['mean']} lbs)")


def main():
    parser = argparse.ArgumentParser(description="Generate Scrap Metal Demo Dataset")
    parser.add_argument('--count', type=int, default=50,
                       help='Number of images per material')
    parser.add_argument('--materials', nargs='+',
                       default=['steel', 'aluminum', 'copper', 'brass'],
                       help='Materials to generate')
    parser.add_argument('--output', default='data/raw_images',
                       help='Output directory base')

    args = parser.parse_args()

    generator = ScrapMetalDemoGenerator(args.output)
    generator.generate_demo_dataset(args.count, args.materials)

    print(f"\n🎉 Demo dataset generated successfully!")
    print(f"📁 Location: {args.output}")
    print(f"\\n🚀 You can now run:")
    print("   python scripts/data_processor.py --process")
    print("   python colab_training.py --train")


if __name__ == "__main__":
    main()
