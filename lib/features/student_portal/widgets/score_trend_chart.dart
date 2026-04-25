import 'package:flutter/material.dart';

class ScoreTrendChart extends StatelessWidget {
  const ScoreTrendChart({
    required this.points,
    super.key,
  });

  final List<double> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        ),
        child: Text(
          'No marks available',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.35),
      ),
      child: CustomPaint(
        painter: _ScoreTrendPainter(points),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ScoreTrendPainter extends CustomPainter {
  _ScoreTrendPainter(this.points);

  final List<double> points;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF94A3B8).withOpacity(0.25)
      ..strokeWidth = 1;

    for (var i = 0; i <= 4; i += 1) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final safePoints = points.map((e) => e.clamp(0, 100).toDouble()).toList(growable: false);

    final linePaint = Paint()
      ..color = const Color(0xFF0EA5E9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0x660EA5E9), Color(0x001BA8FF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < safePoints.length; i += 1) {
      final x = safePoints.length == 1 ? 0.0 : (size.width * i) / (safePoints.length - 1);
      final y = size.height - ((safePoints[i] / 100) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    final endX = safePoints.length == 1 ? 0.0 : size.width;
    fillPath.lineTo(endX, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = const Color(0xFF0284C7);
    for (var i = 0; i < safePoints.length; i += 1) {
      final x = safePoints.length == 1 ? 0.0 : (size.width * i) / (safePoints.length - 1);
      final y = size.height - ((safePoints[i] / 100) * size.height);
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreTrendPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
