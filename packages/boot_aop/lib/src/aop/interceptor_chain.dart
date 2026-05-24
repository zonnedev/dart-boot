import 'aop.dart';

/// Executes a chain of interceptors, then the original method.
class InterceptorChain {
  final List<MethodInterceptor> _interceptors;
  final String _methodName;
  final List<dynamic> _args;
  final dynamic _target;
  final dynamic Function() _originalMethod;

  InterceptorChain({
    required List<MethodInterceptor> interceptors,
    required String methodName,
    required List<dynamic> args,
    required dynamic target,
    required dynamic Function() originalMethod,
  })  : _interceptors = interceptors,
        _methodName = methodName,
        _args = args,
        _target = target,
        _originalMethod = originalMethod;

  /// Synchronous invocation.
  dynamic invoke() {
    if (_interceptors.isEmpty) return _originalMethod();

    var index = 0;

    dynamic next() {
      if (index >= _interceptors.length) return _originalMethod();
      final interceptor = _interceptors[index++];
      return interceptor.intercept(InvocationContext(
        methodName: _methodName,
        args: _args,
        target: _target,
        proceed: next,
      ));
    }

    return next();
  }

  /// Async invocation — awaits each interceptor and the original method.
  Future<dynamic> invokeAsync() async {
    if (_interceptors.isEmpty) return await _originalMethod();

    var index = 0;

    Future<dynamic> next() async {
      if (index >= _interceptors.length) return await _originalMethod();
      final interceptor = _interceptors[index++];
      return await interceptor.intercept(InvocationContext(
        methodName: _methodName,
        args: _args,
        target: _target,
        proceed: () => next(),
      ));
    }

    return next();
  }
}
