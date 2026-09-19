import 'package:flutter/material.dart';

import '../audio/krar_engine.dart';
import '../theme/studio_theme.dart';
import '../widgets/studio_widgets.dart';
import 'engine_screen.dart';
import 'piano_screen.dart';
import 'play_screen.dart';
import 'scales_screen.dart';
import 'tutor_screen.dart';

enum AudioStatus { starting, ready, unavailable }

class _Section {
  const _Section(this.label, this.shortLabel, this.icon, this.instrument);
  final String label;
  final String shortLabel;
  final IconData icon;
  final String? instrument;
}

const _sections = [
  _Section('Play', 'Play', Icons.music_note_outlined, 'Begena · 5 strings'),
  _Section('Piano', 'Piano', Icons.piano, 'Piano · 8 voices'),
  _Section('Scales', 'Scales', Icons.linear_scale, null),
  _Section('Tab Tutor', 'Tutor', Icons.school_outlined, 'Krar · 6 strings'),
  _Section('Engine', 'Engine', Icons.memory_outlined, null),
];

/// Top-level layout: header with section nav on wide screens, bottom nav on
/// phones. Owns the audio engine and unlocks it on the first touch.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.engine});

  /// Injected in tests; otherwise a real engine is created and started.
  final KrarEngine? engine;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final KrarEngine _engine = widget.engine ?? KrarEngine();
  AudioStatus _status = AudioStatus.starting;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.engine == null) _start();
  }

  Future<void> _start() async {
    try {
      await _engine.initialize();
      if (mounted) setState(() => _status = AudioStatus.ready);
    } catch (e) {
      debugPrint('Audio engine failed to start: $e');
      if (mounted) setState(() => _status = AudioStatus.unavailable);
    }
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  void _go(int i) => setState(() => _page = i);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final pages = [
      PlayScreen(engine: _engine),
      PianoScreen(engine: _engine),
      ScalesScreen(engine: _engine),
      TutorScreen(engine: _engine),
      const EngineScreen(),
    ];
    return Listener(
      // Browsers only let audio start after a user gesture.
      onPointerDown: (_) => _engine.resume(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              wide ? _wideHeader() : _narrowHeader(),
              const TibebBand(),
              Expanded(
                child: IndexedStack(
                  index: _page,
                  children: [
                    for (var i = 0; i < pages.length; i++) TickerMode(enabled: i == _page, child: pages[i]),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: wide ? null : _bottomNav(),
      ),
    );
  }

  Widget _wordmark({double size = 30}) {
    return Semantics(
      header: true,
      label: 'Krar and Begena Studio',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Krar & Begena', style: StudioText.display(size)),
            const SizedBox(width: 10),
            Text('STUDIO', style: StudioText.label(color: StudioColors.saffron)),
          ],
        ),
      ),
    );
  }

  Widget _wideHeader() {
    final width = MediaQuery.sizeOf(context).width;
    final instrument = width >= 1180 ? _sections[_page].instrument : null;
    return SizedBox(
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Row(
          children: [
            _wordmark(),
            const SizedBox(width: 40),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (var i = 0; i < _sections.length; i++)
                    _NavTab(label: _sections[i].label, selected: i == _page, onTap: () => _go(i)),
                ]),
              ),
            ),
            const SizedBox(width: 16),
            if (instrument != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: StudioColors.surface,
                  border: Border.all(color: StudioColors.line),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(instrument, style: StudioText.body(13, color: StudioColors.saffron, weight: FontWeight.w600)),
              ),
              const SizedBox(width: 24),
            ],
            _AudioStatusBadge(status: _status, compact: width < 1280),
          ],
        ),
      ),
    );
  }

  Widget _narrowHeader() {
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Flexible(
              child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: _wordmark(size: 24)),
            ),
            const SizedBox(width: 12),
            _AudioStatusBadge(status: _status, compact: true),
          ],
        ),
      ),
    );
  }

  Widget _bottomNav() {
    return NavigationBar(
      selectedIndex: _page,
      onDestinationSelected: _go,
      backgroundColor: StudioColors.panel,
      indicatorColor: StudioColors.navActive,
      height: 68,
      destinations: [
        for (final s in _sections) NavigationDestination(icon: Icon(s.icon), label: s.shortLabel),
      ],
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Semantics(
        button: true,
        selected: selected,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            backgroundColor: selected ? StudioColors.navActive : Colors.transparent,
            foregroundColor: selected ? StudioColors.text : StudioColors.muted,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(label,
              style: StudioText.body(14,
                  color: selected ? StudioColors.text : StudioColors.muted,
                  weight: selected ? FontWeight.w500 : FontWeight.w400)),
        ),
      ),
    );
  }
}

class _AudioStatusBadge extends StatefulWidget {
  const _AudioStatusBadge({required this.status, this.compact = false});

  final AudioStatus status;
  final bool compact;

  @override
  State<_AudioStatusBadge> createState() => _AudioStatusBadgeState();
}

class _AudioStatusBadgeState extends State<_AudioStatusBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (color, text) = switch (widget.status) {
      AudioStatus.starting => (StudioColors.saffron, 'Starting audio…'),
      AudioStatus.ready => (StudioColors.green, widget.compact ? '48 kHz' : 'AudioWorklet · 48 kHz · 128 fr'),
      AudioStatus.unavailable => (StudioColors.terracotta, 'Audio unavailable'),
    };
    final pulsing = widget.status == AudioStatus.ready && motionEnabled(context);
    return Semantics(
      liveRegion: true,
      label: 'Audio: $text',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: pulsing ? Tween(begin: 0.35, end: 1.0).animate(_pulse) : const AlwaysStoppedAnimation(1),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color, blurRadius: 10)],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(text, style: StudioText.mono(12, color: StudioColors.muted)),
          ],
        ),
      ),
    );
  }
}
