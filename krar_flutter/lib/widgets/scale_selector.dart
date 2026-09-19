import 'package:flutter/material.dart';

enum ScaleType {
  tizitaMinor,
  tizitaMajor,
  ambassel,
  bati,
}

extension ScaleTypeExtension on ScaleType {
  String get label {
    switch (this) {
      case ScaleType.tizitaMinor:
        return 'Tizita Minor';
      case ScaleType.tizitaMajor:
        return 'Tizita Major';
      case ScaleType.ambassel:
        return 'Ambassel';
      case ScaleType.bati:
        return 'Bati';
    }
  }

  String get description {
    switch (this) {
      case ScaleType.tizitaMinor:
        return 'Traditional Ethiopian minor scale';
      case ScaleType.tizitaMajor:
        return 'Major variant of Tizita';
      case ScaleType.ambassel:
        return 'Melancholic Ethiopian scale';
      case ScaleType.bati:
        return 'Bright Ethiopian scale';
    }
  }

  List<double> get intervals {
    switch (this) {
      case ScaleType.tizitaMinor:
        return [1.0, 1.189, 1.261, 1.337, 1.417, 1.500, 1.587, 1.682];
      case ScaleType.tizitaMajor:
        return [1.0, 1.189, 1.261, 1.337, 1.417, 1.500, 1.587, 1.682];
      case ScaleType.ambassel:
        return [1.0, 1.107, 1.199, 1.337, 1.417, 1.500, 1.587, 1.682];
      case ScaleType.bati:
        return [1.0, 1.107, 1.199, 1.337, 1.417, 1.500, 1.587, 1.682];
    }
  }
}

class ScaleSelector extends StatefulWidget {
  final Function(ScaleType) onScaleChanged;
  final ScaleType initialScale;

  const ScaleSelector({
    super.key,
    required this.onScaleChanged,
    this.initialScale = ScaleType.tizitaMinor,
  });

  @override
  State<ScaleSelector> createState() => _ScaleSelectorState();
}

class _ScaleSelectorState extends State<ScaleSelector> {
  late ScaleType _selectedScale;

  @override
  void initState() {
    super.initState();
    _selectedScale = widget.initialScale;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF0F3460),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scale',
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            children: ScaleType.values.map((scale) {
              final isSelected = scale == _selectedScale;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedScale = scale;
                      });
                      widget.onScaleChanged(scale);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE94560)
                            : const Color(0xFF0F3460),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFE94560)
                              : const Color(0xFF1A1A2E),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            scale.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.0,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(height: 4.0),
                            Text(
                              scale.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withAlpha(180),
                                fontSize: 9.0,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
