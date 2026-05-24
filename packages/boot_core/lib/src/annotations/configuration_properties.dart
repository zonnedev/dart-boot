/// Binds configuration properties with the given prefix to this class.
/// Each setter/field is bound to prefix.propertyName from the environment.
class ConfigurationProperties {
  final String prefix;
  const ConfigurationProperties(this.prefix);
}
