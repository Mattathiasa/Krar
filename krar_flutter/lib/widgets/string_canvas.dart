import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../audio/krar_engine.dart';
import '../models/string_config.dart';
import '../theme/studio_theme.dart';

/// Holds each string's visual energy and forwards plucks to the engine.
/// The canvas ticks it every frame; screens listen to [voices] and [last].
class StringCanvasController extends ChangeNotifier {
  StringCanvasController(this.engine, {this.numStrings = KrarEngine.stringCount})
      : energy = List.filled(numStrings, 0.0),
        phase = List.filled(numStrings, 0.0);

  final KrarEngine engine;
  final int numStrings;
  final List<double> energy;
  final List<double> phase;

  /// Strings still audibly ringing.
  final ValueNotifier<int> voices = ValueNotifier(0);

  /// The most recently plucked string.
  final ValueNotifier<int> last = ValueNotifier(1);

  /// Bumped when a string is plucked so the canvas can spawn a ripple.
  final List<PluckEvent> _pending = [];

  void pluck(int string, {double velocity = 0.85, Offset? at}) {
    if (string < 0 || string >= numStrings) return;
    engine.resume();
    engine.pluck(string, velocity);
    energy[string] = max(energy[string], velocity.clamp(0.3, 1.0));
    phase[string] = 0;
    last.value = string;
    _pending.add(PluckEvent(string, at));
    _updateVoices();
  }

  Future<void> strum({Duration gap = const Duration(milliseconds: 70)}) async {
    for (var i = 0; i < numStrings; i++) {
      pluck(i, velocity: 0.8);
      await Future<void>.delayed(gap);
    }
  }

  List<PluckEvent> takePending() {
    final out = List<PluckEvent>.of(_pending);
    _pending.clear();
    return out;
  }

  void tick(double dt) {
    for (var i = 0; i < numStrings; i++) {
      if (energy[i] <= 0) continue;
      energy[i] *= exp(-dt / 0.55);
      if (energy[i] < 0.02) energy[i] = 0;
      phase[i] += dt * (70 + i * 18);
    }
    _updateVoices();
    notifyListeners();
  }

  void _updateVoices() {
    final n = energy.where((e) => e > 0.08).length;
    if (voices.value != n) voices.value = n;
  }

  @override
  void dispose() {
    voices.dispose();
    last.dispose();
    super.dispose();
  }
}

class PluckEvent {
  PluckEvent(this.string, this.at);
  final int string;
  final Offset? at;
}

/// Where the frame and strings sit, in the canvas's own logical space.
class LyreGeometry {
  const LyreGeometry({
    required this.size,
    required this.xs,
    required this.top,
    required this.bottom,
    required this.bar,
    required this.box,
    required this.bridge,
    required this.arms,
    required this.labelY,
    required this.laces,
  });

  final Size size;
  final List<double> xs;
  final double top, bottom;
  final RRect bar, box, bridge;

  /// Left arm (top, bottom) then right arm (top, bottom).
  final List<Offset> arms;
  final double labelY;
  final List<double> laces;

  double get mid => (top + bottom) / 2;
  double get halfSpan => (bottom - top) / 2;
  double get catchWidth => (xs[1] - xs[0]) * 0.4;

  static const landscape = LyreGeometry(
    size: Size(960, 540),
    xs: [280, 380, 480, 580, 680],
    top: 68,
    bottom: 432,
    bar: RRect.fromLTRBXY(160, 34, 800, 68, 17, 17),
    box: RRect.fromLTRBXY(170, 420, 790, 520, 18, 18),
    bridge: RRect.fromLTRBXY(250, 432, 710, 446, 5, 5),
    arms: [Offset(200, 60), Offset(180, 440), Offset(760, 60), Offset(780, 440)],
    labelY: 470,
    laces: [200, 260, 320, 640, 700, 760],
  );

  /// Tall strings for phones held upright.
  static const portrait = LyreGeometry(
    size: Size(400, 640),
    xs: [72, 136, 200, 264, 328],
    top: 56,
    bottom: 520,
    bar: RRect.fromLTRBXY(16, 24, 384, 56, 16, 16),
    box: RRect.fromLTRBXY(20, 508, 380, 600, 18, 18),
    bridge: RRect.fromLTRBXY(44, 520, 356, 532, 5, 5),
    arms: [Offset(34, 48), Offset(26, 520), Offset(366, 48), Offset(374, 520)],
    labelY: 548,
    laces: [44, 356],
  );
}

class _Ripple {
  _Ripple(this.center, this.color);
  final Offset center;
  final Color color;
  double age = 0;
}

/// A begena seen face-on: vertical strings in a wooden frame over a skin
/// soundbox. Touch or click a string to pluck it, drag across to strum.
class StringCanvas extends StatefulWidget {
  const StringCanvas({super.key, required this.controller});

  final StringCanvasController controller;

  @override
  State<StringCanvas> createState() => _StringCanvasState();
}

class _StringCanvasState extends State<StringCanvas> with SingleTickerProviderStateMixin {
  // Drawing happens in a fixed logical space, scaled to fit.
  LyreGeometry g = LyreGeometry.landscape;

  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  double _clock = 0;
  final List<_Ripple> _ripples = [];
  final Map<int, Offset> _touches = {};
  final Map<int, double> _lastX = {};
  bool _touched = false;
  Rect _box = Rect.zero;

  StringCanvasController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration now) {
    final dt = ((now - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTick = now;
    _clock += dt;
    for (final e in c.takePending()) {
      final center = e.at ?? Offset(g.xs[e.string], g.mid);
      _ripples.add(_Ripple(center, StudioColors.begenaStrings[e.string]));
    }
    for (final r in _ripples) {
      r.age += dt;
    }
    _ripples.removeWhere((r) => r.age > 1.3);
    c.tick(dt);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Offset _toLogical(Offset p) =>
      Offset((p.dx - _box.left) / _box.width * g.size.width, (p.dy - _box.top) / _box.height * g.size.height);

  int? _stringNear(double x) {
    for (var i = 0; i < g.xs.length; i++) {
      if ((x - g.xs[i]).abs() <= g.catchWidth) return i;
    }
    return null;
  }

  double _velocityAt(double y) => (0.55 + 0.45 * (1 - ((y - g.mid).abs() / g.halfSpan))).clamp(0.3, 1.0);

  void _down(PointerDownEvent e) {
    final p = _toLogical(e.localPosition);
    if (p.dy < g.top - 20 || p.dy > g.bottom + 20) return;
    _touched = true;
    _touches[e.pointer] = p;
    _lastX[e.pointer] = p.dx;
    final s = _stringNear(p.dx);
    if (s != null) c.pluck(s, velocity: _velocityAt(p.dy), at: Offset(g.xs[s], p.dy));
  }

  void _move(PointerMoveEvent e) {
    if (!_touches.containsKey(e.pointer)) return;
    final p = _toLogical(e.localPosition);
    final prev = _lastX[e.pointer]!;
    // A finger dragged across a string plucks it, which is how strumming works.
    for (var i = 0; i < g.xs.length; i++) {
      final x = g.xs[i];
      if ((prev < x && p.dx >= x) || (prev > x && p.dx <= x)) {
        c.pluck(i, velocity: _velocityAt(p.dy), at: Offset(x, p.dy));
      }
    }
    _lastX[e.pointer] = p.dx;
    _touches[e.pointer] = p;
  }

  void _up(PointerEvent e) {
    _touches.remove(e.pointer);
    _lastX.remove(e.pointer);
  }

  @override
  Widget build(BuildContext context) {
    final motion = motionEnabled(context);
    return Semantics(
      label: 'Begena strings. Touch a string to pluck it, drag across strings to strum.',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: StudioColors.line),
          gradient: const RadialGradient(
            center: Alignment(0, -0.1),
            radius: 0.8,
            colors: [Color(0xFF2C2219), StudioColors.stage],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(builder: (context, constraints) {
          g = constraints.maxHeight > constraints.maxWidth * 0.9 ? LyreGeometry.portrait : LyreGeometry.landscape;
          final scale = min(constraints.maxWidth / g.size.width, constraints.maxHeight / g.size.height);
          final w = g.size.width * scale, h = g.size.height * scale;
          _box = Rect.fromLTWH((constraints.maxWidth - w) / 2, (constraints.maxHeight - h) / 2, w, h);
          return Stack(children: [
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _down,
                onPointerMove: _move,
                onPointerUp: _up,
                onPointerCancel: _up,
                child: CustomPaint(
                  painter: _LyrePainter(
                    repaint: c,
                    geometry: g,
                    box: _box,
                    controller: c,
                    ripples: _ripples,
                    touches: _touches,
                    clock: () => _clock,
                    idleHint: () => !_touched,
                    motion: motion,
                  ),
                ),
              ),
            ),
            if (g == LyreGeometry.landscape && constraints.maxHeight >= 420)
              Positioned(
                left: 20,
                top: 16,
                child: Text('Touch a string to pluck · drag across to strum · up to 10 fingers',
                    style: StudioText.mono(12, color: StudioColors.muted)),
              ),
          ]);
        }),
      ),
    );
  }
}

class _LyrePainter extends CustomPainter {
  _LyrePainter({
    required Listenable repaint,
    required this.geometry,
    required this.box,
    required this.controller,
    required this.ripples,
    required this.touches,
    required this.clock,
    required this.idleHint,
    required this.motion,
  }) : super(repaint: repaint);

  final LyreGeometry geometry;
  final Rect box;
  final StringCanvasController controller;
  final List<_Ripple> ripples;
  final Map<int, Offset> touches;
  final double Function() clock;
  final bool Function() idleHint;
  final bool motion;

  static const widths = [3.4, 3.0, 2.6, 2.2, 1.9];
  static const amps = [16.0, 14.0, 12.0, 10.0, 8.0];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(box.left, box.top);
    canvas.scale(box.width / geometry.size.width);

    _frame(canvas);

    final t = clock();
    for (final r in ripples) {
      final k = r.age / 1.3;
      canvas.drawCircle(
        r.center,
        motion ? 20 + 44 * k : 30,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = r.color.withValues(alpha: (1 - k) * 0.9),
      );
    }

    for (var i = 0; i < geometry.xs.length; i++) {
      _string(canvas, i, t);
    }

    for (final p in touches.values) {
      canvas.drawCircle(
        p,
        34,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0x55F3EADB), Color(0x00F3EADB)])
              .createShader(Rect.fromCircle(center: p, radius: 34)),
      );
      canvas.drawCircle(
          p,
          20,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = StudioColors.text);
    }

    _labels(canvas);
    canvas.restore();
  }

  void _frame(Canvas canvas) {
    final g = geometry;
    final wood = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [StudioColors.woodLight, StudioColors.woodDark],
      ).createShader(Offset.zero & g.size)
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(g.arms[0], g.arms[1], wood);
    canvas.drawLine(g.arms[2], g.arms[3], wood);

    canvas.drawRRect(
      g.box,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [StudioColors.skinLight, StudioColors.skinDark],
        ).createShader(g.box.outerRect),
    );
    canvas.drawRRect(
        g.box,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF6B5140));
    final lace = Paint()..color = StudioColors.woodLight;
    for (final x in g.laces) {
      canvas.drawCircle(Offset(x, g.box.top + 20), 3, lace);
    }

    canvas.drawRRect(g.bar, Paint()..shader = wood.shader);
    for (var i = 0; i < g.xs.length; i++) {
      canvas.drawCircle(Offset(g.xs[i], g.bar.center.dy), 4, Paint()..color = StudioColors.begenaStrings[i]);
    }
    canvas.drawRRect(g.bridge, Paint()..color = StudioColors.bridge);
  }

  void _string(Canvas canvas, int i, double t) {
    final g = geometry;
    final x = g.xs[i];
    final color = StudioColors.begenaStrings[i];
    final e = controller.energy[i];
    // Before the first touch a soft glow walks across the strings as an invitation.
    final hint = idleHint() && motion ? max(0.0, sin(t * 1.6 - i * 0.7)) * 0.35 : 0.0;

    final bend = motion ? e * amps[i] * sin(controller.phase[i]) : e * amps[i] * 0.6;
    final path = Path()
      ..moveTo(x, g.top)
      ..quadraticBezierTo(x + bend * 2, g.mid, x, g.bottom);

    final glow = max(e, hint);
    if (glow > 0.02) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = widths[i] + 8
          ..color = color.withValues(alpha: 0.45 * glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = widths[i] + e * 0.8
        ..color = color.withValues(alpha: 0.55 + 0.45 * max(e * 2, hint).clamp(0.0, 1.0)),
    );
  }

  void _labels(Canvas canvas) {
    for (var i = 0; i < 5; i++) {
      final s = StringConfig.begenaStrings[i];
      final lit = controller.energy[i] > 0.08;
      _text(canvas, s.name, Offset(geometry.xs[i], geometry.labelY),
          StudioText.mono(16, color: lit ? StudioColors.begenaStrings[i] : StudioColors.text));
      _text(canvas, '${s.frequency.round()} Hz', Offset(geometry.xs[i], geometry.labelY + 22),
          StudioText.mono(11, color: StudioColors.muted));
    }
  }

  void _text(Canvas canvas, String text, Offset topCenter, TextStyle style) {
    final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, topCenter - Offset(tp.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant _LyrePainter old) =>
      old.box != box || old.motion != motion || old.geometry != geometry;
}
