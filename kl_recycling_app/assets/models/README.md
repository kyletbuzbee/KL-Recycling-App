# TensorFlow Lite Models

This directory contains the machine learning models used by the Enhanced Weight Prediction Service.

## Required Models

Place the following TensorFlow Lite models in this directory:

### 1. `scrap_metal_detector.tflite`
- **Purpose**: Primary object detection model for scrap metal
- **Input**: 224x224 RGB image (normalized 0-1)
- **Output**: Bounding boxes, class scores, confidence values
- **Training**: Custom trained on various scrap metal types

### 2. `depth_estimator.tflite` (Optional)
- **Purpose**: Monocular depth estimation for volume calculation
- **Input**: 224x224 RGB image (normalized 0-1)
- **Output**: Depth map (224x224 float values)
- **Training**: Pre-trained depth estimation model

### 3. `shape_classifier.tflite` (Optional)
- **Purpose**: Classifies scrap metal shape categories
- **Input**: 224x224 RGB image (normalized 0-1)
- **Output**: Probabilities for 20 different shape categories
- **Training**: Custom trained on scrap metal shapes

### 4. `ensemble_model.tflite` (Optional)
- **Purpose**: Combines predictions from multiple models
- **Input**: Feature vector from other model outputs
- **Output**: Final weight prediction
- **Training**: Meta-model trained on ensemble features

## Model Format

- All models must be in TensorFlow Lite format (.tflite)
- Input tensors should accept float32 values normalized 0-1
- Models should be optimized for mobile inference
- Consider using quantization for better performance

## Fallback Behavior

The service is designed to work gracefully when models are missing:
- If primary model (scrap_metal_detector) is missing, uses enhanced fallback
- Optional models (depth, shape, ensemble) are loaded only if available
- System continues with reduced functionality when models aren't available

## Training Data

For custom model training, collect data using the built-in data collection feature. All predictions are stored in `assets/data/prediction_data.jsonl` for analysis and training.

## Performance Considerations

- Models are loaded asynchronously during service initialization
- Memory is managed properly with explicit dispose calls
- Consider model size vs. accuracy trade-offs for mobile deployment
- Test models on target devices for performance benchmarking
