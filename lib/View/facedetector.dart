import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import '../ViewModel/face_match.dart';
import '../ViewModel/face_register.dart';
import 'coordinates.dart';
import 'detector_view.dart';

class FaceDetectorView extends StatefulWidget {
  const FaceDetectorView({super.key});

  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
    ),
  );
  late final Recognizer _recognizer;
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  var _cameraLensDirection = CameraLensDirection.front;

  @override
  void initState() {
    super.initState();
    _recognizer = Recognizer();
  }

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    _recognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DetectorView(
      title: 'Face Recognition',
      customPaint: _customPaint,
      onImage: _processImage,
      initialCameraLensDirection: _cameraLensDirection,
      onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;

    final faces = await _faceDetector.processImage(inputImage);
    final metadata = inputImage.metadata;
    final bytes = inputImage.bytes;

    if (metadata == null) {
      _isBusy = false;
      return;
    }

    if (faces.isNotEmpty && bytes != null) {
      await _recognizer.ensureInitialized();

      final int rawWidth = metadata.size.width.toInt();
      final int rawHeight = metadata.size.height.toInt();

      // Convert NV21 camera bytes to img.Image and rotate to upright orientation.
      img.Image fullImage = _nv21ToImage(bytes, rawWidth, rawHeight);
      fullImage = _applyRotation(fullImage, metadata.rotation);

      List<Recognition> recognitions = [];

      for (Face face in faces) {
        final Rect bbox = face.boundingBox;
        int left = bbox.left.toInt().clamp(0, fullImage.width - 1);
        int top = bbox.top.toInt().clamp(0, fullImage.height - 1);
        int right = bbox.right.toInt().clamp(left + 1, fullImage.width);
        int bottom = bbox.bottom.toInt().clamp(top + 1, fullImage.height);
        int cropW = right - left;
        int cropH = bottom - top;

        if (cropW > 10 && cropH > 10) {
          img.Image croppedFace = img.copyCrop(
            fullImage,
            x: left,
            y: top,
            width: cropW,
            height: cropH,
          );

          Recognition recognition =
              await _recognizer.recognize(croppedFace, bbox);
          if (recognition.distance > 1.25) {
            recognition.number = "Unknown";
          }
          recognitions.add(recognition);
        }
      }

      _customPaint = CustomPaint(
        painter: _LiveRecognitionPainter(
          recognitions: recognitions,
          imageSize: metadata.size,
          rotation: metadata.rotation,
          cameraLensDirection: _cameraLensDirection,
        ),
      );
    } else {
      _customPaint = null;
    }

    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  /// Convert NV21 byte buffer to an [img.Image].
  static img.Image _nv21ToImage(Uint8List nv21, int width, int height) {
    final image = img.Image(width: width, height: height);
    final int ySize = width * height;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * width + x;
        final int uvIndex = ySize + (y >> 1) * width + (x & ~1);

        final int yVal = nv21[yIndex];
        final int vVal = nv21[uvIndex];
        final int uVal = nv21[uvIndex + 1];

        int r = (yVal + 1.370705 * (vVal - 128)).round().clamp(0, 255);
        int g = (yVal - 0.698001 * (vVal - 128) - 0.337633 * (uVal - 128))
            .round()
            .clamp(0, 255);
        int b = (yVal + 1.732446 * (uVal - 128)).round().clamp(0, 255);

        image.setPixelRgb(x, y, r, g, b);
      }
    }

    return image;
  }

  /// Rotate the image to match the upright orientation ML Kit uses for detection.
  static img.Image _applyRotation(
      img.Image image, InputImageRotation rotation) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return img.copyRotate(image, angle: 90);
      case InputImageRotation.rotation180deg:
        return img.copyRotate(image, angle: 180);
      case InputImageRotation.rotation270deg:
        return img.copyRotate(image, angle: 270);
      case InputImageRotation.rotation0deg:
        return image;
    }
  }
}

/// Painter that draws bounding boxes and recognition labels over the live camera.
class _LiveRecognitionPainter extends CustomPainter {
  final List<Recognition> recognitions;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  _LiveRecognitionPainter({
    required this.recognitions,
    required this.imageSize,
    required this.rotation,
    required this.cameraLensDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.amber;

    final Paint bgPaint = Paint()..color = Colors.black54;

    for (Recognition face in recognitions) {
      final double rawLeft = translateX(
          face.location.left, size, imageSize, rotation, cameraLensDirection);
      final double rawTop = translateY(
          face.location.top, size, imageSize, rotation, cameraLensDirection);
      final double rawRight = translateX(
          face.location.right, size, imageSize, rotation, cameraLensDirection);
      final double rawBottom = translateY(
          face.location.bottom, size, imageSize, rotation, cameraLensDirection);

      // Ensure left < right and top < bottom after translation.
      final double left = rawLeft < rawRight ? rawLeft : rawRight;
      final double top = rawTop < rawBottom ? rawTop : rawBottom;
      final double right = rawLeft > rawRight ? rawLeft : rawRight;
      final double bottom = rawTop > rawBottom ? rawTop : rawBottom;

      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), boxPaint);

      // Draw name and distance above the box.
      final String label =
          "${face.number}  ${face.distance.toStringAsFixed(2)}";
      TextSpan span = TextSpan(
        style: const TextStyle(color: Colors.amber, fontSize: 14),
        text: label,
      );
      TextPainter tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      canvas.drawRect(
        Rect.fromLTRB(left, top - tp.height - 4, left + tp.width + 8, top),
        bgPaint,
      );
      tp.paint(canvas, Offset(left + 4, top - tp.height - 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
