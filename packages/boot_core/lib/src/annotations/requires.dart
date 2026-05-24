// coverage:ignore-file
/// Conditional bean loading. The bean is only registered if all conditions are met.
///
/// Can be applied multiple times (repeatable) — all conditions must pass.
class Requires {
  /// The bean only loads in these environments (BOOT_ENV).
  final List<String> env;

  /// The bean will NOT load in these environments.
  final List<String> notEnv;

  /// The bean only loads if this property is set (and optionally equals [value]).
  final String? property;

  /// Used with [property] — the property must equal this value.
  final String? value;

  /// Used with [property] — the property must NOT equal this value.
  final String? notEquals;

  /// Used with [property] — default value if the property is not set.
  final String? defaultValue;

  /// The bean only loads if this property is NOT set.
  final String? missingProperty;

  /// The bean only loads if ALL of these bean types are present in the container.
  final List<Type> beans;

  /// The bean only loads if NONE of these bean types are present in the container.
  /// Use this to provide a default implementation that users can override.
  final List<Type> missingBeans;

  const Requires({
    this.env = const [],
    this.notEnv = const [],
    this.property,
    this.value,
    this.notEquals,
    this.defaultValue,
    this.missingProperty,
    this.beans = const [],
    this.missingBeans = const [],
  });
}
