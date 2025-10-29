
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kl_recycling_app/core/theme.dart';

import 'package:kl_recycling_app/features/camera/logic/camera_provider.dart';
import 'package:kl_recycling_app/features/photo_estimate/models/photo_estimate.dart' as models;
import 'package:kl_recycling_app/features/photo_estimate/view/photo_preview_screen.dart';
import 'package:kl_recycling_app/core/widgets/common/photo_guidance_overlay.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, this.showTutorial = false});

  final bool showTutorial;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  late CameraProvider _cameraProvider;
  final models.PhotoQuality _currentQuality = models.PhotoQuality.fair;
  List<String> _currentTips = [];
  bool _showTutorial = false;
  bool _isFirstTime = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _checkFirstTimeUser();
    _simulatePhotoAnalysis();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraProvider.disposeCamera();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    _cameraProvider = context.read<CameraProvider>();
    await _cameraProvider.initializeCamera();
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    // Only dispose on inactive, let resumed state handle reinitialization
    if (state == AppLifecycleState.inactive) {
      _cameraProvider.disposeCamera();
    }
  }

  @override
  void didUpdateWidget(CameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reinitialize if needed when widget updates
    if (_cameraProvider.controller == null || !_cameraProvider.isInitialized) {
      _initializeCamera();
    }
  }

  Future<void> _checkFirstTimeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isFirstTime = prefs.getBool('camera_tutorial_shown') ?? true;
      if (_isFirstTime && mounted) {
        setState(() {
          _showTutorial = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking first-time user: $e');
    }
  }

  void _simulatePhotoAnalysis() {
    // Simulate dynamic photo quality analysis
    // In a real implementation, this would analyze the camera feed
    _currentTips = [
      'Consider moving closer to fill the frame with metal',
      'Ensure good lighting for better AI accuracy',
      'Avoid complex backgrounds for optimal results',
    ];
    setState(() {});
  }

  void _dismissTutorial() {
    setState(() {
      _showTutorial = false;
      _isFirstTime = false;
    });
    // Mark as shown
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('camera_tutorial_shown', true);
    });
  }

  Future<void> _takePhoto() async {
    try {
      final imagePath = await _cameraProvider.takePicture();
      if (!mounted || imagePath == null) return;

      // Navigate to photo preview
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoPreviewScreen(imagePath: imagePath),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  Widget _buildCameraPreview(CameraController controller) {
    try {
      // Check if controller is properly initialized
      if (!controller.value.isInitialized) {
        return Container(
          color: Theme.of(context).colorScheme.surface,
          child: Center(
            child: Text(
              'Camera initializing...',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
        );
      }

      return CameraPreview(controller);
    } catch (e) {
      debugPrint('Camera preview error: $e');
      return Container(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.videocam_off,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Camera preview\nunavailable',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraProvider = context.watch<CameraProvider>();

    if (!cameraProvider.isInitialized || cameraProvider.controller == null) {
      return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Estimate'),
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Estimate'),
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () {
              // Toggle camera - would implement if needed
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Safe CameraPreview with error handling
          SizedBox.expand(
            child: _buildCameraPreview(cameraProvider.controller!),
          ),

          // Framing overlay with better design
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(20),
          ),

          // Add dash pattern to framing guide
          Positioned.fill(
            child: CustomPaint(
              painter: DashedBorderPainter(
                borderColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),

          // Photo Guidance Overlay - only show dismissible tutorial
          if (_showTutorial)
            Positioned.fill(
              child: PhotoGuidanceOverlay(
                currentQuality: _currentQuality,
                currentTips: _currentTips,
                showTutorial: _showTutorial,
                isProcessing: false,
                onDismiss: _dismissTutorial,
              ),
            ),

          // Enhanced capture button with better positioning
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: 32,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dismissible tutorial overlay
          if (_showTutorial)
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismissTutorial,
                child: const SizedBox.expand(),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom painter for dashed border guide
class DashedBorderPainter extends CustomPainter {
  final Color borderColor;

  const DashedBorderPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashLength = 8.0;
    const gapLength = 4.0;
    final borderRect = Rect.fromLTRB(20, 20, size.width - 20, size.height - 20);

    _drawDashedRect(canvas, borderRect, dashLength, gapLength, paint);
  }

  void _drawDashedRect(Canvas canvas, Rect rect, double dashLength, double gapLength, Paint paint) {
    final width = rect.width;
    final height = rect.height;

    // Draw dashed lines for top, right, bottom, left
    _drawDashedLine(canvas, Offset(rect.left, rect.top), Offset(rect.right, rect.top), dashLength, gapLength, paint);
    _drawDashedLine(canvas, Offset(rect.right, rect.top), Offset(rect.right, rect.bottom), dashLength, gapLength, paint);
    _drawDashedLine(canvas, Offset(rect.right, rect.bottom), Offset(rect.left, rect.bottom), dashLength, gapLength, paint);
    _drawDashedLine(canvas, Offset(rect.left, rect.bottom), Offset(rect.left, rect.top), dashLength, gapLength, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, double dashLength, double gapLength, Paint paint) {
    final path = Path();
    final distance = (end - start).distance;
    final direction = (end - start) / distance;

    double currentDistance = 0;
    bool drawDash = true;

    while (currentDistance < distance) {
      final segmentLength = drawDash ? dashLength : gapLength;
      final endDistance = currentDistance + segmentLength;

      if (endDistance > distance) {
        final remainingDistance = distance - currentDistance;
        final endPoint = start + direction * remainingDistance;

        if (drawDash) {
          path.moveTo(start.dx, start.dy);
          path.lineTo(endPoint.dx, endPoint.dy);
        }
        break;
      }

      final segmentEnd = start + direction * endDistance;

      if (drawDash) {
        path.moveTo(start.dx, start.dy);
        path.lineTo(segmentEnd.dx, segmentEnd.dy);
      }

      start = segmentEnd;
      currentDistance = endDistance;
      drawDash = !drawDash;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
