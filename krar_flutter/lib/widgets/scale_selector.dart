import 'package:flutter/material.dart';

enum ScaleType {
  tizitaMinor,
  tizitaMajor,
  ambassel,
  bati,
}

class ScaleSelector extends StatelessWidget {
  final Function(ScaleType) onScaleChanged;

  const ScaleSelector({
    super.key,
    required this.onScaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScaleButton(
            context,
            'Tizita Minor',
            ScaleType.tizitaMinor,
          ),
          _buildScaleButton(
            context,
            'Tizita Major',
            ScaleType.tizitaMajor,
          ),
          _buildScaleButton(
            context,
            'Ambassel',
            ScaleType.ambassel,
          ),
          _buildScaleButton(
            context,
            'Bati',
            ScaleType.bati,
          ),
        ],
      ),
    );
  }

  Widget _buildScaleButton(
    BuildContext context,
    String label,
    ScaleType scaleType,
  ) {
    return ElevatedButton(
      onPressed: () => onScaleChanged(scaleType),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      child: Text(label),
    );
  }
}
