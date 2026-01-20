import 'package:flutter/material.dart';
import 'package:chefbot_app/models/detection_model.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final double imageWidth;
  final double imageHeight;

  BoundingBoxPainter({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (var d in detections) {
      final scaleX = size.width / imageWidth;
      final scaleY = size.height / imageHeight;

      final rect = Rect.fromLTRB(
        d.x1 * scaleX,
        d.y1 * scaleY,
        d.x2 * scaleX,
        d.y2 * scaleY,
      );

      canvas.drawRect(rect, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: d.label,
          style: const TextStyle(
            color: Colors.white,
            backgroundColor: Colors.red,
            fontSize: 14,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, rect.topLeft);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}