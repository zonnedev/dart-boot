/// Base exception for HTTP client errors (connection failures, timeouts, non-2xx responses).
class HttpClientException implements Exception {
  final String message;
  final Uri uri;
  final int? statusCode;
  final String? body;
  final Map<String, String>? headers;

  HttpClientException(this.message, this.uri, {this.statusCode, this.body, this.headers});

  @override
  String toString() => 'HttpClientException: $message (${uri.toString()})';
}

/// Remote returned a 4xx response.
class HttpClient4xxException extends HttpClientException {
  HttpClient4xxException(Uri uri, {required int statusCode, String? body, Map<String, String>? headers})
      : super('HTTP $statusCode', uri, statusCode: statusCode, body: body, headers: headers);
}

/// Remote returned a 5xx response.
class HttpClient5xxException extends HttpClientException {
  HttpClient5xxException(Uri uri, {required int statusCode, String? body, Map<String, String>? headers})
      : super('HTTP $statusCode', uri, statusCode: statusCode, body: body, headers: headers);
}
