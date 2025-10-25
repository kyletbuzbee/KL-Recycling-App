import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'model_a_adapter.dart';
import 'model_b_adapter.dart';
import 'performance_tracker.dart';

/// AI Model Comparison Screen
/// Side-by-side testing of different AI weight prediction approaches
class AIModelComparisonScreen extends StatefulWidget {
  const AIModelComparisonScreen({super.key});

  @override
  State<AIModelComparisonScreen> createState() => _AIModelComparisonScreenState();
}

class _AIModelComparisonScreenState extends State<AIModelComparisonScreen> {
  // Model adapters
  final ModelAAdapter _modelA = ModelAAdapter();
  final ModelBAdapter _modelB = ModelBAdapter();
  final PerformanceMetrics _performanceTracker = PerformanceMetrics();

  // UI State
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _showResults = false;
  bool _isModelBActive = true; // Default to advanced model

  // Image and Results
  File? _selectedImage;
  ModelAResult? _modelAResult;
  ModelBResult? _modelBResult;

  // Test Data
  String _currentImageId = '';
  double? _groundTruthWeight;

  @override
  void initState() {
    super.initState();
    _initializeModels();
  }

  Future<void> _initializeModels() async {
    setState(() => _isInitialized = false);

    try {
      await Future.wait([
        _modelA.initialize(),
        _modelB.initialize(),
      ]);

      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Model initialization failed: $e');
      // Continue with partial functionality if possible
      setState(() => _isInitialized = true);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _showResults = false;
        _currentImageId = 'test_${DateTime.now().millisecondsSinceEpoch}';
        _groundTruthWeight = null; // Reset ground truth for new image

        _modelAResult = null;
        _modelBResult = null;
      });
    }
  }

  Future<void> _runComparison() async {
    if (_selectedImage == null || !_isInitialized) return;

    setState(() {
      _isProcessing = true;
      _showResults = false;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();

      // Run both models concurrently
      final results = await Future.wait([
        _runModelA(imageBytes),
        _runModelB(imageBytes),
      ]);

      setState(() {
        _modelAResult = results[0] as ModelAResult?;
        _modelBResult = results[1] as ModelBResult?;
        _showResults = true;
      });

    } catch (e) {
      debugPrint('Comparison failed: $e');
      _performanceTracker.recordError('comparison_system', e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<ModelAResult?> _runModelA(Uint8List imageBytes) async {
    try {
      final result = await _modelA.predictWeight(imageBytes);
      _performanceTracker.addPrediction(
        PredictionResult(
          weight: result.weight,
          confidence: result.confidence,
          method: 'Model A: ${result.method}',
          inferenceTime: result.inferenceTime,
          metadata: result.metadata ?? {},
          imageId: _currentImageId,
        ),
        _groundTruthWeight != null,
        _groundTruthWeight,
      );
      return result;
    } catch (e) {
      debugPrint('Model A failed: $e');
      _performanceTracker.recordError('model_a', e.toString());
      return null;
    }
  }

  Future<ModelBResult?> _runModelB(Uint8List imageBytes) async {
    try {
      final result = await _modelB.predictWeight(imageBytes);
      _performanceTracker.addPrediction(
        PredictionResult(
          weight: result.weight,
          confidence: result.confidence,
          method: 'Model B: ${result.method}',
          inferenceTime: result.inferenceTime,
          metadata: result.metadata ?? {},
          imageId: _currentImageId,
        ),
        _groundTruthWeight != null,
        _groundTruthWeight,
      );
      return result;
    } catch (e) {
      debugPrint('Model B failed: $e');
      _performanceTracker.recordError('model_b', e.toString());
      return null;
    }
  }

  void _toggleModel() {
    setState(() => _isModelBActive = !_isModelBActive);
  }

  Widget _buildModelResultCard(String title, dynamic result, Color color, bool isSelected) {
    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? color.withOpacity(0.1) : null,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isSelected) const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            const SizedBox(height: 16),

            if (result == null)
              const Text(
                '❌ Model failed to process image',
                style: TextStyle(color: Colors.red),
              )
            else ...[
              Text(
                '${result.weight.toStringAsFixed(1)} lbs',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  _buildConfidenceIndicator(result.confidence),
                  const SizedBox(width: 16),
                  Text(
                    '${result.inferenceTime.inMilliseconds}ms',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(
                result.method,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),

              if (result.metadata.containsKey('simulation') &&
                  result.metadata['simulation'] == true)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '🔧 Using simulated data for demonstration',
                    style: TextStyle(fontSize: 10, color: Colors.orange[700]),
                  ),
                ),

              // Show ground truth comparison if available
              if (_groundTruthWeight != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ground Truth: ${_groundTruthWeight!.toStringAsFixed(1)} lbs',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Difference: ${(result.weight - _groundTruthWeight!).abs().toStringAsFixed(1)} lbs',
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        'Accuracy: ${(_groundTruthWeight! > 0 ?
                            ((1 - (result.weight - _groundTruthWeight!).abs() / _groundTruthWeight!) * 100).toStringAsFixed(0) : '0')}%',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    Color color;
    String label;

    if (confidence >= 0.8) {
      color = Colors.green;
      label = 'High';
    } else if (confidence >= 0.6) {
      color = Colors.orange;
      label = 'Medium';
    } else {
      color = Colors.red;
      label = 'Low';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label ${(confidence * 100).toInt()}%',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _generateComparisonReport() async {
    final report = _performanceTracker.generateComparisonReport();

    // In a real app, this could show in a dialog or save to file
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comparison Report'),
        content: SingleChildScrollView(
          child: Text(report),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Model Comparison'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _generateComparisonReport,
            tooltip: 'Generate Report',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _performanceTracker.clear,
            tooltip: 'Clear Data',
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Scrap Metal Image',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _pickImage(ImageSource.camera),
                                  icon: const Icon(Icons.camera),
                                  label: const Text('Camera'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _pickImage(ImageSource.gallery),
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Gallery'),
                                ),
                              ),
                            ],
                          ),

                          // Ground truth input
                          const SizedBox(height: 16),
                          TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Ground Truth Weight (lbs) - Optional',
                              hintText: 'Enter actual weight for accuracy validation',
                            ),
                            onChanged: (value) {
                              _groundTruthWeight = double.tryParse(value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Selected image preview
                  if (_selectedImage != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Image',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImage!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: ElevatedButton(
                                onPressed: _isProcessing ? null : _runComparison,
                                child: _isProcessing
                                    ? const CircularProgressIndicator()
                                    : const Text('Run AI Comparison'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Results comparison
                  if (_showResults) ...[
                    const SizedBox(height: 16),
                    Text(
                      'AI Model Results',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),

                    _buildModelResultCard(
                      'Model A: ML Kit Detection',
                      _modelAResult,
                      Colors.blue,
                      !_isModelBActive,
                    ),

                    _buildModelResultCard(
                      'Model B: Custom TFLite Ensemble',
                      _modelBResult,
                      Colors.green,
                      _isModelBActive,
                    ),

                    const SizedBox(height: 16),
                    Card(
                      color: Colors.grey.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🎯 Recommendation',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildRecommendation(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _toggleModel,
                            child: Text(
                              'Switch to ${_isModelBActive ? "Model A" : "Model B"}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _pickImage(ImageSource.camera),
                            child: const Text('Try Another Image'),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 32),
                  Text(
                    'Total Comparisons: ${_performanceTracker.predictions.length}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRecommendation() {
    if (_modelAResult == null && _modelBResult == null) {
      return const Text('Unable to make recommendation - both models failed');
    }

    double? modelAConfidence = _modelAResult?.confidence;
    double? modelBConfidence = _modelBResult?.confidence;
    int? modelATime = _modelAResult?.inferenceTime.inMilliseconds;
    int? modelBTime = _modelBResult?.inferenceTime.inMilliseconds;

    // Simple recommendation logic
    if (modelAConfidence == null && modelBConfidence != null) {
      return const Text('Model A failed - Use Model B (Custom TFLite Ensemble)');
    } else if (modelBConfidence == null && modelAConfidence != null) {
      return const Text('Model B failed - Use Model A (ML Kit Detection)');
    } else if (modelAConfidence == null || modelBConfidence == null) {
      return const Text('Both models failed - Manual estimation recommended');
    }

    // Compare based on confidence and speed
    if (modelBConfidence > modelAConfidence + 0.1) {
      return Text(
        'Model B recommended (${(modelBConfidence * 100).toInt()}% vs ${(modelAConfidence * 100).toInt()}% confidence)',
      );
    } else if (modelAConfidence > modelBConfidence + 0.1) {
      return Text(
        'Model A recommended (${(modelAConfidence * 100).toInt()}% vs ${(modelBConfidence * 100).toInt()}% confidence)',
      );
    } else if (modelATime != null && modelBTime != null && modelBTime < modelATime * 0.8) {
      return Text(
        'Model B recommended (faster: ${modelBTime}ms vs ${modelATime}ms)',
      );
    } else {
      return Text(
        'Both models similar (${(modelAConfidence * 100).toInt()}% confidence) - choose based on requirements',
      );
    }
  }

  @override
  void dispose() {
    _modelA.dispose();
    _modelB.dispose();
    super.dispose();
  }
}
