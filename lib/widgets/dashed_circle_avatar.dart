import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DashedCircleAvatar extends StatelessWidget {
  final String imageUrl;
  final int segments;
  final double radius; // نصف قطر الصورة
  final bool hasStory;

  const DashedCircleAvatar({
    required this.imageUrl,
    required this.segments,
    required this.radius,
    required this.hasStory,
  });

  @override
  Widget build(BuildContext context) {
    final double storyRingRadius = radius; // فرق المسافة بين الصورة والدائرة

    return SizedBox(
      width: storyRingRadius * 2,
      height: storyRingRadius * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (hasStory)
            CustomPaint(
              size: Size.fromRadius(storyRingRadius),
              painter: DashedCirclePainter(
                segments: segments,
                strokeWidth: 3,
                color: Colors.purpleAccent,
              ),
            ),
          Positioned(
            bottom: 26,
            child: CircleAvatar(
              radius: storyRingRadius / 1.47,
              backgroundColor: Colors.grey[200],
              backgroundImage: CachedNetworkImageProvider(imageUrl),
            ),
          ),
        ],
      ),
    );
  }
}

class DashedCirclePainter extends CustomPainter {
  final int segments;
  final double strokeWidth;
  final Color color;

  DashedCirclePainter({
    required this.segments,
    this.strokeWidth = 3,
    this.color = Colors.purpleAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments <= 0) return;

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double radius = size.width / 2;
    final double anglePerSegment = 360 / segments;
    final double gapAngle = anglePerSegment * 0.25;
    final double arcAngle = anglePerSegment * 0.75;

    final Rect rect = Rect.fromCircle(center: Offset(radius, radius), radius: radius - strokeWidth / 2);

    double startAngle = -90 * (3.1416 / 180);

    for (int i = 0; i < segments; i++) {
      canvas.drawArc(
        rect,
        startAngle,
        arcAngle * (3.1416 / 180),
        false,
        paint,
      );
      startAngle += anglePerSegment * (3.1416 / 180);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

