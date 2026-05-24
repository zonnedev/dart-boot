import 'package:boot_http_common/boot_http_common.dart';
import 'dart:convert';




/// Result of a health check.
class HealthResult {
  final bool up;
  final String? message;

  HealthResult._(this.up, this.message);
  factory HealthResult.up([String? message]) => HealthResult._(true, message);
  factory HealthResult.down([String? message]) => HealthResult._(false, message);

  Map<String, dynamic> toJson() => {
    'status': up ? 'UP' : 'DOWN',
    if (message != null) 'message': message,
  };
}

/// Implement to provide a custom health check.
/// Boot auto-discovers all HealthIndicator beans.
abstract class HealthIndicator {
  String get name;
  Future<HealthResult> check();
}

/// Internal handler for /health and /ready endpoints.
class HealthEndpoint {
  final List<HealthIndicator> _indicators;

  HealthEndpoint(this._indicators);

  /// Liveness — always UP if server is running.
  Future<Response> liveness(Request request) async {
    return Response(200,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'status': 'UP'}));
  }

  /// Readiness — checks all indicators.
  Future<Response> readiness(Request request) async {
    final checks = <String, Map<String, dynamic>>{};
    var allUp = true;

    for (final indicator in _indicators) {
      try {
        final result = await indicator.check();
        checks[indicator.name] = result.toJson();
        if (!result.up) allUp = false;
      } catch (e) {
        checks[indicator.name] = HealthResult.down('$e').toJson();
        allUp = false;
      }
    }

    final status = allUp ? 'UP' : 'DOWN';
    final statusCode = allUp ? 200 : 503;
    return Response(statusCode,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'status': status, 'checks': checks}));
  }
}
