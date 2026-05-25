import 'package:boot_core/boot_core.dart';
import 'package:test/test.dart';

void main() {
  group('parseDuration', () {
    test('milliseconds', () {
      expect(parseDuration('500ms'), Duration(milliseconds: 500));
    });

    test('seconds', () {
      expect(parseDuration('5s'), Duration(seconds: 5));
    });

    test('minutes', () {
      expect(parseDuration('2m'), Duration(minutes: 2));
    });

    test('hours', () {
      expect(parseDuration('1h'), Duration(hours: 1));
    });

    test('days', () {
      expect(parseDuration('7d'), Duration(days: 7));
    });

    test('trims whitespace', () {
      expect(parseDuration('  5s  '), Duration(seconds: 5));
    });

    test('throws on invalid format', () {
      expect(() => parseDuration('abc'), throwsFormatException);
    });

    test('throws on missing unit', () {
      expect(() => parseDuration('500'), throwsFormatException);
    });

    test('throws on empty string', () {
      expect(() => parseDuration(''), throwsFormatException);
    });
  });

  group('parseDurationOrNull', () {
    test('returns null for null input', () {
      expect(parseDurationOrNull(null), isNull);
    });

    test('returns null for empty string', () {
      expect(parseDurationOrNull(''), isNull);
    });

    test('parses valid input', () {
      expect(parseDurationOrNull('10s'), Duration(seconds: 10));
    });

    test('throws on invalid non-empty input', () {
      expect(() => parseDurationOrNull('bad'), throwsFormatException);
    });
  });
}
