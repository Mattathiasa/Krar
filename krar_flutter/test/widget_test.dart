import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krar_flutter/audio/krar_engine.dart';
import 'package:krar_flutter/main.dart';
import 'package:krar_flutter/models/piano.dart';
import 'package:krar_flutter/models/qenet.dart';
import 'package:krar_flutter/screens/app_shell.dart';
import 'package:krar_flutter/theme/studio_theme.dart';

void main() {
  setUpAll(() => StudioText.useGoogleFonts = false);

  // The engine is never initialised here, so every audio call is a no-op.
  Widget app() => KrarApp(home: AppShell(engine: KrarEngine()));

  Future<void> goTo(WidgetTester tester, String label) async {
    final tab = find.text(label).last;
    await tester.ensureVisible(tab);
    await tester.tap(tab);
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('shows the studio with the begena and qenet picker', (tester) async {
    await pumpApp(tester);
    expect(find.text('Krar & Begena'), findsOneWidget);
    expect(find.text('Begena · 5 strings'), findsOneWidget);
    expect(find.text('Tizita Minor'), findsWidgets);
  });

  testWidgets('choosing a qenet retitles the studio', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Ambassel, Melancholic'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Ambassel'), findsNWidgets(2));
  });

  testWidgets('nav reaches every section', (tester) async {
    await pumpApp(tester);
    await goTo(tester, 'Scales');
    expect(find.byTooltip('Play Bati'), findsOneWidget);

    await goTo(tester, 'Tab Tutor');
    expect(find.text('Krar · 6 strings'), findsOneWidget);
    expect(find.text('Play along'), findsOneWidget);

    await goTo(tester, 'Engine');
    expect(find.text('Rust KrarEngine'), findsOneWidget);
  });

  testWidgets('piano page shows the keyboard and playable qenet pads', (tester) async {
    await pumpApp(tester);
    await goTo(tester, 'Piano');
    expect(find.text('Piano · 8 voices'), findsOneWidget);
    final pad = find.bySemanticsLabel(RegExp(r'^Degree 2, 282 cents'));
    expect(pad, findsOneWidget);
    await tester.tap(pad);
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Piano keyboard')));
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('tutor tempo buttons change the tempo', (tester) async {
    await pumpApp(tester);
    await goTo(tester, 'Tab Tutor');
    await tester.tap(find.byTooltip('Faster'));
    await tester.pump();
    expect(find.textContaining('♩ = 76'), findsOneWidget);
  });

  // Any overflow or build error fails the test, so this sweeps every page at
  // desktop, small-laptop and phone sizes.
  for (final size in const [Size(1440, 900), Size(1024, 768), Size(390, 844)]) {
    testWidgets('every page lays out cleanly at ${size.width.toInt()}×${size.height.toInt()}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app());
      await tester.pump(const Duration(milliseconds: 100));
      final tabs = size.width >= 900 ? ['Piano', 'Scales', 'Tab Tutor', 'Engine'] : ['Piano', 'Scales', 'Tutor', 'Engine'];
      for (final label in tabs) {
        await goTo(tester, label);
        await tester.pump(const Duration(seconds: 2));
      }
    });
  }

  group('qenet', () {
    test('deviation from equal temperament', () {
      expect(deviationFromEqualTemperament(282), -18);
      expect(deviationFromEqualTemperament(520), 20);
      expect(deviationFromEqualTemperament(1136), 36);
      expect(deviationFromEqualTemperament(678), -22);
    });

    test('piano keys are equal-tempered from A4 = 440 Hz', () {
      expect(const PianoKey(69).frequency, 440);
      expect(const PianoKey(60).frequency, closeTo(261.63, 0.01));
      expect(const PianoKey(61).isBlack, isTrue);
      expect(const PianoKey(64).isBlack, isFalse);
      expect(const PianoKey(60).name, 'C4');
    });

    test('degree frequencies follow the cent table', () {
      expect(ScaleType.bati.frequency(200, 0), 200);
      expect(ScaleType.bati.frequency(200, 7), closeTo(200 * 1.927, 0.1));
      expect(formatDeviation(-18), '−18');
      expect(formatDeviation(0, zero: '±0'), '±0');
    });
  });
}
