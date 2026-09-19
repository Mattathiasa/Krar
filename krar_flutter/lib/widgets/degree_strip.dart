import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/qenet.dart';
import '../theme/studio_theme.dart';

/// Eight playable scale-degree tiles. Each needle leans by how far the degree
/// sits from the nearest piano key.
class DegreeStrip extends StatefulWidget {
  const DegreeStrip({super.key, required this.scale, required this.onPlay});

  final ScaleType scale;
  final void Function(int degree) onPlay;

  @override
  State<DegreeStrip> createState() => _DegreeStripState();
}

class _DegreeStripState extends State<DegreeStrip> {
  int _active = -1;
  Timer? _timer;

  void _play(int i) {
    widget.onPlay(i);
    _timer?.cancel();
    setState(() => _active = i);
    _timer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _active = -1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cents = widget.scale.cents;
    return Row(
      children: [
        for (var i = 0; i < cents.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(child: _tile(i, cents[i])),
        ],
      ],
    );
  }

  Widget _tile(int i, double c) {
    final dev = deviationFromEqualTemperament(c);
    final on = _active == i;
    return Semantics(
      button: true,
      label: 'Play degree ${i + 1}, ${c.round()} cents, ${formatDeviation(dev)} from equal temperament',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _play(i),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 8),
            decoration: BoxDecoration(
              color: on ? const Color(0xFF3A2E1F) : StudioColors.surfaceRaised,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: on ? widget.scale.hue : StudioColors.surfaceRaised),
            ),
            child: ExcludeSemantics(
              child: Column(
                children: [
                  Text('${i + 1}', style: StudioText.mono(11, color: StudioColors.dim)),
                  const SizedBox(height: 6),
                  Text('${c.round()}', style: StudioText.mono(13)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 16,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: (dev * 1.6).clamp(-40, 40) * pi / 180),
                      duration: motionEnabled(context) ? const Duration(milliseconds: 500) : Duration.zero,
                      curve: Curves.elasticOut,
                      builder: (context, angle, _) => Transform.rotate(
                        angle: angle,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 2,
                          decoration: BoxDecoration(color: StudioColors.teal, borderRadius: BorderRadius.circular(1)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(formatDeviation(dev),
                      style: StudioText.mono(11, color: dev == 0 ? StudioColors.dim : StudioColors.teal)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
