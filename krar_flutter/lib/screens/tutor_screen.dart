import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../audio/krar_engine.dart';
import '../models/qenet.dart';
import '../theme/studio_theme.dart';
import '../widgets/studio_widgets.dart';
import 'tab_editor_screen.dart';

/// Krar strings for the lesson, tuned to Tizita Minor above G3.
const double kKrarRoot = 196.0;
const ScaleType kLessonScale = ScaleType.tizitaMinor;

/// Two bars of eighth notes; each value is a string index (0 = string 1).
const List<int> kLessonTab = [1, 3, 2, 4, 3, 5, 4, 2, 0, 2, 1, 3, 2, 4, 5, 3];

/// A tap within this many ms of the beat counts as on time.
const int kOnTimeWindowMs = 30;

class TutorScreen extends StatefulWidget {
  const TutorScreen({super.key, required this.engine});

  final KrarEngine engine;

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat();

  int _step = 0;
  bool _playing = false;
  bool _loop = true;
  bool _waitForMe = false;
  int _bpm = 72;
  Timer? _timer;
  DateTime _stepStartedAt = DateTime.now();

  /// Timing of the user's taps this pass: step index → ms early (−) or late (+).
  Map<int, int> _offsets = {};

  /// The previous pass stays on screen until the user taps in the new one.
  Map<int, int> _lastPass = {};

  Map<int, int> get _shownOffsets => _offsets.isEmpty ? _lastPass : _offsets;

  int get _end => _loop ? 8 : kLessonTab.length;
  Duration get _eighth => Duration(microseconds: (60e6 / _bpm / 2).round());
  int get _current => kLessonTab[_step];
  int get _next => kLessonTab[(_step + 1) % _end];

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  double _freq(int string) => kLessonScale.frequency(kKrarRoot, string);

  void _schedule() {
    _timer?.cancel();
    if (!_playing || _waitForMe) return;
    _timer = Timer.periodic(_eighth, (_) => _advance(sound: true));
  }

  void _advance({required bool sound}) {
    final next = (_step + 1) % _end;
    if (next == 0 && _offsets.isNotEmpty) {
      _lastPass = _offsets;
      _offsets = {};
    }
    if (sound) widget.engine.playFrequency(_freq(kLessonTab[next]));
    setState(() {
      _step = next;
      _stepStartedAt = DateTime.now();
    });
  }

  void _togglePlay() {
    widget.engine.resume();
    setState(() => _playing = !_playing);
    if (_playing && !_waitForMe) {
      widget.engine.playFrequency(_freq(_current));
      _stepStartedAt = DateTime.now();
    }
    _schedule();
  }

  void _restart() {
    setState(() {
      _step = 0;
      _offsets = {};
      _lastPass = {};
      _stepStartedAt = DateTime.now();
    });
    _schedule();
  }

  void _tempo(int delta) {
    setState(() => _bpm = (_bpm + delta).clamp(40, 160));
    _schedule();
  }

  /// The user plucks along. In wait mode this moves the lesson forward;
  /// otherwise it is scored against the nearest beat.
  void _tap() {
    widget.engine.resume();
    if (_waitForMe) {
      widget.engine.playFrequency(_freq(_current));
      _advance(sound: false);
      return;
    }
    if (!_playing) {
      widget.engine.playFrequency(_freq(_current));
      return;
    }
    final interval = _eighth.inMilliseconds;
    final since = DateTime.now().difference(_stepStartedAt).inMilliseconds;
    final early = since > interval / 2;
    final target = early ? (_step + 1) % _end : _step;
    setState(() => _offsets[target] = early ? since - interval : since);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final lesson = _lessonColumn(wide);
    if (!wide) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [lesson, const SizedBox(height: 20), _controls()],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(40, 28, 40, 28), child: lesson),
        ),
        Container(
          width: 360,
          decoration: const BoxDecoration(
            color: StudioColors.panel,
            border: Border(left: BorderSide(color: StudioColors.line)),
          ),
          child: SingleChildScrollView(padding: const EdgeInsets.all(28), child: _controls()),
        ),
      ],
    );
  }

  Widget _lessonColumn(bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(text: 'LESSON · ', style: StudioText.label()),
                    TextSpan(text: kLessonScale.label.toUpperCase(), style: StudioText.label(color: kLessonScale.hue)),
                    TextSpan(text: '  ${kLessonScale.geez}', style: StudioText.geez(13, color: kLessonScale.hue)),
                  ])),
                  const SizedBox(height: 8),
                  Text('Two-bar phrase', style: StudioText.display(wide ? 52 : 38)),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => TabEditorScreen(engine: widget.engine)),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(44, 44),
                foregroundColor: StudioColors.text,
                side: const BorderSide(color: StudioColors.line),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Edit tab'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _staff(),
        const SizedBox(height: 22),
        _timingCard(),
      ],
    );
  }

  Widget _staff() {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 34, 40, 26),
      decoration: BoxDecoration(
        color: StudioColors.paper,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 60, offset: Offset(0, 20))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('6-string krar tab · lines = strings, top = string 1',
                    style: StudioText.mono(12, color: StudioColors.paperMuted)),
              ),
              Text('♩ = $_bpm · 4/4 · beat ${(_step % 8) ~/ 2 + 1}',
                  style: StudioText.mono(12, color: StudioColors.paperMuted)),
            ],
          ),
          const SizedBox(height: 28),
          Semantics(
            label: 'Tab, now on note ${_step + 1} of ${kLessonTab.length}: pluck string ${_current + 1}',
            child: AspectRatio(
              aspectRatio: 920 / 250,
              child: FittedBox(
                child: SizedBox(
                  width: 920,
                  height: 250,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: _step.toDouble()),
                    duration: _playing && _step != 0 && motionEnabled(context) ? _eighth : Duration.zero,
                    builder: (context, head, _) => AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) => CustomPaint(
                        painter: _TabPainter(
                          step: _step,
                          head: head,
                          loop: _loop,
                          pulse: motionEnabled(context) ? _pulse.value : 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timingCard() {
    return StudioCard(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(
            'Your timing',
            trailing: Text(
              _shownOffsets.isEmpty ? 'Press Play, then tap along' : 'Above = early · band = on time · below = late',
              textAlign: TextAlign.right,
              style: StudioText.body(13, color: StudioColors.muted),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: Semantics(
              label: _timingSummary(),
              child: CustomPaint(painter: _TimingPainter(Map.of(_shownOffsets), _end)),
            ),
          ),
        ],
      ),
    );
  }

  String _timingSummary() {
    final shown = _shownOffsets;
    if (shown.isEmpty) return 'No taps recorded yet';
    final onTime = shown.values.where((o) => o.abs() <= kOnTimeWindowMs).length;
    return '$onTime of ${shown.length} taps on time';
  }

  Widget _controls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(
            child: StudioButton(
              label: _playing ? 'Pause' : 'Play along',
              icon: _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              height: 56,
              onPressed: _togglePlay,
            ),
          ),
          const SizedBox(width: 10),
          StudioIconButton(icon: Icons.replay_rounded, tooltip: 'Restart from bar 1', size: 56, onPressed: _restart),
        ]),
        const SizedBox(height: 26),
        const SectionLabel('Tempo'),
        const SizedBox(height: 12),
        Row(children: [
          StudioIconButton(icon: Icons.remove, tooltip: 'Slower', onPressed: () => _tempo(-4)),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: '$_bpm ', style: StudioText.mono(30)),
                  TextSpan(text: 'BPM', style: StudioText.mono(14, color: StudioColors.muted)),
                ]),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          StudioIconButton(icon: Icons.add, tooltip: 'Faster', onPressed: () => _tempo(4)),
        ]),
        const SizedBox(height: 12),
        ExcludeSemantics(
          child: Row(children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == (_step % 8) ~/ 2 ? StudioColors.saffron : StudioColors.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 18),
        _check('Wait for me', 'advances when you tap', _waitForMe, (v) {
          setState(() => _waitForMe = v);
          _schedule();
        }),
        _check('Loop bar 1', null, _loop, (v) {
          setState(() {
            _loop = v;
            _step %= _end;
            _offsets = {};
            _lastPass = {};
          });
        }),
        const SizedBox(height: 18),
        _pluckPad(),
      ],
    );
  }

  Widget _check(String label, String? hint, bool value, ValueChanged<bool> onChanged) {
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(children: [
            Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
            const SizedBox(width: 4),
            Text(label, style: StudioText.body(15)),
            if (hint != null) ...[
              const SizedBox(width: 8),
              Flexible(child: Text(hint, style: StudioText.body(13, color: StudioColors.dim))),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _pluckPad() {
    final color = StudioColors.krarStrings[_current];
    return Semantics(
      button: true,
      label: 'Pluck string ${_current + 1}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _tap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: StudioColors.surfaceRaised,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 1.5),
            ),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('PLUCK NOW · TAP HERE', style: StudioText.label()),
                  const SizedBox(height: 14),
                  Row(children: [
                    SizedBox(
                      width: 100,
                      height: 80,
                      child: FittedBox(
                        child: SizedBox(
                          width: 150,
                          height: 120,
                          child: AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, _) => CustomPaint(
                              painter: _MiniLyrePainter(_current, motionEnabled(context) ? _pulse.value : 0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('String ${_current + 1}', maxLines: 1, style: StudioText.display(44, color: color)),
                          ),
                          const SizedBox(height: 6),
                          Text('Next: string ${_next + 1}', style: StudioText.body(13, color: StudioColors.muted)),
                        ],
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabPainter extends CustomPainter {
  _TabPainter({required this.step, required this.head, required this.loop, required this.pulse});

  final int step;
  final double head;
  final bool loop;
  final double pulse;

  static double lineY(int s) => 30.0 + s * 32;
  static double noteX(num i) => 90.0 + i * 52;

  @override
  void paint(Canvas canvas, Size size) {
    const ink = StudioColors.paperInk;
    final current = kLessonTab[step];

    if (loop) {
      canvas.drawRRect(
        RRect.fromLTRBR(42, 4, 480, 224, const Radius.circular(6)),
        Paint()..color = StudioColors.saffron.withValues(alpha: 0.16),
      );
      _text(canvas, 'LOOP · bar 1', const Offset(48, -18), StudioText.mono(11, color: const Color(0xFF7A4E0E)), center: false);
    }

    for (var s = 0; s < 6; s++) {
      canvas.drawLine(
        Offset(40, lineY(s)),
        Offset(size.width, lineY(s)),
        Paint()
          ..strokeWidth = 2
          ..color = StudioColors.krarStrings[s].withValues(alpha: s == current ? 1 : 0.45),
      );
      _text(canvas, '${s + 1}', Offset(14, lineY(s) - 8), StudioText.mono(12, color: StudioColors.paperMuted, weight: FontWeight.w500));
    }

    final bar = Paint()..color = ink;
    canvas.drawRect(const Rect.fromLTWH(40, 20, 2, 180), bar);
    canvas.drawRect(const Rect.fromLTWH(480, 20, 2, 180), bar);
    canvas.drawRect(Rect.fromLTWH(size.width - 4, 20, 4, 180), bar);

    for (var b = 0; b < 8; b++) {
      canvas.drawRect(Rect.fromLTWH(89.0 + b * 104, 236, 54, 3), bar);
    }

    // Playhead glides toward the current note.
    final hx = noteX(head) - 26;
    canvas.drawRect(Rect.fromLTWH(hx - 1, -8, 3, 240), bar);
    canvas.drawCircle(Offset(hx + 0.5, -10), 6.5, bar);

    for (var i = 0; i < kLessonTab.length; i++) {
      final s = kLessonTab[i];
      final c = Offset(noteX(i), lineY(s));
      final color = StudioColors.krarStrings[s];
      canvas.drawRect(Rect.fromLTWH(c.dx - 1, 212, 2, 26), bar);
      final done = i < step, now = i == step;
      final r = now ? 19.5 : 15.0;
      if (now && pulse > 0) {
        canvas.drawCircle(c, r + 14 * pulse, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color.withValues(alpha: 1 - pulse));
      }
      canvas.drawCircle(c, r, Paint()..color = now ? color : StudioColors.paper);
      canvas.drawCircle(c, r - 1, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = done ? const Color(0xFFC9B9A2) : color);
      _text(canvas, '${s + 1}', c - const Offset(0, 9),
          StudioText.mono(now ? 16 : 13, color: done ? const Color(0xFF8F7F6E) : ink, weight: FontWeight.w600));
    }
  }

  void _text(Canvas canvas, String text, Offset at, TextStyle style, {bool center = true}) {
    final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, center ? at - Offset(tp.width / 2, 0) : at);
  }

  @override
  bool shouldRepaint(covariant _TabPainter old) =>
      old.step != step || old.head != head || old.loop != loop || old.pulse != pulse;
}

class _TimingPainter extends CustomPainter {
  _TimingPainter(this.offsets, this.steps);

  final Map<int, int> offsets;
  final int steps;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    const msToPx = 28 / 120;
    canvas.drawRRect(
      RRect.fromLTRBR(0, mid - kOnTimeWindowMs * msToPx, size.width, mid + kOnTimeWindowMs * msToPx, const Radius.circular(6)),
      Paint()..color = const Color(0xFF1E3328),
    );
    canvas.drawLine(Offset(0, mid), Offset(size.width, mid), Paint()..color = StudioColors.green.withValues(alpha: 0.6));
    offsets.forEach((i, ms) {
      final x = (i + 0.5) / steps * size.width;
      final y = mid + ms.clamp(-120, 120) * msToPx;
      final color = ms.abs() <= kOnTimeWindowMs ? StudioColors.green : StudioColors.saffron;
      canvas.drawCircle(Offset(x, y), 9, Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      canvas.drawCircle(Offset(x, y), 6, Paint()..color = color);
    });
  }

  @override
  bool shouldRepaint(covariant _TimingPainter old) => true;
}

class _MiniLyrePainter extends CustomPainter {
  _MiniLyrePainter(this.current, this.pulse);

  final int current;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(22, 12)
        ..lineTo(14, 100)
        ..lineTo(136, 100)
        ..lineTo(128, 12),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF6B5140),
    );
    canvas.drawRRect(const RRect.fromLTRBXY(10, 6, 140, 16, 5, 5), Paint()..color = StudioColors.woodLight);
    for (var s = 0; s < 6; s++) {
      final x = 35.0 + s * 16;
      final on = s == current;
      final bend = on ? sin(pulse * 2 * pi * 3) * 3 : 0.0;
      canvas.drawPath(
        Path()
          ..moveTo(x, 16)
          ..quadraticBezierTo(x + bend * 2, 54, x, 92),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = on ? 4 : 1.6
          ..color = on ? StudioColors.krarStrings[s] : StudioColors.dim.withValues(alpha: 0.7),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniLyrePainter old) => old.current != current || old.pulse != pulse;
}
