import 'package:flutter/material.dart';

import '../models/qenet.dart';
import '../theme/studio_theme.dart';

export '../models/qenet.dart';

/// Two-by-two grid of the four qenet. The selected one fills with its hue.
class ScaleSelector extends StatelessWidget {
  const ScaleSelector({
    super.key,
    required this.selected,
    required this.onScaleChanged,
  });

  final ScaleType selected;
  final ValueChanged<ScaleType> onScaleChanged;

  @override
  Widget build(BuildContext context) {
    return GridView(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: 76,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final s in ScaleType.values)
          _QenetButton(
            scale: s,
            selected: s == selected,
            onTap: () => onScaleChanged(s),
          ),
      ],
    );
  }
}

class _QenetButton extends StatelessWidget {
  const _QenetButton({
    required this.scale,
    required this.selected,
    required this.onTap,
  });

  final ScaleType scale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? StudioColors.ground : StudioColors.text;
    return Semantics(
      button: true,
      selected: selected,
      label: '${scale.label}, ${scale.short}',
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 200),
        offset: selected ? const Offset(0, -0.03) : Offset.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? scale.hue : StudioColors.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? scale.hue : StudioColors.line,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: scale.hue.withValues(alpha: 0.3),
                          blurRadius: 16,
                        ),
                      ]
                    : null,
              ),
              child: ExcludeSemantics(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            scale.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: StudioText.body(
                              15,
                              color: fg,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          scale.geez,
                          style: StudioText.geez(
                            13,
                            color: fg.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scale.short,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StudioText.body(
                        12,
                        color: fg.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single qenet as a rounded chip, filled with its hue when selected.
class ScalePill extends StatelessWidget {
  const ScalePill({
    super.key,
    required this.scale,
    required this.selected,
    required this.onTap,
  });

  final ScaleType scale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            // Sized to its label, so it works in a Wrap as well as a scrolling row.
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: ShapeDecoration(
              color: selected ? scale.hue : StudioColors.surface,
              shape: StadiumBorder(
                side: BorderSide(
                  color: selected ? scale.hue : StudioColors.line,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  scale.label,
                  style: StudioText.body(
                    14,
                    color: selected ? StudioColors.ground : StudioColors.text,
                    weight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
