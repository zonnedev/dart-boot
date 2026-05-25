// coverage:ignore-file

/// Meta-annotation that marks an annotation as triggering method-level wiring.
///
/// When a method is annotated with an annotation that is itself annotated
/// with `@MethodHook`, the generator emits [MethodMetadata] and a `dispatch`
/// case for that method on the bean's [BeanDefinition].
///
/// At runtime, [MethodWiringProcessor] beans discover and wire these methods.
class MethodHook {
  const MethodHook();
}
