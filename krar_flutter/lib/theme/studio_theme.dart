import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colour and type tokens for the "night studio" look: a warm charcoal
/// ground, gut-string cream, and one hue per string drawn from tibeb weaving.
class StudioColors {
  static const ground = Color(0xFF15120E);
  static const panel = Color(0xFF1A1511);
  static const stage = Color(0xFF1B1612);
  static const surface = Color(0xFF1F1A15);
  static const surfaceRaised = Color(0xFF221C16);
  static const navActive = Color(0xFF2B241C);
  static const line = Color(0xFF3B3229);

  static const text = Color(0xFFF3EADB);
  static const muted = Color(0xFFB3A391);
  static const dim = Color(0xFF8C7D6C);

  static const saffron = Color(0xFFE8B04A);
  static const saffronLight = Color(0xFFF6D08A);
  static const terracotta = Color(0xFFE2683C);
  static const rose = Color(0xFFD94F7A);
  static const violet = Color(0xFFA77BDB);
  static const green = Color(0xFF4DB38A);
  static const blue = Color(0xFF5E8FE6);
  static const teal = Color(0xFF74B8AC);

  static const woodLight = Color(0xFF8A6A4A);
  static const woodDark = Color(0xFF5A4230);
  static const bridge = Color(0xFFA8845E);
  static const skinLight = Color(0xFF4A3A2A);
  static const skinDark = Color(0xFF2E241A);

  static const paper = Color(0xFFF3EADB);
  static const paperInk = Color(0xFF15120E);
  static const paperMuted = Color(0xFF5C4F42);

  /// Begena: lowest string first.
  static const begenaStrings = [saffron, terracotta, rose, green, blue];

  /// Krar: string 1 (top of the tab) first.
  static const krarStrings = [saffron, terracotta, rose, violet, green, blue];

  static const tibeb = [saffron, green, terracotta, blue];
}

class StudioText {
  /// Tests turn this off so no fonts are fetched over the network.
  static bool useGoogleFonts = true;

  static TextStyle _font(TextStyle Function({TextStyle? textStyle}) google, String family, TextStyle style) =>
      useGoogleFonts ? google(textStyle: style) : style.copyWith(fontFamily: family);

  static TextStyle display(double size, {Color color = StudioColors.text, FontStyle? style}) => _font(
      GoogleFonts.instrumentSerif, 'Instrument Serif', TextStyle(fontSize: size, height: 1.0, color: color, fontStyle: style));

  static TextStyle body(double size,
          {Color color = StudioColors.text, FontWeight weight = FontWeight.w400, double? height}) =>
      _font(GoogleFonts.ibmPlexSans, 'IBM Plex Sans',
          TextStyle(fontSize: size, color: color, fontWeight: weight, height: height));

  static TextStyle mono(double size, {Color color = StudioColors.text, FontWeight weight = FontWeight.w400}) =>
      _font(GoogleFonts.ibmPlexMono, 'IBM Plex Mono', TextStyle(fontSize: size, color: color, fontWeight: weight));

  /// Small uppercase section label.
  static TextStyle label({Color color = StudioColors.muted}) => _font(GoogleFonts.ibmPlexMono, 'IBM Plex Mono',
      TextStyle(fontSize: 12, color: color, letterSpacing: 1.4, fontWeight: FontWeight.w500));

  static TextStyle geez(double size, {Color color = StudioColors.text}) =>
      _font(GoogleFonts.notoSansEthiopic, 'Noto Sans Ethiopic', TextStyle(fontSize: size, color: color));
}

ThemeData buildStudioTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: StudioColors.ground,
    colorScheme: const ColorScheme.dark(
      primary: StudioColors.saffron,
      onPrimary: StudioColors.ground,
      secondary: StudioColors.teal,
      surface: StudioColors.surface,
      onSurface: StudioColors.text,
      outline: StudioColors.line,
    ),
  );
  return base.copyWith(
    textTheme: (StudioText.useGoogleFonts
            ? GoogleFonts.ibmPlexSansTextTheme(base.textTheme)
            : base.textTheme.apply(fontFamily: 'IBM Plex Sans'))
        .apply(
      bodyColor: StudioColors.text,
      displayColor: StudioColors.text,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: StudioColors.saffron,
      inactiveTrackColor: StudioColors.line,
      thumbColor: StudioColors.saffron,
      overlayColor: Color(0x33E8B04A),
      trackHeight: 3,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? StudioColors.saffron : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(StudioColors.ground),
      side: const BorderSide(color: StudioColors.muted, width: 1.5),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: StudioColors.ground,
      foregroundColor: StudioColors.text,
      elevation: 0,
    ),
  );
}

/// Motion is on unless the platform asks for reduced animation.
bool motionEnabled(BuildContext context) => !MediaQuery.disableAnimationsOf(context);
