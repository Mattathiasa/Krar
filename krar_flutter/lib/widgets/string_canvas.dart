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
  final List<int> _activeFingers = [];
  final Map<int, int> _fingerStringMap = {};

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

  void _releaseString(int stringIndex) {
    widget.engine.release(stringIndex);
    setState(() {
      _stringVelocities[stringIndex] *= 0.5;
    });
  }

  int _getStringFromPosition(Offset position, BoxConstraints constraints) {
    final stringHeight = constraints.maxHeight / widget.numStrings;
    final stringIndex = (position.dy / stringHeight).floor().clamp(
          0,
          widget.numStrings - 1,
        );
    return stringIndex;
  }

  double _getVelocityFromPosition(Offset position, BoxConstraints constraints) {
    final centerX = constraints.maxWidth / 2;
    final distanceFromCenter = (position.dx - centerX).abs();
    final normalizedDistance = distanceFromCenter / centerX;
    return 0.5 + normalizedDistance * 0.5;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          onPointerDown: (details) {
            final stringIndex = _getStringFromPosition(
              details.localPosition,
              constraints,
            );
            final velocity = _getVelocityFromPosition(
              details.localPosition,
              constraints,
            );

            _activeFingers.add(details.pointer);
            _fingerStringMap[details.pointer] = stringIndex;

            _pluckString(stringIndex, velocity);
          },
          onPointerMove: (details) {
            final currentString = _fingerStringMap[details.pointer];
            final newString = _getStringFromPosition(
              details.localPosition,
              constraints,
            );

            if (currentString != newString) {
              if (currentString != null) {
                _releaseString(currentString);
              }

              final velocity = _getVelocityFromPosition(
                details.localPosition,
                constraints,
              );

              _fingerStringMap[details.pointer] = newString;
              _pluckString(newString, velocity);
            }
          },
          onPointerUp: (details) {
            final stringIndex = _fingerStringMap.remove(details.pointer);
            _activeFingers.remove(details.pointer);

            if (stringIndex != null) {
              _releaseString(stringIndex);
            }
          },
          onPointerCancel: (details) {
            final stringIndex = _fingerStringMap.remove(details.pointer);
            _activeFingers.remove(details.pointer);

            if (stringIndex != null) {
              _releaseString(stringIndex);
            }
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
    final backgroundPaint = Paint()
      ..color = const Color(0xFF1A1A2E)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    final stringSpacing = size.height / (numStrings + 1);

    for (int i = 0; i < numStrings; i++) {
      final y = stringSpacing * (i + 1);
      final velocity = stringVelocities[i];
      final phase = stringPhases[i];

      final basePaint = Paint()
        ..color = Color.lerp(
          const Color(0xFF8B4513),
          const Color(0xFFD2691E),
          velocity,
        )!
        ..strokeWidth = 2.0 + velocity * 3.0
        ..strokeCap = StrokeCap.round;

      final glowPaint = Paint()
        ..color = Color.lerp(
          const Color(0x008B4513),
          const Color(0x80FFD700),
          velocity,
        )!
        ..strokeWidth = 4.0 + velocity * 6.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

      final path = Path();
      path.moveTo(0, y);

      for (double x = 0; x <= size.width; x += 1.0) {
        final normalizedX = x / size.width;
        final vibration = velocity *
            15.0 *
            (1.0 - normalizedX) *
            (normalizedX) *
            4.0 *
            (normalizedX < 0.5 ? normalizedX * 2 : (1 - normalizedX) * 2);
        final dy = vibration * (phase * 0.1).sin();
        path.lineTo(x, y + dy);
      }

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, basePaint);

      final stringNamePaint = Paint()
        ..color = Colors.white.withAlpha(velocity > 0.0 ? 255 : 128)
        ..fontSize = 12.0;

      final stringNames = ['Db2', 'Ab2', 'Eb3', 'Bb3', 'F4'];
      final textPainter = TextPainter(
        text: TextSpan(
          text: stringNames[i],
          style: stringNamePaint,
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(10, y - 8));
    }
  }

  @override
  bool shouldRepaint(covariant StringPainter oldDelegate) {
    return oldDelegate.stringVelocities != stringVelocities ||
        oldDelegate.stringPhases != stringPhases;
  }
}
