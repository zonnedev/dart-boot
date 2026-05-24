import 'dart:convert';
import 'dart:io' as io;

import 'client_configuration.dart';
import 'client_exceptions.dart';
import 'package:boot_http_common/boot_http_common.dart';

/// Fluent builder for creating configured [HttpClient] instances.
/// Injected as a prototype bean — each injection gets a fresh builder pre-loaded with YAML defaults.
class HttpClientBuilder {
  String? _baseUrl;
  Duration _connectTimeout;
  Duration _readTimeout;
  int _maxRedirects;
  bool _followRedirects;
  final Map<String, String> _defaultHeaders = {};
  final List<HttpClientFilter> _filters = [];

  HttpClientBuilder({
    Duration connectTimeout = const Duration(seconds: 5),
    Duration readTimeout = const Duration(seconds: 30),
    int maxRedirects = 5,
    bool followRedirects = true,
  })  : _connectTimeout = connectTimeout,
        _readTimeout = readTimeout,
        _maxRedirects = maxRedirects,
        _followRedirects = followRedirects;

  /// Create a builder pre-loaded from a service config section.
  factory HttpClientBuilder.fromServiceConfig(HttpClientConfiguration config, {String? baseUrl}) {
    return HttpClientBuilder(
      connectTimeout: config.connectTimeout,
      readTimeout: config.readTimeout,
      maxRedirects: config.maxRedirects,
    ).._baseUrl = baseUrl;
  }

  HttpClientBuilder baseUrl(String url) {
    _baseUrl = url;
    return this;
  }

  HttpClientBuilder connectTimeout(Duration d) {
    _connectTimeout = d;
    return this;
  }

  HttpClientBuilder readTimeout(Duration d) {
    _readTimeout = d;
    return this;
  }

  HttpClientBuilder maxRedirects(int n) {
    _maxRedirects = n;
    return this;
  }

  HttpClientBuilder followRedirects(bool v) {
    _followRedirects = v;
    return this;
  }

  HttpClientBuilder defaultHeader(String key, String value) {
    _defaultHeaders[key] = value;
    return this;
  }

  HttpClientBuilder filter(HttpClientFilter f) {
    _filters.add(f);
    return this;
  }

  /// Build the [HttpClient] with all configured settings.
  HttpClient build() {
    return HttpClient(
      baseUrl: _baseUrl,
      connectTimeout: _connectTimeout,
      readTimeout: _readTimeout,
      maxRedirects: _maxRedirects,
      followRedirects: _followRedirects,
      defaultHeaders: Map.unmodifiable(_defaultHeaders),
      filters: List.unmodifiable(_filters),
    );
  }
}

/// HTTP client with configured timeouts, headers, and filters.
/// Use [HttpClientBuilder] to create instances.
class HttpClient {
  final io.HttpClient _client = io.HttpClient();
  final String? baseUrl;
  final Duration readTimeout;
  final int maxRedirects;
  final bool followRedirects;
  final Map<String, String> defaultHeaders;
  final List<HttpClientFilter> _filters;

  HttpClient({
    this.baseUrl,
    Duration connectTimeout = const Duration(seconds: 5),
    this.readTimeout = const Duration(seconds: 30),
    this.maxRedirects = 5,
    this.followRedirects = true,
    this.defaultHeaders = const {},
    List<HttpClientFilter> filters = const [],
  }) : _filters = List.of(filters) {
    _client.connectionTimeout = connectTimeout;
  }

  /// Register an additional filter at runtime.
  void addFilter(HttpClientFilter filter) => _filters.add(filter);

  /// Send an HTTP request.
  Future<ClientResponse> send(
    String method,
    String url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final resolvedUrl = (baseUrl != null && !url.startsWith('http')) ? '$baseUrl$url' : url;
    final mergedHeaders = {...defaultHeaders, ...?headers};

    final request = MutableRequest(
      method: method,
      uri: Uri.parse(resolvedUrl),
      headers: mergedHeaders,
      body: body != null ? (body is String ? body : _jsonEncode(body)) : null,
    );

    ClientResponse result;
    if (_filters.isNotEmpty) {
      final chain = _HttpClientFilterChain(_filters, _doSend);
      final response = await chain.proceed(request);
      result = ClientResponse(
        statusCode: response.statusCode,
        body: response.body ?? '',
        headers: response.headers,
      );
    } else {
      result = await _doSend(request);
    }

    _throwIfError(result, request.uri);
    return result;
  }

  Future<ClientResponse> _doSend(MutableRequest request) async {
    try {
      final ioRequest = await _client.openUrl(request.method, request.uri);
      ioRequest.maxRedirects = maxRedirects;
      ioRequest.followRedirects = followRedirects;

      request.headers.forEach((k, v) => ioRequest.headers.set(k, v));

      if (request.body != null) {
        ioRequest.headers.contentType = io.ContentType.json;
        ioRequest.write(request.body);
      }

      final ioResponse = await ioRequest.close().timeout(readTimeout);
      final responseBody = await ioResponse.transform(utf8.decoder).join();

      return ClientResponse(
        statusCode: ioResponse.statusCode,
        body: responseBody,
        headers: _extractHeaders(ioResponse.headers),
      );
    } on io.RedirectException catch (e) {
      throw HttpClientException('Too many redirects (${e.redirects.length})', request.uri);
    } on io.SocketException catch (e) {
      throw HttpClientException('Connection failed: ${e.message}', request.uri);
    }
  }

  void _throwIfError(ClientResponse response, Uri uri) {
    if (response.statusCode >= 500) {
      throw HttpClient5xxException(uri,
          statusCode: response.statusCode, body: response.body, headers: response.headers);
    }
    if (response.statusCode >= 400) {
      throw HttpClient4xxException(uri,
          statusCode: response.statusCode, body: response.body, headers: response.headers);
    }
  }

  Map<String, String> _extractHeaders(io.HttpHeaders headers) {
    final map = <String, String>{};
    headers.forEach((name, values) => map[name] = values.join(', '));
    return map;
  }

  String _jsonEncode(Object obj) => jsonEncode(obj);

  void close() => _client.close();
}

/// Response from an HTTP client call.
class ClientResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;

  ClientResponse({required this.statusCode, required this.body, required this.headers});

  Map<String, dynamic> get json => jsonDecode(body) as Map<String, dynamic>;
  List<dynamic> get jsonList => jsonDecode(body) as List<dynamic>;
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// Client filter chain implementation.
class _HttpClientFilterChain implements FilterChain {
  final List<HttpClientFilter> _filters;
  final Future<ClientResponse> Function(MutableRequest) _sender;
  int _index = 0;

  _HttpClientFilterChain(this._filters, this._sender);

  @override
  Future<Response> proceed(dynamic request) async {
    if (_index >= _filters.length) {
      final clientResponse = await _sender(request as MutableRequest);
      return Response(clientResponse.statusCode,
          headers: clientResponse.headers, body: clientResponse.body);
    }
    final filter = _filters[_index++];
    return filter.filter(request as MutableRequest, this);
  }
}
