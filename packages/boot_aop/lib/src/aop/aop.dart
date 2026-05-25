// coverage:ignore-file
import 'package:boot_core/boot_core.dart';

export 'package:boot_core/boot_core.dart' show MethodInterceptor;

/// Meta-annotation: marks an annotation as providing Around advice.
class Around {
  const Around();
}

/// Associates an interceptor with an advice annotation.
@BeanSource()
class InterceptorBean {
  final Type value;
  const InterceptorBean(this.value);
}

/// Context passed to interceptors during method invocation.
class InvocationContext {
  final String methodName;
  final List<dynamic> args;
  final dynamic target;
  final dynamic Function() _proceed;

  InvocationContext({
    required this.methodName,
    required this.args,
    required this.target,
    required dynamic Function() proceed,
  }) : _proceed = proceed;

  /// Call the next interceptor or the original method.
  dynamic proceed() => _proceed();
}
