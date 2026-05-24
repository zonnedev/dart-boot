import 'package:boot/boot.dart';

part 'rate_limit_filter.g.dart';

@ServerFilter()
@Order(0)
class RateLimitFilter implements HttpServerFilter {
  final _requests = <String, List<DateTime>>{};
  final int _maxRequests;

  RateLimitFilter(@Value('\${rate-limit.max:60}') this._maxRequests);

  @override
  Future<Response> filter(Request request, FilterChain chain) async {
    final clientIp = request.headers['x-forwarded-for'] ?? 'unknown';
    final now = DateTime.now();
    final oneMinuteAgo = now.subtract(Duration(minutes: 1));

    final history = _requests.putIfAbsent(clientIp, () => []);
    history.removeWhere((t) => t.isBefore(oneMinuteAgo));

    if (history.length >= _maxRequests) {
      return Response(429,
        headers: {
          'content-type': 'application/json',
          'retry-after': '60',
        },
        body: '{"error": "Too many requests. Limit: $_maxRequests per minute."}',
      );
    }

    history.add(now);
    return chain.proceed(request);
  }
}
