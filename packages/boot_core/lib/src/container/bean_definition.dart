import 'annotation_metadata.dart';
import 'bean_container.dart';

/// Metadata about an annotated method on a bean.
class MethodMetadata {
  final String methodName;
  final List<AnnotationValue> annotations;
  final List<Type> parameterTypes;
  const MethodMetadata(this.methodName, this.annotations, [this.parameterTypes = const []]);
}

/// Compile-time generated bean definition.
abstract class BeanDefinition {
  /// The bean's runtime type.
  Type get beanType;

  /// Create the bean instance, resolving dependencies from the container.
  dynamic create(BeanContainer container);

  /// All annotations on this bean, resolved at compile time.
  List<AnnotationValue> get annotationMetadata => const [];

  /// Annotated methods on this bean (for @EventListener, @Scheduled, etc.)
  List<MethodMetadata> get methodMetadata => const [];

  /// Dispatch a method call on the bean instance without reflection.
  dynamic dispatch(Object instance, String method, List<dynamic> args) =>
      throw UnimplementedError('No dispatch for $beanType.$method');

  void postConstruct(dynamic instance) {}
  Future<void> postConstructAsync(dynamic instance) async {}
  void preDestroy(dynamic instance) {}
  Future<void> preDestroyAsync(dynamic instance) async {}

  bool get hasPostConstruct => false;
  bool get hasPostConstructAsync => false;
  bool get hasPreDestroy => false;
  bool get hasPreDestroyAsync => false;
}
