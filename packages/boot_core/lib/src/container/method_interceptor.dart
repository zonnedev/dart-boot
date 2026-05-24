/// Implement this to create a method interceptor.
/// This interface lives in boot_core because the container stores interceptors.
abstract class MethodInterceptor {
  dynamic intercept(covariant dynamic context);
}
