/// Minimal route registration interface used by library modules.
/// Implemented by BootRouter in boot_http.
// coverage:ignore-file
abstract class RouteRegistry {
  /// Register routes lazily — resolved during configureRuntime.
  void addAllLazy(covariant Function factory);
}
