import 'package:boot_http_common/boot_http_common.dart';


import 'logger.dart';

/// Built-in filter that logs every HTTP request with method, path, status, and duration.
class RequestLoggingFilter implements HttpServerFilter {
  final Logger _log = Logger('http');

  @override
  Future<Response> filter(Request request, FilterChain chain) async {
    final sw = Stopwatch()..start();
    final response = await chain.proceed(request);
    sw.stop();

    _log.info('${request.method} /${request.path}', {
      'status': response.statusCode,
      'duration': sw.elapsedMilliseconds,
    });

    return response;
  }
}
