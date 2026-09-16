import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digiroutes_app/ui/screens/onboarding_screen.dart';
import 'package:digiroutes_app/logic/digipin.dart';

void main() {
  testWidgets('OnboardingScreen renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('What is DIGIPIN?'), findsOneWidget);
  });

  group('DIGIPIN unit tests', () {
    test('Encodes and decodes Delhi coordinates correctly', () {
      // New Delhi: ~28.6139° N, 77.2090° E
      const lat = 28.6139;
      const lon = 77.2090;
      final pin = getDigiPin(lat, lon);
      expect(pin.length, 10);

      final coords = getLatLngFromDigiPin(pin);
      expect((coords.latitude - lat).abs(), lessThan(0.01));
      expect((coords.longitude - lon).abs(), lessThan(0.01));
    });

    test('Throws on coordinates outside India bounds', () {
      expect(() => getDigiPin(51.5074, -0.1278), throwsArgumentError);
    });

    test('Throws on invalid DIGIPIN string', () {
      expect(() => getLatLngFromDigiPin('INVALIDPIN'), throwsArgumentError);
      expect(() => getLatLngFromDigiPin('123'), throwsArgumentError);
    });
  });
}
