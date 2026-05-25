import 'container/annotation_metadata.dart';
import 'container/bean_definition.dart';

/// Interface for modules that wire method-level annotations at runtime.
///
/// Implement this and register as a `@Singleton` bean. At startup,
/// `configureRuntime` discovers all processors and applies them to
/// beans that have matching [MethodMetadata].
abstract class MethodWiringProcessor {
  /// The annotation type this processor handles.
  AnnotationType get handles;

  /// Wire the annotated method on the given bean instance.
  void wire(Object instance, MethodMetadata method, BeanDefinition def);
}
