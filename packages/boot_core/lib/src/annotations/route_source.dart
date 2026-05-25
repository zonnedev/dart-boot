// coverage:ignore-file
import 'bean_source.dart';

/// Meta-annotation that marks an annotation as producing HTTP routes.
///
/// When a class is annotated with an annotation that is itself annotated
/// with `@RouteSource`, the generator emits route registration code:
/// `router.addAll($XxxRoutes(bean).routes)`
///
/// Implies `@BeanSource` — the class is also registered as a bean.
@BeanSource()
class RouteSource {
  const RouteSource();
}
