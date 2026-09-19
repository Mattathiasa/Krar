import 'dart:async';

import 'package:flutter/material.dart';

import '../audio/krar_engine.dart';
import '../models/qenet.dart';
import '../theme/studio_theme.dart';
import '../widgets/studio_widgets.dart';

/// Scales play from Ab3.
const double kScaleRoot = 207.65;

class ScalesScreen extends StatefulWidget {
  const ScalesScreen({super.key, required this.engine});

  final KrarEngine engine;

  @override
  State<ScalesScreen> createState() => _ScalesScreenState();
}

class _ScalesScreenState extends State<ScalesScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();
  ScaleType? _playing;
  int _step = -1;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!motionEnabled(context)) _intro.value = 1;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _intro.dispose();
    super.dispose();
  }

  void _toggle(ScaleType s) {
    _timer?.cancel();
    if (_playing == s) {
      setState(() {
        _playing = null;
        _step = -1;
      });
      return;
    }
    widget.engine.resume();
    var step = 0;
    void tick() {
      if (step >= s.cents.length) {
        _timer?.cancel();
        setState(() {
          _playing = null;
          _step = -1;
        });
        return;
      }
      widget.engine.playFrequency(s.frequency(kScaleRoot, step));
      setState(() {
        _playing = s;
        _step = step;
      });
      step++;
    }

    tick();
    _timer = Timer.periodic(const Duration(milliseconds: 380), (_) => tick());
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final pad = wide ? 48.0 : 20.0;
    final rows = [
      for (var i = 0; i < ScaleType.values.length; i++)
        _ScaleRow(
          scale: ScaleType.values[i],
          index: i,
          intro: _intro,
          playing: _playing == ScaleType.values[i],
          step: _playing == ScaleType.values[i] ? _step : -1,
          onToggle: () => _toggle(ScaleType.values[i]),
          wide: wide,
        ),
    ];
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(padding: EdgeInsets.fromLTRB(pad, 30, pad, 24), child: _Intro(wide: wide)),
        for (final r in rows)
          Padding(padding: EdgeInsets.fromLTRB(pad, 0, pad, 12), child: SizedBox(height: wide ? 136 : 176, child: r)),
      ],
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: 'THE FOUR QENET · ', style: StudioText.label()),
          TextSpan(text: 'ቅኝት', style: StudioText.geez(13, color: StudioColors.saffron)),
        ])),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'Between the '),
            TextSpan(
                text: 'piano keys',
                style: StudioText.display(wide ? 60 : 40, color: StudioColors.saffron, style: FontStyle.italic)),
          ]),
          style: StudioText.display(wide ? 60 : 40),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            'Each dot is a scale degree, placed in cents from the root. Teal ticks are the piano\'s equal '
            'temperament; the teal bar shows which way, and how far, the Ethiopian pitch leans. Press play to hear it.',
            style: StudioText.body(16, color: StudioColors.muted, height: 1.5),
          ),
        ),
      ],
    );
    if (!wide) return text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: text),
        const _Legend(),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Widget swatch, String label) => Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Row(children: [swatch, const SizedBox(width: 8), Text(label, style: StudioText.body(13, color: StudioColors.muted))]),
        );
    return Row(children: [
      item(Container(width: 12, height: 12, decoration: const BoxDecoration(color: StudioColors.saffron, shape: BoxShape.circle)),
          'Scale degree'),
      item(Container(width: 2, height: 14, color: StudioColors.teal), '12-TET key'),
      item(
          Container(
              width: 18,
              height: 4,
              decoration: BoxDecoration(color: StudioColors.teal, borderRadius: BorderRadius.circular(2))),
          'Lean'),
    ]);
  }
}

class _ScaleRow extends StatelessWidget {
  const _ScaleRow({
    required this.scale,
    required this.index,
    required this.intro,
    required this.playing,
    required this.step,
    required this.onToggle,
    required this.wide,
  });

  final ScaleType scale;
  final int index;
  final Animation<double> intro;
  final bool playing;
  final int step;
  final VoidCallback onToggle;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final play = SizedBox.square(
      dimension: 52,
      child: IconButton.filled(
        tooltip: playing ? 'Stop ${scale.label}' : 'Play ${scale.label}',
        onPressed: onToggle,
        icon: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 26),
        style: IconButton.styleFrom(backgroundColor: scale.hue, foregroundColor: StudioColors.ground),
      ),
    );
    final name = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(scale.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: StudioText.display(32, color: scale.hue)),
        const SizedBox(height: 4),
        Text.rich(TextSpan(children: [
          TextSpan(text: scale.geez, style: StudioText.geez(13)),
          TextSpan(text: ' · ${scale.short}', style: StudioText.body(13, color: StudioColors.muted)),
        ])),
      ],
    );
    final ruler = AnimatedBuilder(
      animation: intro,
      builder: (context, _) => CustomPaint(
        painter: _RulerPainter(scale: scale, intro: intro.value, row: index, step: step),
        size: Size.infinite,
      ),
    );
    return StudioCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      borderColor: playing ? scale.hue : null,
      child: wide
          ? Row(children: [
              play,
              const SizedBox(width: 24),
              SizedBox(width: 150, child: name),
              const SizedBox(width: 24),
              Expanded(child: ruler),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [play, const SizedBox(width: 16), Expanded(child: name)]),
              const SizedBox(height: 8),
              Expanded(child: ruler),
            ]),
    );
  }
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({required this.scale, required this.intro, required this.row, required this.step});

  final ScaleType scale;
  final double intro;
  final int row;
  final int step;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 20.0;
    final span = size.width - pad * 2;
    double px(double c) => pad + c / 1200 * span;
    final mid = size.height * 0.5;

    canvas.drawLine(Offset(0, mid), Offset(size.width, mid), Paint()..color = const Color(0xFF4A3F33));
    final tick = Paint()
      ..color = StudioColors.teal.withValues(alpha: 0.5)
      ..strokeWidth = 2;
    for (var i = 0; i <= 12; i++) {
      final x = px(i * 100.0);
      canvas.drawLine(Offset(x, mid - 12), Offset(x, mid + 12), tick);
    }

    final cents = scale.cents;
    for (var d = 0; d < cents.length; d++) {
      final c = cents[d];
      final et = (c / 100).round() * 100.0;
      final dev = deviationFromEqualTemperament(c);
      final delay = (row * 0.12 + d * 0.06) / 1.8;
      final pop = Curves.easeOutBack.transform(((intro - delay) / 0.3).clamp(0.0, 1.0));
      final grow = Curves.easeOutCubic.transform(((intro - delay - 0.2) / 0.35).clamp(0.0, 1.0));

      // Lean bar from the piano key to the Ethiopian pitch.
      final a = px(et), b = px(c);
      final leanEnd = a + (b - a) * grow;
      canvas.drawRRect(
        RRect.fromLTRBR(a < leanEnd ? a : leanEnd, mid - 2.5, a < leanEnd ? leanEnd : a, mid + 2.5, const Radius.circular(3)),
        Paint()..color = StudioColors.teal,
      );

      if (pop <= 0) continue;
      final on = d == step;
      final y = mid - (1 - pop) * 14;
      final r = (on ? 13.0 : 8.0) * pop;
      if (on) {
        canvas.drawCircle(Offset(b, y), 22, Paint()
          ..color = scale.hue.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      }
      canvas.drawCircle(Offset(b, y), r + 3, Paint()..color = StudioColors.surface);
      canvas.drawCircle(Offset(b, y), r, Paint()..color = scale.hue);

      _label(canvas, '${c.round()}', Offset(b, y - 34), StudioText.mono(13, color: on ? scale.hue : StudioColors.text), pop);
      _label(canvas, formatDeviation(dev, zero: '±0'), Offset(b, y + 16),
          StudioText.mono(12, color: dev.abs() >= 15 ? StudioColors.teal : StudioColors.dim), pop);
    }
  }

  void _label(Canvas canvas, String text, Offset topCenter, TextStyle style, double opacity) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style.copyWith(color: style.color!.withValues(alpha: opacity))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, topCenter - Offset(tp.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant _RulerPainter old) =>
      old.intro != intro || old.step != step || old.scale != scale;
}
