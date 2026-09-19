import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../audio/krar_engine.dart';
import '../models/piano.dart';
import '../theme/studio_theme.dart';
import '../widgets/scale_selector.dart';

/// A playable piano with the chosen qenet laid over it, so each Ethiopian
/// pitch can be heard against the equal-tempered key beside it.
class PianoScreen extends StatefulWidget {
  const PianoScreen({super.key, required this.engine});

  final KrarEngine engine;

  @override
  State<PianoScreen> createState() => _PianoScreenState();
}

class _PianoScreenState extends State<PianoScreen> {
  ScaleType _scale = ScaleType.tizitaMinor;
  bool _compare = true;

  /// Keys currently under a finger or the mouse: pointer → MIDI note.
  final Map<int, int> _held = {};

  /// The piano key sounded as the reference in a comparison.
  int? _referenceKey;
  int _activeDegree = -1;
  final List<Timer> _timers = [];

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _after(Duration d, VoidCallback f) {
    _timers.add(Timer(d, () {
      if (mounted) f();
    }));
  }

  void _strike(int midi, double velocity) {
    widget.engine.resume();
    widget.engine.playPiano(PianoKey(midi).frequency, velocity: velocity);
  }

  void _playDegree(int degree) {
    final cents = _scale.cents[degree];
    final qenetFreq = _scale.frequency(PianoKey(kQenetRootMidi).frequency, degree);
    widget.engine.resume();
    if (!_compare) {
      widget.engine.playPiano(qenetFreq);
      setState(() => _activeDegree = degree);
      _after(const Duration(milliseconds: 600), () => setState(() => _activeDegree = -1));
      return;
    }
    // Piano key first, then the qenet pitch, so the lean is audible.
    final nearest = kQenetRootMidi + (cents / 100).round();
    _strike(nearest, 0.75);
    setState(() => _referenceKey = nearest);
    _after(const Duration(milliseconds: 450), () {
      widget.engine.playPiano(qenetFreq);
      setState(() {
        _referenceKey = null;
        _activeDegree = degree;
      });
    });
    _after(const Duration(milliseconds: 1100), () => setState(() => _activeDegree = -1));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final pad = wide ? 48.0 : 16.0;
    return ListView(
      padding: EdgeInsets.fromLTRB(pad, wide ? 30 : 20, pad, 32),
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: 'PIANO · EQUAL TEMPERAMENT · ', style: StudioText.label()),
          TextSpan(text: '${_scale.label.toUpperCase()} ', style: StudioText.label(color: _scale.hue)),
          TextSpan(text: _scale.geez, style: StudioText.geez(13, color: _scale.hue)),
        ])),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'Twelve keys, and the notes '),
            TextSpan(
              text: 'between them',
              style: StudioText.display(wide ? 56 : 36, color: _scale.hue, style: FontStyle.italic),
            ),
          ]),
          style: StudioText.display(wide ? 56 : 36),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            'Play the piano, then tap a numbered pad to hear a qenet degree. With compare on, you hear the '
            'nearest piano key first and then the Ethiopian pitch, so you can hear which way it leans.',
            style: StudioText.body(16, color: StudioColors.muted, height: 1.5),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in ScaleType.values)
              ScalePill(scale: s, selected: s == _scale, onTap: () => setState(() => _scale = s)),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: EdgeInsets.fromLTRB(wide ? 28 : 12, 20, wide ? 28 : 12, wide ? 28 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: StudioColors.line),
            gradient: const RadialGradient(
              center: Alignment(0, -0.4),
              radius: 1.1,
              colors: [Color(0xFF2C2219), StudioColors.stage],
            ),
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            final layout = _KeyboardLayout(
              low: wide ? 48 : 60,
              high: wide ? 84 : 72,
              width: constraints.maxWidth,
              height: wide ? 260 : 210,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 132, child: _qenetStrip(layout)),
                _keyboard(layout),
              ],
            );
          }),
        ),
        const SizedBox(height: 16),
        MergeSemantics(
          child: Row(
            children: [
              Switch(
                value: _compare,
                onChanged: (v) => setState(() => _compare = v),
                activeThumbColor: StudioColors.ground,
                activeTrackColor: StudioColors.saffron,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text('Compare with the nearest piano key', style: StudioText.body(15)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qenetStrip(_KeyboardLayout layout) {
    final cents = _scale.cents;
    const size = 48.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Leader lines from each pad down to where its pitch falls on the keys.
        Positioned.fill(
          child: CustomPaint(
            painter: _LeaderPainter(
              xs: [for (final c in cents) layout.xForCents(c)],
              padBottoms: [for (var d = 0; d < cents.length; d++) _padTop(d) + size],
              color: _scale.hue,
              active: _activeDegree,
            ),
          ),
        ),
        for (var d = 0; d < cents.length; d++)
          Positioned(
            left: layout.xForCents(cents[d]) - size / 2,
            top: _padTop(d),
            width: size,
            height: size,
            child: _QenetPad(
              degree: d,
              cents: cents[d],
              hue: _scale.hue,
              active: d == _activeDegree,
              onTap: () => _playDegree(d),
            ),
          ),
      ],
    );
  }

  /// Neighbouring degrees can be closer than a pad is wide, so alternate rows.
  double _padTop(int degree) => degree.isOdd ? 4 : 60;

  Widget _keyboard(_KeyboardLayout layout) {
    void down(PointerDownEvent e) {
      final midi = layout.hit(e.localPosition);
      if (midi == null) return;
      setState(() => _held[e.pointer] = midi);
      _strike(midi, layout.velocityAt(e.localPosition));
    }

    void move(PointerMoveEvent e) {
      if (!_held.containsKey(e.pointer)) return;
      final midi = layout.hit(e.localPosition);
      // Sliding along the keys plays each new one: a glissando.
      if (midi != null && midi != _held[e.pointer]) {
        setState(() => _held[e.pointer] = midi);
        _strike(midi, layout.velocityAt(e.localPosition));
      }
    }

    void up(PointerEvent e) {
      if (_held.remove(e.pointer) != null) setState(() {});
    }

    return Semantics(
      label: 'Piano keyboard, ${PianoKey(layout.low).name} to ${PianoKey(layout.high).name}. '
          'Use the numbered qenet pads above it to hear each scale degree.',
      child: Listener(
        onPointerDown: down,
        onPointerMove: move,
        onPointerUp: up,
        onPointerCancel: up,
        child: SizedBox(
          height: layout.height,
          child: CustomPaint(
            size: Size(layout.width, layout.height),
            painter: _KeyboardPainter(
              layout: layout,
              held: _held.values.toSet(),
              reference: _referenceKey,
              rootMarker: kQenetRootMidi,
              rootColor: _scale.hue,
            ),
          ),
        ),
      ),
    );
  }
}

class _QenetPad extends StatelessWidget {
  const _QenetPad({
    required this.degree,
    required this.cents,
    required this.hue,
    required this.active,
    required this.onTap,
  });

  final int degree;
  final double cents;
  final Color hue;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dev = deviationFromEqualTemperament(cents);
    return Semantics(
      button: true,
      label: 'Degree ${degree + 1}, ${cents.round()} cents, ${formatDeviation(dev)} from the nearest piano key',
      child: AnimatedScale(
        scale: active ? 1.18 : 1,
        duration: const Duration(milliseconds: 160),
        child: Material(
          color: hue,
          shape: const CircleBorder(),
          elevation: active ? 8 : 0,
          shadowColor: hue,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: ExcludeSemantics(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${degree + 1}', style: StudioText.mono(15, color: StudioColors.ground, weight: FontWeight.w600)),
                  Text(formatDeviation(dev, zero: '±0'), style: StudioText.mono(10, color: StudioColors.ground)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Key rectangles for a range of MIDI notes that starts and ends on a white key.
class _KeyboardLayout {
  _KeyboardLayout({required this.low, required this.high, required this.width, required this.height})
      : whites = [for (var m = low; m <= high; m++) if (!PianoKey(m).isBlack) m] {
    whiteW = width / whites.length;
    blackW = whiteW * 0.62;
    blackH = height * 0.62;
  }

  final int low, high;
  final double width, height;
  final List<int> whites;
  late final double whiteW, blackW, blackH;

  Iterable<int> get blacks sync* {
    for (var m = low; m <= high; m++) {
      if (PianoKey(m).isBlack) yield m;
    }
  }

  Rect rectFor(int midi) {
    if (!PianoKey(midi).isBlack) {
      return Rect.fromLTWH(whites.indexOf(midi) * whiteW, 0, whiteW, height);
    }
    final left = (whites.indexOf(midi - 1) + 1) * whiteW - blackW / 2;
    return Rect.fromLTWH(left, 0, blackW, blackH);
  }

  /// Horizontal position of a pitch [cents] above the qenet root, between
  /// the centres of the keys either side of it.
  double xForCents(double cents) {
    final semis = cents / 100;
    final below = kQenetRootMidi + semis.floor();
    final a = rectFor(below).center.dx;
    final b = below + 1 <= high ? rectFor(below + 1).center.dx : a;
    return lerpDouble(a, b, semis - semis.floor())!;
  }

  int? hit(Offset p) {
    for (final m in blacks) {
      if (rectFor(m).contains(p)) return m;
    }
    for (final m in whites) {
      if (rectFor(m).contains(p)) return m;
    }
    return null;
  }

  /// Playing nearer the front of a key is louder, as on a real piano.
  double velocityAt(Offset p) => (0.45 + 0.55 * (p.dy / height)).clamp(0.3, 1.0);
}

class _KeyboardPainter extends CustomPainter {
  _KeyboardPainter({
    required this.layout,
    required this.held,
    required this.reference,
    required this.rootMarker,
    required this.rootColor,
  });

  final _KeyboardLayout layout;
  final Set<int> held;
  final int? reference;
  final int rootMarker;
  final Color rootColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in layout.whites) {
      final r = layout.rectFor(m).deflate(1.5);
      final rr = RRect.fromRectAndCorners(r, bottomLeft: const Radius.circular(6), bottomRight: const Radius.circular(6));
      final color = held.contains(m)
          ? StudioColors.saffronLight
          : m == reference
              ? const Color(0xFFBFE3DC)
              : StudioColors.paper;
      canvas.drawRRect(rr, Paint()..color = color);
      if (m % 12 == 0) {
        final tp = TextPainter(
          text: TextSpan(text: PianoKey(m).name, style: StudioText.mono(11, color: StudioColors.paperMuted)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(r.center.dx - tp.width / 2, r.bottom - tp.height - 10));
      }
      if (m == rootMarker) {
        canvas.drawCircle(Offset(r.center.dx, r.bottom - 38), 5, Paint()..color = rootColor);
      }
    }
    for (final m in layout.blacks) {
      final r = layout.rectFor(m);
      final rr = RRect.fromRectAndCorners(r, bottomLeft: const Radius.circular(4), bottomRight: const Radius.circular(4));
      final color = held.contains(m)
          ? StudioColors.saffron
          : m == reference
              ? StudioColors.teal
              : const Color(0xFF1B1612);
      canvas.drawRRect(rr, Paint()..color = color);
      canvas.drawRRect(
        rr,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFF3B3229),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _KeyboardPainter old) =>
      old.layout.width != layout.width ||
      old.layout.low != layout.low ||
      old.held.length != held.length ||
      !old.held.containsAll(held) ||
      old.reference != reference ||
      old.rootColor != rootColor;
}

class _LeaderPainter extends CustomPainter {
  _LeaderPainter({required this.xs, required this.padBottoms, required this.color, required this.active});

  final List<double> xs;
  final List<double> padBottoms;
  final Color color;
  final int active;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < xs.length; i++) {
      canvas.drawLine(
        Offset(xs[i], padBottoms[i]),
        Offset(xs[i], size.height),
        Paint()
          ..strokeWidth = i == active ? 3 : 1.5
          ..color = (i == active ? color : StudioColors.teal).withValues(alpha: i == active ? 1 : 0.6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LeaderPainter old) => true;
}
