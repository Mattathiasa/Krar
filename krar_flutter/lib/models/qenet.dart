import 'dart:math';
import 'dart:ui';

import '../theme/studio_theme.dart';

/// The four Ethiopian qenet (modes). Index order matches the Rust `ScaleType`.
enum ScaleType {
  tizitaMinor,
  tizitaMajor,
  ambassel,
  bati,
}

extension ScaleTypeExtension on ScaleType {
  String get label => switch (this) {
        ScaleType.tizitaMinor => 'Tizita Minor',
        ScaleType.tizitaMajor => 'Tizita Major',
        ScaleType.ambassel => 'Ambassel',
        ScaleType.bati => 'Bati',
      };

  String get geez => switch (this) {
        ScaleType.tizitaMinor || ScaleType.tizitaMajor => 'ትዝታ',
        ScaleType.ambassel => 'አምባሰል',
        ScaleType.bati => 'ባቲ',
      };

  String get short => switch (this) {
        ScaleType.tizitaMinor => 'Nostalgia, minor',
        ScaleType.tizitaMajor => 'Nostalgia, major',
        ScaleType.ambassel => 'Melancholic',
        ScaleType.bati => 'Bright',
      };

  String get description => switch (this) {
        ScaleType.tizitaMinor => 'Traditional Ethiopian scale with minor character',
        ScaleType.tizitaMajor => 'Major variant of the Tizita scale',
        ScaleType.ambassel => 'Melancholic Ethiopian scale',
        ScaleType.bati => 'Bright Ethiopian scale',
      };

  Color get hue => switch (this) {
        ScaleType.tizitaMinor => StudioColors.saffron,
        ScaleType.tizitaMajor => StudioColors.terracotta,
        ScaleType.ambassel => StudioColors.blue,
        ScaleType.bati => StudioColors.green,
      };

  /// Cents from the root for each degree (same table as krar_engine/src/scale.rs).
  List<double> get cents => switch (this) {
        ScaleType.tizitaMinor || ScaleType.tizitaMajor => const [0, 282, 386, 520, 678, 884, 1018, 1136],
        ScaleType.ambassel => const [0, 182, 316, 520, 678, 812, 1018, 1136],
        ScaleType.bati => const [0, 182, 316, 498, 678, 884, 1018, 1136],
      };

  List<double> get intervals => switch (this) {
        ScaleType.tizitaMinor || ScaleType.tizitaMajor => const [1.0, 1.189, 1.261, 1.337, 1.417, 1.500, 1.587, 1.682],
        ScaleType.ambassel || ScaleType.bati => const [1.0, 1.107, 1.199, 1.337, 1.417, 1.500, 1.587, 1.682],
      };

  /// Frequency of [degree] above [root], from the cent table.
  double frequency(double root, int degree) => root * pow(2, cents[degree] / 1200).toDouble();
}

/// Signed distance in cents from [cents] to the nearest 12-TET semitone.
int deviationFromEqualTemperament(double cents) => (cents - (cents / 100).round() * 100).round();

String formatDeviation(int dev, {String zero = '0'}) {
  if (dev == 0) return zero;
  return dev > 0 ? '+$dev' : '−${dev.abs()}';
}
