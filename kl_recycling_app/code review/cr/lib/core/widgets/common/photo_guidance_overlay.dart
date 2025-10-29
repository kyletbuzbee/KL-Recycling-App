import 'package:flutter/material.dart';
import 'package:kl_recycling_app/core/theme.dart';
import 'package:kl_recycling_app/features/photo_estimate/models/photo_estimate.dart';

/// Enhanced photo guidance overlay for weight estimation
class PhotoGuidanceOverlay extends StatefulWidget {
  final bool isVisible;
  final VoidCallback? onDismiss;
  final Function(double)? onScaleSet;
  final PhotoQuality currentQuality;
  final List<String> currentTips;
  final bool showTutorial;
  final bool isProcessing;

  const PhotoGuidanceOverlay({
    super.key,
    this.isVisible = true,
    this.onDismiss,
    this.onScaleSet,
    this.currentQuality = PhotoQuality.fair,
    this.currentTips = const [],
    this.showTutorial = false,
    this.isProcessing = false,
  });

  @override
  State<PhotoGuidanceOverlay> createState() => _PhotoGuidanceOverlayState();
}

class _PhotoGuidanceOverlayState extends State<PhotoGuidanceOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    if (widget.isVisible) {
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: widget.isVisible ? child : const SizedBox.shrink(),
        );
      },
      child: _buildOverlayContent(),
    );
  }

  Widget _buildOverlayContent() {
    return Container(
      color: const Color.fromARGB(255, 27, 26, 26).withValues(alpha: 0.7),
      child: SafeArea(
        child: Column(
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.primary.withValues(alpha: 0.9),
              child: Row(
                children: [
                  Icon(Icons.photo_camera, color: Theme.of(context).colorScheme.onPrimary, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Photo Tips for Better Weight Estimates',
                      style: TextStyle(
                        color: Color.fromARGB(255, 0, 0, 0),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onPrimary),
                    onPressed: widget.onDismiss,
                    tooltip: 'Dismiss tips',
                  ),
                ],
              ),
            ),

            // Main tips area - Simplified to essential tips only
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTipSection(
                      'Essential Tips for Best Results',
                      Icons.star,
                      [
                        'Position metal centrally in frame',
                        'Ensure good lighting from multiple angles',
                        'Include a reference object (coin, quarter, or ruler)',
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Help icon for additional details
                    Card(
                      color: AppColors.surface.withValues(alpha: 0.9),
                      margin: EdgeInsets.zero,
                      child: InkWell(
                        onTap: () => _showDetailedHelp(),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.help_outline,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Need more detailed tips?',
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 0, 0, 0),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: AppColors.secondary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showReferenceObjectSelector,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Add Reference Object'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: widget.onDismiss,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Take Photo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipSection(String title, IconData icon, List<String> tips) {
    return Card(
      color: AppColors.surface.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.secondary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 36),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '•',
                    style: TextStyle(
                      color: Color.fromARGB(179, 5, 5, 5),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceBar(String label, double confidence, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: LinearProgressIndicator(
            value: confidence,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(confidence * 100).round()}%',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showReferenceObjectSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Reference Object',
              style: TextStyle(
                color: const Color.fromARGB(255, 8, 10, 145),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildReferenceObjectButton('US Quarter', '1.0"', Icons.attach_money),
                _buildReferenceObjectButton('AA Battery', '1.5"', Icons.battery_full),
                _buildReferenceObjectButton('Credit Card', '3.4x2.1"', Icons.credit_card),
                _buildReferenceObjectButton('Ruler', '12"', Icons.straighten),
                _buildReferenceObjectButton('Custom', 'Manual', Icons.add),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailedHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.help, color: AppColors.secondary, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'Detailed Photo Tips',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTipSection(
                        'Reference Objects',
                        Icons.aspect_ratio,
                        [
                          'US Quarter: 1 inch diameter',
                          'AA Battery: 1.5 inches long',
                          'Ruler: Provides precise measurements',
                          'Playing card: 2.5 x 3.5 inches',
                          'Credit card: 3.375 x 2.125 inches',
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildTipSection(
                        'Advanced Techniques',
                        Icons.exposure_plus_1,
                        [
                          'Use parallel lighting to reduce glare',
                          'Photograph from 45-degree angle for depth perception',
                          'Capture multiple angles when possible (top, side, bottom)',
                          'Ensure metal surface texture is visible',
                          'Avoid busy backgrounds that might confuse AI detection',
                          'Use grid overlay feature for composition',
                          'Take photos with consistent zoom level',
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildTipSection(
                        'Material-Specific Tips',
                        Icons.category,
                        [
                          'Steel/Iron: Show edges and thickness clearly',
                          'Aluminum: Capture lightweight appearance and shine',
                          'Copper: Highlight reddish tint and conductivity',
                          'Brass: Show golden color and smoothness',
                          'Wire/Thin materials: Photograph against contrasting background',
                        ],
                      ),

                      const SizedBox(height: 24),

                      // AI Analysis Quality section
                      Card(
                        color: AppColors.surface.withValues(alpha: 0.9),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.insights, color: AppColors.info),
                                  const SizedBox(width: 12),
            Text(
              'AI Analysis Quality',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildConfidenceBar('High Confidence', 0.85, AppColors.success),
                              const SizedBox(height: 8),
                              _buildConfidenceBar('Medium Confidence', 0.65, AppColors.warning),
                              const SizedBox(height: 8),
                              _buildConfidenceBar('Low Confidence', 0.35, AppColors.error),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceObjectButton(String name, String size, IconData icon) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reference object "$name" ($size) saved for photo scaling'),
            backgroundColor: AppColors.success,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              size,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
