// coverage:ignore-file
/// Constants for @Secured annotation values.
class SecurityRule {
  static const String isAuthenticated = 'isAuthenticated()';
  static const String isAnonymous = 'isAnonymous()';
  static const String denyAll = 'denyAll()';

  SecurityRule._();
}

/// Marks a controller or method with access rules.
///
/// ```dart
/// @Controller('/admin')
/// @Secured([SecurityRule.isAuthenticated])
/// class AdminController { ... }
///
/// @Get('/manage')
/// @Secured(['ROLE_ADMIN'])
/// Future<Response> adminOnly(Request req) async { ... }
/// ```
class Secured {
  final List<String> value;
  const Secured(this.value);
}
