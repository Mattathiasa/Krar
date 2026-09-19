import 'package:flutter_test/flutter_test.dart';
import 'package:krar_flutter/main.dart';

void main() {
  testWidgets('Krar app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KrarApp());
    expect(find.text('Krar & Begena Studio'), findsOneWidget);
  });
}
