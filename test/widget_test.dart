import 'package:flutter_test/flutter_test.dart';

import 'package:froggy/models/weather.dart';

void main() {
  group('conditionFromWmo', () {
    test('clear codes map to sunny', () {
      expect(conditionFromWmo(0), WeatherCondition.sunny);
      expect(conditionFromWmo(1), WeatherCondition.sunny);
    });

    test('cloud codes map to cloudy', () {
      expect(conditionFromWmo(2), WeatherCondition.cloudy);
      expect(conditionFromWmo(3), WeatherCondition.cloudy);
    });

    test('fog codes map to hazy', () {
      expect(conditionFromWmo(45), WeatherCondition.hazy);
      expect(conditionFromWmo(48), WeatherCondition.hazy);
    });

    test('rain/drizzle/showers/thunder map to rainy', () {
      expect(conditionFromWmo(61), WeatherCondition.rainy);
      expect(conditionFromWmo(80), WeatherCondition.rainy);
      expect(conditionFromWmo(95), WeatherCondition.rainy);
    });

    test('snow codes map to snowy', () {
      expect(conditionFromWmo(71), WeatherCondition.snowy);
      expect(conditionFromWmo(86), WeatherCondition.snowy);
    });
  });

  group('dayPartFor', () {
    final sunrise = DateTime(2026, 6, 27, 6, 0);
    final sunset = DateTime(2026, 6, 27, 21, 0);

    test('before sunrise is night', () {
      expect(dayPartFor(DateTime(2026, 6, 27, 4, 0), sunrise, sunset),
          DayPart.night);
    });

    test('just after sunrise is morning', () {
      expect(dayPartFor(DateTime(2026, 6, 27, 7, 0), sunrise, sunset),
          DayPart.morning);
    });

    test('midday is day', () {
      expect(dayPartFor(DateTime(2026, 6, 27, 13, 0), sunrise, sunset),
          DayPart.day);
    });

    test('around sunset is sunset', () {
      expect(dayPartFor(DateTime(2026, 6, 27, 20, 30), sunrise, sunset),
          DayPart.sunset);
    });

    test('falls back to clock bands without sun times', () {
      expect(dayPartFor(DateTime(2026, 6, 27, 13, 0), null, null), DayPart.day);
      expect(
          dayPartFor(DateTime(2026, 6, 27, 2, 0), null, null), DayPart.night);
    });
  });
}
