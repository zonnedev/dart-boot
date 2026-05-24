// coverage:ignore-file

/// Meta-annotation that marks an annotation as a bean source.
///
/// When a class is annotated with an annotation that is itself annotated
/// with `@BeanSource`, the framework treats that class as a bean and
/// registers it in the container.
///
/// This allows modules to define their own bean-producing annotations
/// (like `@Client`) without the core generator needing to know about them.
///
/// Example:
/// ```dart
/// @BeanSource()
/// class Client {
///   final String url;
///   const Client({this.url = ''});
/// }
/// ```
///
/// The generator will then register any class annotated with `@Client`
/// using the convention `$${className}Definition`.
class BeanSource {
  const BeanSource();
}
