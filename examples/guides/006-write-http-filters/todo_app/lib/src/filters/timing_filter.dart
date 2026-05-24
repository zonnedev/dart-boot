import 'package:boot/boot.dart';

part 'timing_filter.g.dart';

@ServerFilter()
@Order(2)
class TimingFilter implements HttpServerFilter {
  static final _log = Logger('TimingFilter');

  @override
  Future<Response> filter(Request request, FilterChain chain) async {
    final stopwatch = Stopwatch()..start();
    final response = await chain.proceed(request);
    stopwatch.stop();
    _log.info('${request.method} ${request.path}', {
      'status': response.statusCode,
      'duration_ms': stopwatch.elapsedMilliseconds,
    });
    return response;
  }
}
