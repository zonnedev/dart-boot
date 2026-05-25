// coverage:ignore-file
import 'bean_source.dart';

/// Marks a bean as prototype scope — a new instance is created each time it's injected.
@BeanSource()
class Prototype {
  const Prototype();
}
