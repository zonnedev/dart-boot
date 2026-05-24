import 'package:boot/boot.dart';
import 'cached.dart';

part 'cached_interceptor.g.dart';

@InterceptorBean(Cached)
class CachedInterceptor implements MethodInterceptor {
  final _cache = <String, dynamic>{};

  @override
  dynamic intercept(InvocationContext ctx) {
    final key = '${ctx.methodName}:${ctx.args}';

    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    final result = ctx.proceed();
    _cache[key] = result;
    return result;
  }

  void clear() => _cache.clear();
}
