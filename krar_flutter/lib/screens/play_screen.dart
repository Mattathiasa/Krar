import 'package:flutter/material.dart';

import '../audio/krar_engine.dart';
import '../models/string_config.dart';
import '../theme/studio_theme.dart';
import '../widgets/degree_strip.dart';
import '../widgets/output_meters.dart';
import '../widgets/scale_selector.dart';
import '../widgets/string_canvas.dart';
import '../widgets/studio_widgets.dart';

/// Degree tiles play an octave above the lowest begena string (Db3).
const double kDegreeRoot = 138.59;

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.engine});

  final KrarEngine engine;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late final StringCanvasController _strings = StringCanvasController(widget.engine);
  ScaleType _scale = ScaleType.tizitaMinor;
  double _volume = 0.8;
  double _reverb = 0.2;

  @override
  void dispose() {
    _strings.dispose();
    super.dispose();
  }

  void _setScale(ScaleType s) {
    setState(() => _scale = s);
    widget.engine.setScale(s);
  }

  void _playDegree(int i) {
    widget.engine.resume();
    widget.engine.playFrequency(_scale.frequency(kDegreeRoot, i));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return wide ? _wide() : _narrow();
  }

  Widget _wide() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _titleRow(),
                const SizedBox(height: 18),
                Expanded(child: StringCanvas(controller: _strings)),
                const SizedBox(height: 18),
                SizedBox(
                  height: 92,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 220, child: _partials()),
                      const SizedBox(width: 14),
                      Expanded(child: OutputScope(engine: widget.engine)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: MediaQuery.sizeOf(context).width >= 1200 ? 400 : 340,
          decoration: const BoxDecoration(
            color: StudioColors.panel,
            border: Border(left: BorderSide(color: StudioColors.line)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionLabel('Qenet · mode'),
                const SizedBox(height: 14),
                ScaleSelector(selected: _scale, onScaleChanged: _setScale),
                const SizedBox(height: 26),
                const SectionLabel('Play the degrees'),
                const SizedBox(height: 12),
                DegreeStrip(scale: _scale, onPlay: _playDegree),
                const SizedBox(height: 12),
                Text(
                  'Needles lean toward how far each degree sits from the nearest piano key. Tap one to hear it.',
                  style: StudioText.body(13, color: StudioColors.muted, height: 1.5),
                ),
                const SizedBox(height: 26),
                const SectionLabel('Mix'),
                const SizedBox(height: 8),
                _slider('Master volume', _volume, (v) {
                  setState(() => _volume = v);
                  widget.engine.setMasterVolume(v);
                }),
                _slider('Reverb', _reverb, (v) {
                  setState(() => _reverb = v);
                  widget.engine.setReverb(v);
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _narrow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(_scale.label,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: StudioText.display(34, color: _scale.hue)),
              ),
              StudioButton(label: 'Strum', icon: Icons.waves, height: 44, onPressed: _strings.strum),
            ],
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            children: [
              for (final s in ScaleType.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ScalePill(scale: s, selected: s == _scale, onTap: () => _setScale(s)),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: StringCanvas(controller: _strings),
          ),
        ),
        if (MediaQuery.sizeOf(context).height >= 720)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: DegreeStrip(scale: _scale, onPlay: _playDegree),
          )
        else
          const SizedBox(height: 12),
      ],
    );
  }

  Widget _titleRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: 'NOW TUNED TO  ', style: StudioText.label()),
                TextSpan(text: 'ቅኝት · ${_scale.geez}', style: StudioText.geez(13, color: _scale.hue)),
              ])),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: StudioText.display(56, color: _scale.hue),
                  child: Text(_scale.label, maxLines: 1),
                ),
              ),
            ],
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: _strings.voices,
          builder: (context, v, _) => StatReadout(label: 'Voices', value: '$v', unit: ' / ${KrarEngine.stringCount}'),
        ),
        if (MediaQuery.sizeOf(context).width >= 1300) ...[
          const SizedBox(width: 28),
          const StatReadout(label: 'Block', value: '2.67', unit: ' ms'),
        ],
        const SizedBox(width: 28),
        StudioButton(label: 'Strum', icon: Icons.waves, onPressed: _strings.strum),
      ],
    );
  }

  Widget _partials() {
    return AnimatedBuilder(
      animation: _strings,
      builder: (context, _) {
        final i = _strings.last.value;
        return PartialsMeter(
          color: StudioColors.begenaStrings[i],
          name: StringConfig.begenaStrings[i].name,
          energy: _strings.energy[i],
        );
      },
    );
  }

  Widget _slider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: StudioText.body(14)),
              Text(value.toStringAsFixed(2), style: StudioText.mono(14, color: StudioColors.muted)),
            ],
          ),
        ),
        Slider(value: value, onChanged: onChanged, label: label),
      ],
    );
  }
}
