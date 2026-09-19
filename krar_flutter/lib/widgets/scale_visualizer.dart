import 'package:flutter/material.dart';
import 'scale_selector.dart';

class ScaleVisualizer extends StatelessWidget {
  final ScaleType currentScale;
  final double rootFrequency;

  const ScaleVisualizer({
    super.key,
    required this.currentScale,
    this.rootFrequency = 130.81,
  });

  @override
  Widget build(BuildContext context) {
    final intervals = currentScale.intervals;
    final degrees = ['1', '2', '3', '4', '5', '6', '7', '8'];
    final cents = _getCentsForScale(currentScale);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFF0F3460),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.piano,
                color: const Color(0xFFE94560),
                size: 20.0,
              ),
              const SizedBox(width: 8.0),
              Text(
                currentScale.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            currentScale.description,
            style: TextStyle(
              color: Colors.white.withAlpha(150),
              fontSize: 12.0,
            ),
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            height: 120.0,
            child: CustomPaint(
              size: const Size(double.infinity, 120.0),
              painter: ScaleDiagramPainter(
                intervals: intervals,
                cents: cents,
                degrees: degrees,
                rootFrequency: rootFrequency,
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          _buildIntervalsList(intervals, cents, degrees),
        ],
      ),
    );
  }

  List<double> _getCentsForScale(ScaleType scale) {
    switch (scale) {
      case ScaleType.tizitaMinor:
        return [0, 282, 386, 520, 678, 884, 1018, 1136];
      case ScaleType.tizitaMajor:
        return [0, 282, 386, 520, 678, 884, 1018, 1136];
      case ScaleType.ambassel:
        return [0, 182, 316, 520, 678, 812, 1018, 1136];
      case ScaleType.bati:
        return [0, 182, 316, 498, 678, 884, 1018, 1136];
    }
  }

  Widget _buildIntervalsList(
    List<double> intervals,
    List<double> cents,
    List<String> degrees,
  ) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: List.generate(intervals.length, (index) {
        final frequency = rootFrequency * intervals[index];
        final centsValue = cents[index];

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10.0,
            vertical: 6.0,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0F3460),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                degrees[index],
                style: const TextStyle(
                  color: Color(0xFFE94560),
                  fontSize: 10.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                '${frequency.toStringAsFixed(1)}Hz',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.0,
                ),
              ),
              Text(
                '${centsValue.toStringAsFixed(0)}¢',
                style: TextStyle(
                  color: Colors.white.withAlpha(150),
                  fontSize: 9.0,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class ScaleDiagramPainter extends CustomPainter {
  final List<double> intervals;
  final List<double> cents;
  final List<String> degrees;
  final double rootFrequency;

  ScaleDiagramPainter({
    required this.intervals,
    required this.cents,
    required this.degrees,
    required this.rootFrequency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final padding = 20.0;

    final axisPaint = Paint()
      ..color = const Color(0xFF0F3460)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(padding, height - padding),
      Offset(width - padding, height - padding),
      axisPaint,
    );

    final maxCents = 1200.0;
    final pointPaint = Paint()
      ..color = const Color(0xFFE94560)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = const Color(0xFF533483)
      ..strokeWidth = 2.0;

    final points = <Offset>[];

    for (int i = 0; i < intervals.length; i++) {
      final x = padding + (cents[i] / maxCents) * (width - 2 * padding);
      final y = height - padding - (intervals[i] - 1.0) * (height - 2 * padding) / 0.7;

      points.add(Offset(x, y));

      canvas.drawCircle(x: x, y: y, radius: 4.0, paint: pointPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: degrees[i],
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 4, y - 16));
    }

    if (points.length > 1) {
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(path, linePaint);
    }

    final labelTextPainter = TextPainter(
      text: TextSpan(
        text: 'Cents →',
        style: TextStyle(
          color: Colors.white.withAlpha(100),
          fontSize: 10.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelTextPainter.layout();
    labelTextPainter.paint(
      canvas,
      Offset(width / 2 - 20, height - 5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
