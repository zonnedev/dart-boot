// coverage:ignore-file
import 'bean_source.dart';

/// Marks a class as a bean factory. Methods annotated with @Singleton or @Prototype
/// produce beans that are registered in the container.
@BeanSource()
class Factory {
  const Factory();
}
