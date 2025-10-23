#!/bin/bash
# KL Recycling ML Environment Setup Script
# This script sets up the complete ML training environment for scrap metal weight prediction

set -e  # Exit on any error

echo "🚀 Setting up KL Recycling ML Training Environment..."
echo "=================================================="

# Check if we're in the right directory
if [ ! -f "requirements.txt" ]; then
    echo "❌ Error: requirements.txt not found. Please run this script from the ml_training directory."
    exit 1
fi

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not found. Please install Python 3.8+"
    exit 1
fi

PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
REQUIRED_VERSION="3.8"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$PYTHON_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ Python $REQUIRED_VERSION+ required, found $PYTHON_VERSION"
    exit 1
fi

echo "✅ Python $PYTHON_VERSION found"

# Create virtual environment
echo "📦 Creating virtual environment..."
python3 -m venv kl_recycling_ml_env
source kl_recycling_ml_env/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install requirements
echo "⬇️ Installing ML dependencies (this may take several minutes)..."
pip install -r requirements.txt

# Verify installations
echo "🔍 Verifying installations..."

declare -a PACKAGES=("tensorflow" "torch" "opencv-python" "matplotlib" "pandas" "numpy" "ultralytics" "scikit-learn" "albumentations")

for package in "${PACKAGES[@]}"; do
    if python3 -c "import $package" 2>/dev/null; then
        echo "✅ $package installed"
    else
        echo "❌ $package failed to install"
        exit 1
    fi
done

# Setup Jupyter
echo "📚 Setting up Jupyter environment..."
pip install jupyterlab
python3 -c "
import jupyterlab
print('✅ JupyterLab installed')

# Create default config
import os
if not os.path.exists('notebooks'):
    os.makedirs('notebooks')

print('📁 Created notebooks directory')
"

# Setup directories
echo "📁 Setting up project directories..."
mkdir -p data/{raw_images,processed_images,augmented_images,annotations,metrics,scrap_dataset/{train,val,test}}
mkdir -p models/{detection,weight_estimator,checkpoints}
mkdir -p scripts
mkdir -p config
mkdir -p docs
mkdir -p logs

# Download sample data (if available)
echo "📦 Setting up sample data..."
# Create sample data structure
cat > data/README.md << 'EOF'
# Training Data Directory Structure

## Raw Images
- raw_images/steel/          # Raw scrap steel photos
- raw_images/aluminum/       # Raw scrap aluminum photos
- raw_images/copper/         # Raw scrap copper photos
- raw_images/brass/          # Raw scrap brass photos

## Processed Data
- processed_images/          # Quality-checked and formatted images
- annotations/               # JSON annotation files with weight data
- scrap_dataset/             # Final dataset ready for training
  ├── train/                 # Training split
  ├── val/                   # Validation split
  └── test/                  # Test split

## Data Collection Tips
1. Use good lighting and multiple angles
2. Include reference objects (coins, batteries, etc.)
3. Vary distances and compositions
4. Label actual weights accurately
5. Use run scripts/data_processor.py to prepare data
EOF

# Create training guide
echo "📖 Creating training documentation..."
cat > docs/training_quick_start.md << 'EOF'
# Training Quick Start Guide

## 1. Data Collection
```bash
# Collect images for all material types
python scripts/data_processor.py --collect --materials steel aluminum copper brass --count 200

# Process and validate raw images
python scripts/data_processor.py --process --input data/raw_images/ --output data/processed_images/
```

## 2. Train Object Detection Model
```bash
# Train YOLOv8 detection model
python scripts/train_model.py --model yolo_v8 --dataset data/scrap_dataset/ --name scrap_detector_v1
```

## 3. Train Weight Prediction Model
```bash
# Train ResNet weight predictor
python scripts/train_model.py --model resnet50 --task weight_prediction --dataset data/scrap_dataset/
```

## 4. Deploy Models to App
```bash
# Convert and deploy models
python scripts/deploy_model.py --detection-model models/detection/scrap_detector/weights/best.pt \
                              --weight-model models/weight_estimator/resnet50_final.pth \
                              --app ../kl_recycling_app/
```

## 5. Test in Flutter App
```bash
cd ../kl_recycling_app
flutter run --debug
# Take photos and test weight estimation accuracy
```

## Expected Timeline
- **Data Collection**: 1-2 weeks (1000+ images per material)
- **Model Training**: 1-3 days (depends on hardware)
- **Testing & Iteration**: 1-2 weeks
- **Production Ready**: 4-6 weeks from start

## Hardware Requirements
- **GPU**: RTX 3060 or better (8GB+ VRAM)
- **RAM**: 16GB+
- **Storage**: 100GB for datasets and models
EOF

# Create run scripts for common tasks
echo "🏃 Creating automation scripts..."

cat > train_all_models.sh << 'EOF'
#!/bin/bash
# Automated script to train all required models

echo "🎯 Starting complete model training pipeline..."

# Step 1: Process data if needed
if [ ! -d "data/scrap_dataset/train" ]; then
    echo "📦 Processing dataset..."
    python scripts/data_processor.py --process --input data/raw_images/ --output data/processed_images/
fi

# Step 2: Train object detection
echo "🔍 Training object detection model..."
python scripts/train_model.py --model yolo_v8 --dataset data/scrap_dataset/ --name scrap_detector

# Step 3: Train weight prediction
echo "⚖️ Training weight prediction model..."
python scripts/train_model.py --model resnet50 --task weight_prediction --dataset data/scrap_dataset/ --name weight_predictor

# Step 4: Deploy to app
echo "📱 Deploying models to Flutter app..."
python scripts/deploy_model.py --models-dir models/ --app ../kl_recycling_app/

echo "✅ Training pipeline complete!"
echo "🚀 Test the enhanced weight prediction in your Flutter app"
EOF

chmod +x train_all_models.sh

# Final summary
echo ""
echo "🎉 ML Training Environment Setup Complete!"
echo "=========================================="
echo ""
echo "📂 Project structure created:"
echo "   ├── data/          # Training datasets"
echo "   ├── models/        # Trained models"
echo "   ├── notebooks/     # Jupyter experiments"
echo "   ├── scripts/       # Training utilities"
echo "   └── docs/          # Documentation"
echo ""
echo "🚀 Quick start commands:"
echo "   source kl_recycling_ml_env/bin/activate  # Activate environment"
echo "   jupyter lab                              # Start Jupyter"
echo "   ./train_all_models.sh                   # Full training pipeline"
echo ""
echo "📖 Documentation:"
echo "   docs/training_quick_start.md           # Training guide"
echo "   docs/data_collection_guide.md          # Data collection tips"
echo "   README.md                               # Complete documentation"
echo ""
