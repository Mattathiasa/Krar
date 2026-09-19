import 'package:flutter/material.dart';

import '../theme/studio_theme.dart';

/// A woven strip of diamonds after the borders of Ethiopian tibeb cloth.
class TibebBand extends StatelessWidget {
  const TibebBand({super.key, this.height = 10});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _TibebPainter()),
      ),
    );
  }
}

class _TibebPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = StudioColors.surface);
    final h = size.height, w = h * 1.5;
    var i = 0;
    for (double x = 0; x < size.width; x += w, i++) {
      final path = Path()
        ..moveTo(x, h / 2)
        ..lineTo(x + w / 2, 0)
        ..lineTo(x + w, h / 2)
        ..lineTo(x + w / 2, h)
        ..close();
      canvas.drawPath(path, Paint()..color = StudioColors.tibeb[i % StudioColors.tibeb.length]);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final label = Semantics(header: true, child: Text(text.toUpperCase(), style: StudioText.label()));
    if (trailing == null) return label;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        label,
        const SizedBox(width: 12),
        Expanded(child: Align(alignment: Alignment.centerRight, child: trailing!)),
      ],
    );
  }
}

class StudioCard extends StatelessWidget {
  const StudioCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.borderColor});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        color: StudioColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? StudioColors.line),
      ),
      child: child,
    );
  }
}

/// A small stat: uppercase label over a mono value.
class StatReadout extends StatelessWidget {
  const StatReadout({super.key, required this.label, required this.value, this.unit});

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(), style: StudioText.label().copyWith(fontSize: 11)),
        const SizedBox(height: 4),
        Text.rich(TextSpan(children: [
          TextSpan(text: value, style: StudioText.mono(22)),
          if (unit != null) TextSpan(text: unit, style: StudioText.mono(22, color: StudioColors.dim)),
        ])),
      ],
    );
  }
}

/// Primary saffron button with an optional leading icon.
class StudioButton extends StatelessWidget {
  const StudioButton({super.key, required this.label, required this.onPressed, this.icon, this.height = 48});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label, style: StudioText.body(15, color: StudioColors.ground, weight: FontWeight.w600)),
        style: FilledButton.styleFrom(
          backgroundColor: StudioColors.saffron,
          foregroundColor: StudioColors.ground,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

/// Square outlined icon button, 44px minimum touch target.
class StudioIconButton extends StatelessWidget {
  const StudioIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed, this.size = 44});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          foregroundColor: StudioColors.text,
          backgroundColor: StudioColors.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: StudioColors.line),
          ),
        ),
      ),
    );
  }
}
