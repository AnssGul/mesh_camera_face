import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:math' as math;

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _cameraController;
  bool isControllerInitialized = false;
  Timer? _timer;
  int countdown = 3;

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController(
      widget.cameras[1],
      ResolutionPreset.high,
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _cameraController.initialize();
    setState(() {
      isControllerInitialized = true;
    });
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown == 0) {
        timer.cancel();
        _capturePicture();
      } else {
        setState(() {
          countdown--;
        });
      }
    });
  }

  Future<void> _capturePicture() async {
    if (!_cameraController.value.isInitialized) return;

    final XFile file = await _cameraController.takePicture();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Picture Taken"),
          content: Container(
            height: 200,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            child: Image.file(
              File(file.path),
              fit: BoxFit.contain,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: isControllerInitialized
                ? CameraPreview(_cameraController)
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: OvalNetOverlayPainter(countdown: countdown),
            ),
          ),
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Text(
              "Align your face in the AI net\nCapturing in $countdown seconds",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OvalNetOverlayPainter extends CustomPainter {
  final int countdown;

  OvalNetOverlayPainter({required this.countdown});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _getDynamicColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final double ovalWidth = size.width * 0.6;
    final double ovalHeight = size.height * 0.4;

    final Offset ovalCenter = Offset(size.width / 2, size.height / 2);
    final Rect ovalRect = Rect.fromCenter(
      center: ovalCenter,
      width: ovalWidth,
      height: ovalHeight,
    );

    final outlinePaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(ovalRect, outlinePaint);

    const int gridLinesX = 20;
    const int gridLinesY = 12;

    final double cellWidth = ovalWidth / gridLinesX;
    final double cellHeight = ovalHeight / gridLinesY;

    for (int i = 0; i < gridLinesX; i++) {
      for (int j = 0; j < gridLinesY; j++) {
        double xOffset = math.sin(countdown + i * 0.3) * 3;
        double yOffset = math.cos(countdown + j * 0.3) * 3;

        Offset lineStart = Offset(ovalRect.left + cellWidth * i + xOffset,
            ovalRect.top + cellHeight * j + yOffset);
        Offset lineEnd = Offset(ovalRect.left + cellWidth * (i + 1) + xOffset,
            ovalRect.top + cellHeight * (j + 1) + yOffset);

        if (_isLineInOval(lineStart, lineEnd, ovalRect)) {
          canvas.drawLine(lineStart, lineEnd, paint);
        }
      }
    }
  }

  Color _getDynamicColor() {
    int red = (countdown * 15) % 255;
    int green = (countdown * 10) % 255;
    int blue = (countdown * 5) % 255;
    return Color.fromARGB(255, red, green, blue);
  }

  bool _isLineInOval(Offset start, Offset end, Rect ovalRect) {
    return _isPointInOval(start, ovalRect) && _isPointInOval(end, ovalRect);
  }

  bool _isPointInOval(Offset point, Rect ovalRect) {
    final centerX = ovalRect.center.dx;
    final centerY = ovalRect.center.dy;
    final a = ovalRect.width / 2;
    final b = ovalRect.height / 2;

    final normalizedX = (point.dx - centerX) / a;
    final normalizedY = (point.dy - centerY) / b;

    return (normalizedX * normalizedX + normalizedY * normalizedY) <= 1;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
