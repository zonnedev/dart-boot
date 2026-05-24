import 'package:boot_http_common/boot_http_common.dart';

import 'authentication.dart';
import 'authentication_provider.dart';
import 'authentication_request.dart';
import 'secured.dart';

/// Internal security filter — intercepts requests and enforces access rules.
/// Checks both intercept-url-map (YAML) and @Secured annotations (route metadata).
class SecurityFilter implements HttpServerFilter {
  final List<AuthenticationProvider> _providers;
  final List<SecurityRuleEntry> _rules;
  final List<String> _defaultRules;

  SecurityFilter(this._providers, this._rules, {List<String>? defaultRules})
      : _defaultRules = defaultRules ?? [SecurityRule.isAnonymous];

  @override
  Future<Response> filter(Request request, FilterChain chain) async {
    final authRequest = AuthenticationRequest(
      authorization: request.headers['authorization'],
      headers: request.headers,
      path: request.path,
      method: request.method,
    );

    // Authenticate
    Authentication? authentication;
    for (final provider in _providers) {
      authentication = await provider.authenticate(authRequest);
      if (authentication != null) break;
    }

    if (authentication != null) {
      request.setAttribute('authentication', authentication);
    }

    // Check intercept-url-map rules
    final urlRule = _findRule(request.method, request.path);
    final urlResult = _enforce(urlRule, authentication);
    if (urlResult != null) return urlResult;

    // Check route-level @Secured metadata
    final metadata = request.getAttribute<List<Object>>('route.metadata');
    if (metadata != null) {
      for (final secured in metadata.whereType<Secured>()) {
        final metaResult = _enforce(secured.value, authentication);
        if (metaResult != null) return metaResult;
      }
    }

    return chain.proceed(request);
  }

  /// Enforce a set of access rules. Returns a rejection Response, or null if allowed.
  Response? _enforce(List<String> rules, Authentication? authentication) {
    if (rules.isEmpty) return null;

    if (rules.contains(SecurityRule.isAnonymous)) return null;

    if (rules.contains(SecurityRule.denyAll)) {
      return Response(403,
          headers: {'content-type': 'application/json'},
          body: '{"error":"Forbidden"}');
    }

    if (authentication == null) {
      return Response(401,
          headers: {'content-type': 'application/json'},
          body: '{"error":"Unauthorized"}');
    }

    if (rules.contains(SecurityRule.isAuthenticated)) return null;

    // Role check
    final hasRole = rules.any((r) => authentication.roles.contains(r));
    if (!hasRole) {
      return Response(403,
          headers: {'content-type': 'application/json'},
          body: '{"error":"Forbidden"}');
    }

    return null;
  }

  List<String> _findRule(String method, String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    for (final entry in _rules) {
      if (_pathMatches(entry.pattern, normalizedPath)) {
        if (entry.method == null ||
            entry.method!.toUpperCase() == method.toUpperCase()) {
          return entry.access;
        }
      }
    }
    return _defaultRules;
  }

  bool _pathMatches(String pattern, String path) {
    if (pattern == '/**') return true;
    if (pattern.endsWith('/**')) {
      final prefix = pattern.substring(0, pattern.length - 3);
      return path.startsWith(prefix);
    }
    if (pattern.endsWith('/*')) {
      final prefix = pattern.substring(0, pattern.length - 2);
      return path.startsWith(prefix) &&
          !path.substring(prefix.length + 1).contains('/');
    }
    return pattern == path;
  }
}

/// A security rule entry from YAML intercept-url-map or @Secured annotations.
class SecurityRuleEntry {
  final String pattern;
  final String? method;
  final List<String> access;

  SecurityRuleEntry({required this.pattern, this.method, required this.access});
}
