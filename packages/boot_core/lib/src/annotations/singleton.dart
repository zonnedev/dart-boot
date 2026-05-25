// coverage:ignore-file
import 'bean_source.dart';

/// Marks a class as a singleton-scoped managed bean (one shared instance).
/// This is the default and most common scope.
@BeanSource()
class Singleton {
  /// Limits the types this bean is injectable as.
  final List<Type> typed;

  /// Method name to call when the bean is destroyed (for factory-produced beans).
  final String? preDestroy;

  const Singleton({this.typed = const [], this.preDestroy});
}
