import 'package:flutter/material.dart';
import '../audio/krar_engine.dart';

class StringCanvas extends StatefulWidget {
  final KrarEngine engine;
  final int numStrings;

  const StringCanvas({
    super.key,
    required this.engine,
    this.numStrings = 5,
  });

  @override
  State<StringCanvas> createState() => _StringCanvasState();
}

class _StringCanvasState extends State<StringCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _stringVelocities = [];
  final List<double> _stringPhases = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateStrings);

    for (int i = 0; i < widget.numStrings; i++) {
      _stringVelocities.add(0.0);
      _stringPhases.add(0.0);
    }

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateStrings() {
    setState(() {
      for (int i = 0; i < widget.numStrings; i++) {
        if (_stringVelocities[i] > 0.001) {
          _stringPhases[i] += _stringVelocities[i] * 0.1;
          _stringVelocities[i] *= 0.98;
        } else {
          _stringVelocities[i] = 0.0;
          _stringPhases[i] = 0.0;
        }
      }
    });
  }

  void _pluckString(int stringIndex, double velocity) {
    widget.engine.pluck(stringIndex, velocity);
    setState(() {
      _stringVelocities[stringIndex] = velocity;
      _stringPhases[stringIndex] = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: (details) {
            _handleTouch(details.localPosition, constraints);
          },
          onPanUpdate: (details) {
            _handleTouch(details.localPosition, constraints);
          },
          onTapDown: (details) {
            _handleTouch(details.localPosition, constraints);
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: StringPainter(
              numStrings: widget.numStrings,
              stringVelocities: _stringVelocities,
              stringPhases: _stringPhases,
            ),
          ),
        );
      },
    );
  }

  void _handleTouch(Offset position, BoxConstraints constraints) {
    final stringHeight = constraints.maxHeight / widget.numStrings;
    final stringIndex = (position.dy / stringHeight).floor().clamp(
          0,
          widget.numStrings - 1,
        );

    final centerX = constraints.maxWidth / 2;
    final distanceFromCenter = (position.dx - centerX).abs();
    final normalizedDistance = distanceFromCenter / centerX;
    final velocity = 0.5 + normalizedDistance * 0.5;

    _pluckString(stringIndex, velocity);
  }
}

class StringPainter extends CustomPainter {
  final int numStrings;
  final List<double> stringVelocities;
  final List<double> stringPhases;

  StringPainter({
    required this.numStrings,
    required this.stringVelocities,
    required this.stringPhases,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final stringSpacing = size.height / (numStrings + 1);

    for (int i = 0; i < numStrings; i++) {
      final y = stringSpacing * (i + 1);
      final velocity = stringVelocities[i];
      final phase = stringPhases[i];

      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFF8B4513),
          const Color(0xFFD2691E),
          velocity,
        )!
        ..strokeWidth = 2.0 + velocity * 2.0
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(0, y);

      for (double x = 0; x <= size.width; x += 1.0) {
        final normalizedX = x / size.width;
        final vibration = velocity *
            10.0 *
            (1.0 - normalizedX) *
            (normalizedX) *
            4.0 *
            (normalizedX < 0.5 ? normalizedX * 2 : (1 - normalizedX) * 2);
        final dy = vibration * (phase * 0.1).sin();
        path.lineTo(x, y + dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StringPainter oldDelegate) {
    return oldDelegate.stringVelocities != stringVelocities ||
        oldDelegate.stringPhases != stringPhases;
  }
}
