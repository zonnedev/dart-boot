import 'package:boot_http_common/boot_http_common.dart';
import 'package:boot_core/boot_core.dart';

/// Built-in filter that logs every HTTP request with method, path, status, and duration.
class RequestLoggingFilter implements HttpServerFilter {
  static final _log = Logger('http');

  @override
  Future<Response> filter(Request request, FilterChain chain) async {
    final sw = Stopwatch()..start();
    final ctx = BootContext.current; // capture before await
    final response = await chain.proceed(request);
    sw.stop();

    // Log within the original context zone to preserve trace IDs
    void doLog() {
      _log.info('${request.method} /${request.path}', {
        'status': response.statusCode,
        'duration': sw.elapsedMilliseconds,
      });
    }

    if (ctx != null) {
      ctx.run(doLog);
    } else {
      doLog();
    }

    return response;
  }
}
