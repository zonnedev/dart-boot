/// Marks the application entry point class.
class BootApplication {
  /// Packages to scan for beans. If empty, auto-discovers all packages
  /// that ship a `boot_beans.json` manifest.
  final List<String> scan;

  const BootApplication({this.scan = const []});
}
