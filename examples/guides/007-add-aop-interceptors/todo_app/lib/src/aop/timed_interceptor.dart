import 'package:boot/boot.dart';
import 'timed.dart';

part 'timed_interceptor.g.dart';

@InterceptorBean(Timed)
class TimedInterceptor implements MethodInterceptor {
  static final _log = Logger('Timed');

  @override
  dynamic intercept(InvocationContext ctx) {
    final sw = Stopwatch()..start();
    final result = ctx.proceed();
    sw.stop();
    _log.info('${ctx.methodName}', {'duration_ms': sw.elapsedMilliseconds});
    return result;
  }
}
