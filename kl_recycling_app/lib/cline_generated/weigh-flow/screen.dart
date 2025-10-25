/// Weigh Flow Screen
/// Compose-style Flutter UI for capturing images, showing predictions, and submitting for training
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/camera_provider.dart';
import 'view_model.dart';
import 'tflite_helper.dart';
import 'repository.dart';

class WeighFlowScreen extends StatefulWidget {
  const WeighFlowScreen({super.key});

  @override
  State<WeighFlowScreen> createState() => _WeighFlowScreenState();
}

class _WeighFlowScreenState extends State<WeighFlowScreen> {
  late WeighFlowViewModel _viewModel;
  final TextEditingController _weightController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _viewModel = WeighFlowViewModel(
      tfliteHelper: TFLiteHelper(),
      repository: ItemRepository(),
    );
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Weigh Flow'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            Consumer<WeighFlowViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.state == WeighFlowState.completed) {
                  return IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: viewModel.reset,
                    tooltip: 'Start New Session',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: Consumer<WeighFlowViewModel>(
          builder: (context, viewModel, child) {
            return _buildBody(viewModel);
          },
        ),
      ),
    );
  }

  Widget _buildBody(WeighFlowViewModel viewModel) {
    switch (viewModel.state) {
      case WeighFlowState.initial:
        return _buildLoadingState('Initializing...');

      case WeighFlowState.cameraReady:
        return _buildCameraReadyState();

      case WeighFlowState.imageCaptured:
        return _buildImageCapturedState();

      case WeighFlowState.processing:
        return _buildProcessingState();

      case WeighFlowState.predictionReady:
        return _buildPredictionReadyState();

      case WeighFlowState.submitting:
        return _buildSubmittingState();

      case WeighFlowState.completed:
        return _buildCompletedState();

      case WeighFlowState.error:
        return _buildErrorState();

      default:
        return _buildLoadingState('Unknown state');
    }
  }

  Widget _buildLoadingState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildCameraReadyState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Capture Scrap Metal Image',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Consumer<CameraProvider>(
                builder: (context, cameraProvider, child) {
                  if (!cameraProvider.isInitialized || cameraProvider.controller == null) {
                    return const Center(
                      child: Text('Camera not available\nTap below to use gallery'),
                    );
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CameraPreview(cameraProvider.controller!),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _takePicture,
                  icon: const Icon(Icons.camera),
                  label: const Text('Take Photo'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Position your scrap metal clearly in the frame and ensure good lighting.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImageCapturedState() {
    final viewModel = context.watch<WeighFlowViewModel>();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Image Captured',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: viewModel.capturedImage != null
                    ? Image.file(
                        viewModel.capturedImage!,
                        fit: BoxFit.cover,
                      )
                    : const Center(child: Text('No image available')),
              ),
            ),
          ),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: viewModel.runPrediction,
            icon: const Icon(Icons.analytics),
            label: const Text('Run AI Prediction'),
          ),

          const SizedBox(height: 8),

          OutlinedButton.icon( // Use context.read for actions
            onPressed: () => context.read<WeighFlowViewModel>().reset(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retake Photo'),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState() {
    return _buildLoadingState('Running AI prediction...');
  }

  Widget _buildPredictionReadyState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'AI Prediction Complete',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Image preview
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: context.watch<WeighFlowViewModel>().capturedImage != null
                  ? Image.file(
                      context.watch<WeighFlowViewModel>().capturedImage!,
                      fit: BoxFit.cover,
                    )
                  : const Center(child: Text('No image')),
            ),
          ),

          const SizedBox(height: 16),

          // Prediction result
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Predicted Weight',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${context.watch<WeighFlowViewModel>().predictedWeight?.toStringAsFixed(1) ?? 'N/A'} lbs',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confidence: ${(context.watch<WeighFlowViewModel>().predictedWeight != null ? 0.75 : 0).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Weight input
          const Text(
            'Enter Measured Weight (lbs)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter actual weight',
              suffixText: 'lbs',
            ),
            onChanged: (value) => context.read<WeighFlowViewModel>().updateMeasuredWeight(value),
          ),

          if (context.watch<WeighFlowViewModel>().errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              context.watch<WeighFlowViewModel>().errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ],

          const SizedBox(height: 16),

          // Submit button
          ElevatedButton.icon(
            onPressed: context.watch<WeighFlowViewModel>().canSubmit ? () => context.read<WeighFlowViewModel>().submitForTraining() : null,
            icon: const Icon(Icons.upload),
            label: const Text('Submit for Training'),
          ),

          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: () => context.read<WeighFlowViewModel>().reset(),
            icon: const Icon(Icons.refresh),
            label: const Text('Start Over'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittingState() {
    return _buildLoadingState('Submitting for training...');
  }

  Widget _buildCompletedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Submission Complete!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your labeled image has been queued for upload and will be used to improve our AI model.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<WeighFlowViewModel>().reset(),
              icon: const Icon(Icons.refresh),
              label: const Text('Process Another Item'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red[700]),
            ),
            const SizedBox(height: 8),
            Text(
              context.watch<WeighFlowViewModel>().errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.read<WeighFlowViewModel>().retry(),
                    child: const Text('Retry'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.read<WeighFlowViewModel>().reset(),
                    child: const Text('Start Over'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePicture() async {
    try {
      final cameraProvider = context.read<CameraProvider>();
      if (cameraProvider.isInitialized) {
        final imagePath = await cameraProvider.takePicture();
        if (imagePath != null) {
          _viewModel.setCapturedImage(File(imagePath));
        }
      } else {
        // Fallback to gallery if camera not available
        await _pickFromGallery();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take picture: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _viewModel.setCapturedImage(File(pickedFile.path));
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
