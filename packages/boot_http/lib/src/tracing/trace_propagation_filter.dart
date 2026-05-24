import 'package:boot_core/boot_core.dart';
import 'package:boot_http_common/boot_http_common.dart';

/// Client filter that propagates traceparent to outgoing HTTP calls.
/// Registered automatically when boot.tracing.propagation is enabled.
class TracePropagationFilter implements HttpClientFilter {
  @override
  Future<Response> filter(MutableRequest request, ClientFilterChain chain) async {
    final ctx = BootContext.current;
    if (ctx?.traceparent != null && !request.headers.containsKey('traceparent')) {
      request.headers['traceparent'] = ctx!.traceparent.toString();
    }
    return chain.proceed(request);
  }
}
