/// Parse a duration string into a [Duration].
///
/// Supported formats: `500ms`, `5s`, `2m`, `1h`, `7d`.
///
/// Throws [FormatException] if the input is not a valid duration string.
///
/// ```dart
/// parseDuration('5s');    // Duration(seconds: 5)
/// parseDuration('500ms'); // Duration(milliseconds: 500)
/// parseDuration('abc');   // throws FormatException
/// ```
Duration parseDuration(String input) {
  final match = RegExp(r'^(\d+)(ms|s|m|h|d)$').firstMatch(input.trim());
  if (match == null) throw FormatException('Invalid duration: "$input"');
  final value = int.parse(match.group(1)!);
  return switch (match.group(2)) {
    'ms' => Duration(milliseconds: value),
    's' => Duration(seconds: value),
    'm' => Duration(minutes: value),
    'h' => Duration(hours: value),
    'd' => Duration(days: value),
    _ => throw FormatException('Invalid duration unit: ${match.group(2)}'),
  };
}

/// Parse a duration string, returning `null` only if [input] is null or empty.
///
/// If [input] is non-null and non-empty but malformed, throws [FormatException].
/// Use this for optional config values where absence is valid but bad format is not.
///
/// ```dart
/// parseDurationOrNull(null);    // null (key absent from config)
/// parseDurationOrNull('');      // null (empty value)
/// parseDurationOrNull('5s');    // Duration(seconds: 5)
/// parseDurationOrNull('abc');   // throws FormatException
/// ```
Duration? parseDurationOrNull(String? input) {
  if (input == null || input.isEmpty) return null;
  return parseDuration(input);
}
