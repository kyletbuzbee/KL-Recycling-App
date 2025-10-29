import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kl_recycling_app/core/theme.dart';

import 'package:kl_recycling_app/features/camera/logic/camera_provider.dart';
import 'package:kl_recycling_app/features/photo_estimate/models/photo_estimate.dart' as models;
import 'package:kl_recycling_app/core/services/ai/weight_prediction_service.dart' as ai_service;
import 'package:kl_recycling_app/core/widgets/common/custom_card.dart';
import 'package:kl_recycling_app/constants/app_icons.dart';
import 'package:kl_recycling_app/core/widgets/common/app_icon_tile.dart';

class PhotoPreviewScreen extends StatefulWidget {
  final String imagePath;

  const PhotoPreviewScreen({super.key, required this.imagePath});

  @override
  State<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends State<PhotoPreviewScreen> {
  models.MaterialType _selectedMaterial = models.MaterialType.unknown;
  double _estimatedWeight = 0.0;
  final TextEditingController _notesController = TextEditingController();

  late ai_service.EnhancedWeightPredictionService _aiService;
  ai_service.WeightPredictionResult? _aiPrediction;
  bool _isAnalyzing = false;
  bool _serviceInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAIService();
  }

  @override
  void dispose() {
    if (_serviceInitialized) {
      _aiService.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initializeAIService() async {
    try {
      _aiService = ai_service.EnhancedWeightPredictionService();
      await _aiService.initialize();
      _serviceInitialized = true;

      // Now run analysis
      await _analyzeImageAI();
    } catch (e) {
      debugPrint('AI service initialization failed: $e');
      // Continue with manual estimation only
      setState(() {
        _serviceInitialized = false;
      });
    }
  }

  Future<void> _analyzeImageAI() async {
    if (_selectedMaterial == models.MaterialType.unknown || !_serviceInitialized) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _aiService.predictWeightFromImage(
        imagePath: widget.imagePath,
        materialType: _selectedMaterial,
        manualEstimate: _estimatedWeight > 0 ? _estimatedWeight : null,
      );

      if (mounted) {
        setState(() {
          _aiPrediction = result;
          _isAnalyzing = false;

          // Auto-suggest AI weight if user hasn't entered anything
          if (_estimatedWeight == 0.0 && result.estimatedWeight > 0) {
            _estimatedWeight = result.estimatedWeight;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI analysis failed: ${e.toString()}'),
        backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  void _onMaterialChanged(models.MaterialType material) {
    setState(() {
      _selectedMaterial = material;
      // Clear previous AI result when material changes
      _aiPrediction = null;
    });
    // Re-analyze with new material
    _analyzeImageAI();
  }

  @override
  Widget build(BuildContext context) {
    final isMaterialSelected = _selectedMaterial != models.MaterialType.unknown;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Weight Estimation'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        actions: [
          TextButton(
            onPressed: isMaterialSelected && _estimatedWeight > 0 ? _saveEstimate : null,
            child: Text(
              'Save',
              style: TextStyle(
                color: (isMaterialSelected && _estimatedWeight > 0)
                  ? AppColors.onPrimary
                  : AppColors.onSurfaceSecondary.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Photo display with ML indicators
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(File(widget.imagePath)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // ML processing indicator
                  if (_isAnalyzing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.white,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Analyzing metal weight...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // AI result indicator
                  if (_aiPrediction != null && !_isAnalyzing)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                        color: _aiPrediction!.confidenceColor.withValues(alpha: 1.0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_aiPrediction!.confidenceDescription} Confidence',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // AI Results Card
            if (_aiPrediction != null && !_isAnalyzing)
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomCard(
                  padding: const EdgeInsets.all(20),
                  variant: CardVariant.filled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppIconTile(
                            assetPath: AppIcons.analyticsDashboard,
                            semanticLabel: 'AI weight prediction analytics',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AI Weight Analysis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _aiPrediction!.confidenceColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_aiPrediction!.estimatedWeight.toStringAsFixed(1)} lbs',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _aiPrediction!.confidenceColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Estimated weight based on enhanced AI analysis with TensorFlow Lite',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // AI Factors
                      if (_aiPrediction!.factors.isNotEmpty) ...[
                        const Text(
                          'How it was calculated:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._aiPrediction!.factors.take(3).map((factor) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(top: 8, right: 12),
                                decoration: BoxDecoration(
                                  color: _aiPrediction!.confidenceColor,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  factor,
                                  style: const TextStyle(fontSize: 13, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 12),
                      ],
                      // Suggestions
                      if (_aiPrediction!.suggestions.isNotEmpty &&
                          _aiPrediction!.suggestions.first != 'Photo analysis looks good - weight estimate should be reliable') ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.info.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: AppColors.info,
                                size: 20,
                                semanticLabel: 'AI suggestion indicator',
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _aiPrediction!.suggestions.first,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Manual Entry Form
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Material & Manual Estimate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    color: isMaterialSelected ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (!isMaterialSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Select a material to enable AI analysis',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurfaceSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Material type buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _materialButton(models.MaterialType.steel, 'Steel'),
                      _materialButton(models.MaterialType.aluminum, 'Aluminum'),
                      _materialButton(models.MaterialType.copper, 'Copper'),
                      _materialButton(models.MaterialType.brass, 'Brass'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Manual weight input
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _estimatedWeight > 0 ? _estimatedWeight.toStringAsFixed(1) : '',
                          decoration: InputDecoration(
                            labelText: _aiPrediction != null
                              ? 'Override AI Weight (lbs)'
                              : 'Enter Weight (lbs)',
                            border: const OutlineInputBorder(),
                            hintText: _aiPrediction?.estimatedWeight.toStringAsFixed(1),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            setState(() {
                              _estimatedWeight = double.tryParse(value) ?? 0.0;
                            });
                          },
                        ),
                      ),
                      if (_aiPrediction != null)

                        IconButton(
                          icon: AppIconTile(
                            assetPath: AppIcons.qualityControlVerified,
                            semanticLabel: 'Restore AI estimate',
                            width: 20,
                            height: 20,
                          ),
                          tooltip: 'Use AI estimate',
                          onPressed: () {
                            setState(() {
                              _estimatedWeight = _aiPrediction!.estimatedWeight;
                            });
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Notes (optional)',
                      border: OutlineInputBorder(),
                      hintText: 'Any special details about this material',
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 32),

                  // Confidence indicator and submit
                  if (_aiPrediction != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _aiPrediction!.confidenceColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          AppIconTile(
                            assetPath: _aiPrediction!.confidenceScore >= 0.6 ? AppIcons.qualityControlVerified : AppIcons.warningAmber,
                            semanticLabel: _aiPrediction!.confidenceScore >= 0.6 ? 'High confidence verification' : 'Warning low confidence',
                            color: _aiPrediction!.confidenceColor,
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_aiPrediction!.confidenceDescription} confidence estimate - $_estimatedWeight lbs',
                              style: TextStyle(
                                color: _aiPrediction!.confidenceColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else if (isMaterialSelected && !_isAnalyzing) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 20,
                            semanticLabel: 'Information about AI analysis',
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Select material type above to enable AI weight analysis',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (isMaterialSelected && _estimatedWeight > 0) ? _saveEstimate : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: isMaterialSelected && _estimatedWeight > 0
                          ? AppColors.primary
                          : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        _aiPrediction != null ? 'Save AI-Verified Estimate' : 'Save Estimate',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _materialButton(models.MaterialType type, String label) {
    final isSelected = _selectedMaterial == type;

    return OutlinedButton(
      onPressed: () => _onMaterialChanged(type),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primary : null,
        foregroundColor: isSelected ? Colors.white : AppColors.primary,
        side: BorderSide(
          color: AppColors.primary,
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }

  Future<void> _saveEstimate() async {
    try {
      final cameraProvider = context.read<CameraProvider>();

      // Get current location
      final position = await cameraProvider.getCurrentLocation();

      final photoEstimate = models.PhotoEstimate(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: widget.imagePath,
        materialType: _selectedMaterial,
        estimatedWeight: _estimatedWeight,
        notes: _notesController.text,
        timestamp: DateTime.now(),
        latitude: position?.latitude,
        longitude: position?.longitude,
        estimatedValue: null,
      );

      cameraProvider.addEstimate(photoEstimate);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estimate saved successfully!')),
      );

      Navigator.pop(context); // Go back to camera
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving estimate: $e')),
      );
    }
  }
}
