/// Boot Framework — compile-time DI and HTTP framework for Dart.
///
/// This is the umbrella package that re-exports all Boot modules.
/// For library authors who only need DI, depend on `boot_core` instead.
library boot;

export 'package:boot_core/boot_core.dart';
export 'package:boot_aop/boot_aop.dart';
export 'package:boot_events/boot_events.dart';
export 'package:boot_scheduling/boot_scheduling.dart';
export 'package:boot_serialization/boot_serialization.dart';
export 'package:boot_http/boot_http.dart';
export 'package:boot_http_client/boot_http_client.dart';

// Boot.run entry point (depends on all modules)
export 'src/boot.dart';
export 'src/configure_runtime.dart';
