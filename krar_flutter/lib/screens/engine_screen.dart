import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/studio_theme.dart';

/// How the sound is made: the three layers, and one string's feedback loop.
class EngineScreen extends StatelessWidget {
  const EngineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final pad = wide ? 48.0 : 20.0;
    // Web runs the engine as WASM behind an AudioWorklet; iOS runs it natively on CoreAudio.
    final cards = kIsWeb
        ? const [
            _LayerCard(
              n: '01',
              kicker: 'Main thread',
              title: 'Flutter Web canvas',
              accent: StudioColors.blue,
              body: 'Pointer events from up to ten fingers are hit-tested against the strings in StringCanvas. '
                  'Every string a finger touches or crosses becomes a pluck(string, velocity) call.',
            ),
            _LayerCard(
              n: '02',
              kicker: 'Audio thread',
              title: 'AudioWorkletProcessor',
              accent: StudioColors.saffron,
              highlight: true,
              body: 'krar-processor plays 128-frame blocks, 2.67 ms each at 48 kHz. Today it asks the main thread '
                  'for each block over its MessagePort; running the engine inside the worklet is the next step.',
            ),
            _LayerCard(
              n: '03',
              kicker: 'WebAssembly',
              title: 'Rust KrarEngine',
              accent: StudioColors.terracotta,
              body: 'Compiled with wasm-bindgen. Owns one string model per voice, the active qenet, and master gain.',
            ),
          ]
        : const [
            _LayerCard(
              n: '01',
              kicker: 'UI thread',
              title: 'Flutter canvas',
              accent: StudioColors.blue,
              body: 'Pointer events from up to ten fingers are hit-tested against the strings in StringCanvas. '
                  'Every string a finger touches or crosses becomes a pluck(string, velocity) call over dart:ffi.',
            ),
            _LayerCard(
              n: '02',
              kicker: 'Audio thread',
              title: 'CoreAudio render callback',
              accent: StudioColors.saffron,
              highlight: true,
              body: 'The engine renders straight into CoreAudio on its own real-time thread. It never waits on '
                  'the UI: if a control call holds the engine, it plays one silent block instead of blocking.',
            ),
            _LayerCard(
              n: '03',
              kicker: 'Native Rust',
              title: 'Rust KrarEngine',
              accent: StudioColors.terracotta,
              body: 'The same crate as the web build, compiled for iOS into KrarEngine.framework with a small C ABI. '
                  'Owns one string model per voice, the active qenet, and master gain.',
            ),
          ];
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, 36, pad, 40),
      children: [
        Text('UNDER THE HOOD', style: StudioText.label()),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'No samples. Every note is a '),
            TextSpan(
              text: 'simulated string.',
              style: StudioText.display(wide ? 56 : 38, color: StudioColors.saffron, style: FontStyle.italic),
            ),
          ]),
          style: StudioText.display(wide ? 56 : 38),
        ),
        const SizedBox(height: 32),
        if (wide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 20),
                  Expanded(child: cards[i]),
                ],
              ],
            ),
          )
        else
          for (final c in cards) Padding(padding: const EdgeInsets.only(bottom: 16), child: c),
        const SizedBox(height: 24),
        const _KarplusStrongPanel(),
      ],
    );
  }
}

class _LayerCard extends StatelessWidget {
  const _LayerCard({
    required this.n,
    required this.kicker,
    required this.title,
    required this.body,
    required this.accent,
    this.highlight = false,
  });

  final String n, kicker, title, body;
  final Color accent;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: StudioColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlight ? accent : StudioColors.line),
        boxShadow: highlight ? [BoxShadow(color: accent.withValues(alpha: 0.12), blurRadius: 40)] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4, color: accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(kicker.toUpperCase(),
                        style: StudioText.label(color: highlight ? accent : StudioColors.muted).copyWith(fontSize: 11)),
                    Text(n, style: StudioText.mono(12, color: StudioColors.dim)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, style: StudioText.body(22, weight: FontWeight.w600)),
                const SizedBox(height: 12),
                Text(body, style: StudioText.body(14, color: StudioColors.muted, height: 1.55)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KarplusStrongPanel extends StatefulWidget {
  const _KarplusStrongPanel();

  @override
  State<_KarplusStrongPanel> createState() => _KarplusStrongPanelState();
}

class _KarplusStrongPanelState extends State<_KarplusStrongPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _flow =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    final motion = motionEnabled(context);
    final explainer = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('INSIDE ONE STRING', style: StudioText.label().copyWith(fontSize: 11)),
        const SizedBox(height: 12),
        Text('Karplus–Strong', style: StudioText.display(36)),
        const SizedBox(height: 12),
        Text(
          'A burst of noise circulates through a delay line one period long. Each pass is averaged and damped, '
          'so high harmonics fade first, the way a gut string rings out.',
          style: StudioText.body(14, color: StudioColors.muted, height: 1.55),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: StudioColors.surfaceRaised, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('y[n] = ρ · ½ (y[n−N] + y[n−N−1])', style: StudioText.mono(13)),
              const SizedBox(height: 4),
              Text('N = fs / f₀', style: StudioText.mono(13, color: StudioColors.dim)),
            ],
          ),
        ),
      ],
    );
    final diagram = Semantics(
      label: 'Diagram: a noise burst feeds a delay line, then an averaging filter and damping, '
          'which loops back to the delay line and also goes to the output.',
      child: AspectRatio(
        aspectRatio: 760 / 260,
        child: FittedBox(
          child: SizedBox(
            width: 760,
            height: 260,
            child: AnimatedBuilder(
              animation: _flow,
              builder: (context, _) => CustomPaint(painter: _LoopPainter(motion ? _flow.value : 0.3)),
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 28),
      decoration: BoxDecoration(
        color: StudioColors.stage,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: StudioColors.line),
      ),
      child: wide
          ? Row(children: [
              SizedBox(width: 300, child: explainer),
              const SizedBox(width: 40),
              Expanded(child: diagram),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [explainer, const SizedBox(height: 24), diagram]),
    );
  }
}

class _LoopPainter extends CustomPainter {
  _LoopPainter(this.t);

  final double t;

  static const loop = [
    Offset(190, 112),
    Offset(660, 112),
    Offset(660, 218),
    Offset(190, 218),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final arrow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = StudioColors.saffron;
    _dashed(canvas, const [Offset(130, 112), Offset(170, 112)], arrow);
    _dashed(canvas, const [Offset(208, 112), Offset(248, 112)], arrow);
    _dashed(canvas, const [Offset(420, 112), Offset(478, 112)], arrow);
    _dashed(canvas, const [Offset(630, 112), Offset(700, 112)], arrow);
    _dashed(canvas, const [Offset(660, 112), Offset(660, 218), Offset(632, 218)], arrow);
    _dashed(canvas, const [Offset(480, 218), Offset(190, 218), Offset(190, 132)], arrow);
    for (final head in const [
      (Offset(170, 112), 0.0),
      (Offset(248, 112), 0.0),
      (Offset(478, 112), 0.0),
      (Offset(700, 112), 0.0),
      (Offset(632, 218), pi),
      (Offset(190, 132), -pi / 2),
    ]) {
      _arrowHead(canvas, head.$1, head.$2);
    }

    // Samples circling the delay loop; the boxes drawn after hide them in transit.
    _dot(canvas, _along(t), 6, StudioColors.terracotta);
    _dot(canvas, _along((t + 0.5) % 1), 4, StudioColors.green);

    _box(canvas, const Rect.fromLTWH(0, 80, 130, 64), 'Noise burst', 'pluck(velocity)', StudioColors.line);
    _box(canvas, const Rect.fromLTWH(250, 80, 170, 64), 'Delay line', 'z⁻ᴺ · N = fs / f₀', StudioColors.saffron);
    _box(canvas, const Rect.fromLTWH(480, 80, 150, 64), 'Average', '½(1 + z⁻¹)', StudioColors.line);
    _box(canvas, const Rect.fromLTWH(480, 190, 150, 56), 'Damping ρ', 'energy lost per pass', StudioColors.line);

    canvas.drawCircle(const Offset(190, 112), 18, Paint()..color = StudioColors.surfaceRaised);
    canvas.drawCircle(const Offset(190, 112), 18, Paint()
      ..style = PaintingStyle.stroke
      ..color = StudioColors.muted);
    _text(canvas, '+', const Offset(190, 101), StudioText.body(18));

    canvas.drawCircle(const Offset(660, 112), 3.5, Paint()..color = StudioColors.saffron);
    _text(canvas, 'Out', const Offset(725, 88), StudioText.body(14, color: StudioColors.saffron));
    _text(canvas, 'feedback', const Offset(330, 198), StudioText.mono(11, color: StudioColors.dim));
  }

  Offset _along(double f) {
    final pts = [...loop, loop.first];
    var total = 0.0;
    for (var i = 0; i < pts.length - 1; i++) {
      total += (pts[i + 1] - pts[i]).distance;
    }
    var d = f * total;
    for (var i = 0; i < pts.length - 1; i++) {
      final seg = (pts[i + 1] - pts[i]).distance;
      if (d <= seg) return Offset.lerp(pts[i], pts[i + 1], d / seg)!;
      d -= seg;
    }
    return pts.first;
  }

  void _dot(Canvas canvas, Offset p, double r, Color c) {
    canvas.drawCircle(p, r + 4, Paint()
      ..color = c.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(p, r, Paint()..color = c);
  }

  void _dashed(Canvas canvas, List<Offset> pts, Paint paint) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    // Dashes march along the arrows as the signal flows.
    const dash = 6.0, gap = 6.0;
    final shift = t * 24 * 4 % (dash + gap);
    for (final m in path.computeMetrics()) {
      var d = -shift;
      while (d < m.length) {
        final a = max(0.0, d), b = min(m.length, d + dash);
        if (b > a) canvas.drawPath(m.extractPath(a, b), paint);
        d += dash + gap;
      }
    }
  }

  void _arrowHead(Canvas canvas, Offset tip, double angle) {
    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(angle);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(-9, -5)
        ..lineTo(-9, 5)
        ..close(),
      Paint()..color = StudioColors.saffron,
    );
    canvas.restore();
  }

  void _box(Canvas canvas, Rect r, String title, String sub, Color border) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(12));
    canvas.drawRRect(rr, Paint()..color = StudioColors.surfaceRaised);
    canvas.drawRRect(rr, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = border == StudioColors.line ? 1 : 2
      ..color = border);
    _text(canvas, title, Offset(r.center.dx, r.top + 14), StudioText.body(15));
    _text(canvas, sub, Offset(r.center.dx, r.top + 36), StudioText.mono(11, color: StudioColors.dim));
  }

  void _text(Canvas canvas, String text, Offset topCenter, TextStyle style) {
    final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, topCenter - Offset(tp.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant _LoopPainter old) => old.t != t;
}
