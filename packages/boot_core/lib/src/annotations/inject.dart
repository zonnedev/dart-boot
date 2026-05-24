/// Qualifier for constructor parameter injection.
class Inject {
  /// Optional named qualifier to disambiguate beans of the same type.
  final String? name;

  const Inject({this.name});
}
