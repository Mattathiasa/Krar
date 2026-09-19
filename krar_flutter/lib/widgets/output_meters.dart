import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../audio/krar_engine.dart';
import '../theme/studio_theme.dart';
import 'studio_widgets.dart';

/// Partial amplitudes each string starts with (string_model.rs `harmonics`).
const List<double> kStringHarmonics = [1.0, 0.8, 0.6, 0.4, 0.3, 0.2, 0.15, 0.1];

/// Bars for the eight partials of the last plucked string; they breathe
/// while the string rings.
class PartialsMeter extends StatefulWidget {
  const PartialsMeter({super.key, required this.color, required this.name, required this.energy});

  final Color color;
  final String name;

  /// 0..1, how strongly the string is still ringing.
  final double energy;

  @override
  State<PartialsMeter> createState() => _PartialsMeterState();
}

class _PartialsMeterState extends State<PartialsMeter> with SingleTickerProviderStateMixin {
  late final AnimationController _breath =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final motion = motionEnabled(context);
    return StudioCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: 'PARTIALS · ', style: StudioText.label().copyWith(fontSize: 11)),
            TextSpan(text: widget.name, style: StudioText.label(color: widget.color).copyWith(fontSize: 11)),
          ])),
          const SizedBox(height: 8),
          Expanded(
            child: AnimatedBuilder(
              animation: _breath,
              builder: (context, _) {
                final t = _breath.value * 2 * pi;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < kStringHarmonics.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: LayoutBuilder(builder: (context, c) {
                          final h = kStringHarmonics[i];
                          final wobble = motion ? 0.81 + 0.19 * sin(t * (6 + i) + i) : 1.0;
                          // Upper partials fade first, like a real string.
                          final live = 0.35 + 0.65 * pow(widget.energy, 1 + i * 0.4);
                          return Container(
                            height: c.maxHeight * h * wobble * live,
                            decoration: BoxDecoration(
                              color: widget.color.withValues(alpha: 0.45 + h * 0.55),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3), bottom: Radius.circular(1)),
                            ),
                          );
                        }),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Live oscilloscope of the master bus, read from the bridge's AnalyserNode.
class OutputScope extends StatefulWidget {
  const OutputScope({super.key, required this.engine});

  final KrarEngine engine;

  @override
  State<OutputScope> createState() => _OutputScopeState();
}

class _OutputScopeState extends State<OutputScope> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<List<double>> _samples = ValueNotifier(const []);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _samples.value = widget.engine.waveform())..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _samples.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StudioCard(
      padding: EdgeInsets.zero,
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _ScopePainter(_samples))),
        Positioned(
          left: 14,
          top: 10,
          child: Text('OUTPUT · MASTER BUS', style: StudioText.label().copyWith(fontSize: 11)),
        ),
      ]),
    );
  }
}

class _ScopePainter extends CustomPainter {
  _ScopePainter(this.samples) : super(repaint: samples);

  final ValueNotifier<List<double>> samples;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height * 0.56;
    canvas.drawLine(Offset(0, mid), Offset(size.width, mid), Paint()..color = StudioColors.line);
    final s = samples.value;
    if (s.isEmpty) return;
    final path = Path();
    final amp = size.height * 0.4;
    for (var i = 0; i < s.length; i++) {
      final x = i / (s.length - 1) * size.width;
      final y = mid - s[i].clamp(-1.0, 1.0) * amp * 4;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = const LinearGradient(
          colors: [StudioColors.saffron, StudioColors.terracotta, StudioColors.saffron],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _ScopePainter oldDelegate) => false;
}
