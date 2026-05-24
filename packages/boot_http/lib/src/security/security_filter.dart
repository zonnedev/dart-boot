import 'package:boot_http_common/boot_http_common.dart';




import 'security.dart';

/// Internal security filter — intercepts requests and enforces @Secured rules.
/// Registered automatically when security is enabled.
class SecurityFilter implements HttpServerFilter {
  final List<AuthenticationProvider> _providers;
  final List<SecurityRuleEntry> _rules;
  final List<String> _defaultRules;

  SecurityFilter(this._providers, this._rules, {List<String>? defaultRules})
      : _defaultRules = defaultRules ?? [SecurityRule.isAnonymous];

  @override
  Future<Response> filter(Request request, FilterChain chain) async {
    // Find matching rule for this request
    final rule = _findRule(request.method, request.path);

    // Always attempt authentication (to populate request.authentication)
    final authRequest = AuthenticationRequest(
      authorization: request.headers['authorization'],
      headers: request.headers,
      path: request.path,
      method: request.method,
    );

    Authentication? authentication;
    for (final provider in _providers) {
      authentication = await provider.authenticate(authRequest);
      if (authentication != null) break;
    }

    if (authentication != null) {
      request.setAttribute('authentication', authentication);
    }

    // If anonymous access is allowed, proceed regardless
    if (rule.contains(SecurityRule.isAnonymous)) {
      return chain.proceed(request);
    }

    // If deny all, reject immediately
    if (rule.contains(SecurityRule.denyAll)) {
      return Response(403, headers: {'content-type': 'application/json'},
          body: '{"error":"Forbidden"}');
    }

    // No authentication and it's required
    if (authentication == null) {
      return Response(401, headers: {'content-type': 'application/json'},
          body: '{"error":"Unauthorized"}');
    }

    // Check roles if specified
    if (rule.isNotEmpty && !rule.contains(SecurityRule.isAuthenticated)) {
      final hasRole = rule.any((r) => authentication!.roles.contains(r));
      if (!hasRole) {
        return Response(403, headers: {'content-type': 'application/json'},
            body: '{"error":"Forbidden"}');
      }
    }

    return chain.proceed(request);
  }

  List<String> _findRule(String method, String path) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    for (final entry in _rules) {
      if (_pathMatches(entry.pattern, normalizedPath)) {
        if (entry.method == null || entry.method!.toUpperCase() == method.toUpperCase()) {
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
      return path.startsWith(prefix) && !path.substring(prefix.length + 1).contains('/');
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
