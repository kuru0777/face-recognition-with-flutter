import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../ViewModel/face_register.dart';

class FaceRecognitionPainter extends CustomPainter {
  final List<Recognition> facesList;
  dynamic imageFile;
  FaceRecognitionPainter({required this.facesList, @required this.imageFile});
  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }

    Paint p = Paint();
    p.color = Colors.amber;
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 10;

    for (Recognition face in facesList) {
      canvas.drawRect(face.location, p);
      TextSpan span = TextSpan(
        style: const TextStyle(
            backgroundColor: Colors.amber,
            color: Colors.black,
            fontSize: 50,
            fontWeight: FontWeight.bold),
        text: "${face.number}  ${face.distance.toStringAsFixed(2)}",
      );
      TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas,
          Offset(face.location.left - 250, face.location.top - tp.height - 10));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class FaceDetectPainter extends CustomPainter {
  late List<Face> facesList;
  dynamic imageFile;
  FaceDetectPainter({required this.facesList, @required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }

    Paint p = Paint();
    p.color = Colors.amber;
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 10;

    for (Face face in facesList) {
      canvas.drawRect(face.boundingBox, p);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class FaceRecognitionLivePainter extends CustomPainter {
  FaceRecognitionLivePainter(this.absoluteImageSize, this.facesList, this.camDire2);

  final Size absoluteImageSize;
  final List<Recognition> facesList;
  CameraLensDirection camDire2;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.amber;

    for (Recognition face in facesList) {
      canvas.drawRect(
        Rect.fromLTRB(
          camDire2 == CameraLensDirection.front
              ? (absoluteImageSize.width - face.location.right) * scaleX
              : face.location.left * scaleX,
          face.location.top * scaleY,
          camDire2 == CameraLensDirection.front
              ? (absoluteImageSize.width - face.location.left) * scaleX
              : face.location.right * scaleX,
          face.location.bottom * scaleY,
        ),
        paint,
      );

      Paint textBackground = Paint()..color = Colors.black.withOpacity(0.5);

      final double textLeft = camDire2 == CameraLensDirection.front
          ? (absoluteImageSize.width - face.location.right) * scaleX
          : face.location.left * scaleX;
      final double textTop = face.location.top * scaleY;
      final double textRight = camDire2 == CameraLensDirection.front
          ? (absoluteImageSize.width - face.location.left) * scaleX
          : face.location.right * scaleX;
      final double textBottom = face.location.top * scaleY + 30;

      canvas.drawRect(
        Rect.fromLTRB(textLeft, textTop, textRight, textBottom),
        textBackground,
      );

      TextSpan span = TextSpan(
        style: const TextStyle(color: Colors.amber, fontSize: 20),
        text: "${face.number}  ${face.distance.toStringAsFixed(2)}",
      );
      TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(textLeft, textTop),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

