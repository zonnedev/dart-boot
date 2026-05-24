import 'dart:math';
import 'package:boot/boot.dart';

part 'request_id_filter.g.dart';

@ServerFilter()
@Order(1)
class RequestIdFilter implements HttpServerFilter {
  final _random = Random();

  @override
  Future<Response> filter(Request request, FilterChain chain) async {
    final requestId = _generateId();
    request.setAttribute('requestId', requestId);

    final response = await chain.proceed(request);

    return Response(
      response.statusCode,
      headers: {...response.headers, 'x-request-id': requestId},
      body: response.body,
    );
  }

  String _generateId() {
    return List.generate(16, (_) => _random.nextInt(16).toRadixString(16)).join();
  }
}
