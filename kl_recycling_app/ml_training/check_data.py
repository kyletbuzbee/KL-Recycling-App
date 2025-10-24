#!/usr/bin/env python3
"""
Check Data Processing Results
=============================

Debug script to verify that data processing worked correctly.
Shows what's in the data folders and validates label files.
"""

from pathlib import Path
import os
import json

def check_data():
    """Check data processing results."""
    print("🔍 Checking Data Processing Results")
    print("=" * 50)

    # Check raw data (source)
    raw_images_dir = Path("data/raw_images")
    print(f"\\n📁 Raw Images (source):")

    total_raw_images = 0
    total_raw_annotations = 0

    if raw_images_dir.exists():
        for material_dir in raw_images_dir.iterdir():
            if material_dir.is_dir():
                images = list(material_dir.glob("*.jpg"))
                jsons = list(material_dir.glob("*.json"))

                total_raw_images += len(images)
                total_raw_annotations += len(jsons)

                print(f"  {material_dir.name}: {len(images)} images, {len(jsons)} annotations")

    print(f"  Total: {total_raw_images} images, {total_raw_annotations} annotations")

    # Check processed data (destination)
    scrap_dataset_dir = Path("data/scrap_dataset")
    print(f"\\n📁 Processed Dataset (YOLO format):")

    if not scrap_dataset_dir.exists():
        print("  ❌ data/scrap_dataset folder doesn't exist!")
        return

    total_processed_images = 0
    total_processed_labels = 0

    for split in ['train', 'val', 'test']:
        split_dir = scrap_dataset_dir / split

        if split_dir.exists():
            images = list(split_dir.glob("*.jpg"))
            labels = list(split_dir.glob("*.txt"))

            total_processed_images += len(images)
            total_processed_labels += len(labels)

            print(f"  {split:5}: {len(images):3} images, {len(labels):3} labels")

            # Check format of first label file
            if labels:
                first_label = labels[0]
                print(f"         Sample label: {first_label.name}")
                try:
                    with open(first_label, 'r') as f:
                        content = f.read().strip()
                        if content:
                            parts = content.split()
                            if len(parts) == 5:
                                print(f"         Content: {content[:50]}...")
                                # Check if values are valid
                                try:
                                    values = [float(x) for x in parts]
                                    all_valid = all(0 <= v <= 1 for v in values[1:])  # 0-1 range for coords
                                    class_valid = 0 <= values[0] <= 3  # 0-3 range for classes
                                    if all_valid and class_valid:
                                        print("         ✅ Valid YOLO format!")
                                    else:
                                        print("         ❌ Invalid value ranges!")
                                except ValueError:
                                    print("         ❌ Could not parse numbers!")
                            else:
                                print(f"         ❌ Wrong number of values: {len(parts)} (need 5)")
                        else:
                            print("         ❌ Empty file!")
                except Exception as e:
                    print(f"         ❌ Read error: {e}")

        else:
            print(f"  {split:5}: ❌ split folder doesn't exist")

    # Check data.yaml
    data_yaml = scrap_dataset_dir / "data.yaml"
    if data_yaml.exists():
        print(f"\\n✅ data.yaml exists: {data_yaml}")
        try:
            import yaml
            with open(data_yaml, 'r') as f:
                config = yaml.safe_load(f)
                print(f"  Classes: {config.get('nc', 0)} materials")
                print(f"  Train path: {config.get('train', 'missing')}")
                print(f"  Val path: {config.get('val', 'missing')}")
        except Exception as e:
            print(f"  ❌ Invalid YAML: {e}")
    else:
        print(f"\\n❌ data.yaml missing")

    # Summary
    print(f"\\n🎯 Summary:")
    print(f"  Raw images: {total_raw_images}")
    print(f"  Processed images: {total_processed_images}")
    print(f"  Processed labels: {total_processed_labels}")

    if total_process_images == total_process_labels and total_process_labels > 0:
        print("  ✅ Data processing appears successful!")
    else:
        print("  ❌ Data processing incomplete - missing labels!")

        if total_raw_images == 0:
            print("    💡 Need to run data generation first")
        elif total_process_labels == 0:
            print("    💡 Need to run data processing")

if __name__ == "__main__":
    check_data()
