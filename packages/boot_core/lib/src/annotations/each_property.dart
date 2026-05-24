// coverage:ignore-file
/// Creates a bean for each sub-property under the given prefix.
///
/// For config like:
/// ```yaml
/// datasources:
///   primary:
///     url: localhost
///   analytics:
///     url: analytics-host
/// ```
///
/// `@EachProperty('datasources')` creates one bean per key (primary, analytics).
/// The bean's constructor receives a `String name` parameter with the key,
/// and `@Value` params resolve relative to that key's prefix.
class EachProperty {
  final String value;
  final bool list;

  const EachProperty(this.value, {this.list = false});
}

/// Creates a bean for each bean of the given configuration type.
/// Used with @EachProperty to produce dependent beans per config instance.
class EachBean {
  final Type value;

  const EachBean(this.value);
}
