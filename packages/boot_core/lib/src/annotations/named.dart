/// Qualifier that identifies a bean by name.
///
/// If [value] is omitted, it is derived from the class name:
/// `ReadOnlyPool` → `'readOnlyPool'`, `DiskCache` → `'diskCache'`.
class Named {
  final String? value;
  const Named([this.value]);
}
