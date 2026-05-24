import 'dart:io';

import 'package:args/command_runner.dart';

class RoutesCommand extends Command<int> {
  @override
  String get name => 'routes';

  @override
  String get description => 'List all registered HTTP routes.';

  @override
  Future<int> run() async {
    final contextFile = File('lib/src/generated/boot_context.g.dart');
    if (!contextFile.existsSync()) {
      stderr.writeln('Error: boot_context.g.dart not found. Run "boot build" first.');
      return 1;
    }

    final content = contextFile.readAsStringSync();
    final routes = <_RouteInfo>[];

    // Parse route entries from generated $Routes classes
    // Pattern: RouteEntry(method: 'GET', path: '/users/', handler: ...)
    final entryPattern = RegExp(
      r"RouteEntry\(\s*method:\s*'(\w+)',\s*path:\s*'([^']+)'"
    );

    // Find which controller each routes class belongs to
    // Pattern: $UserControllerRoutes(container.get<UserController>())
    final routeClassPattern = RegExp(
      r'\$(\w+)Routes\(container\.get<(\w+)>\(\)\)\.routes'
    );

    final controllers = <String, String>{};
    for (final match in routeClassPattern.allMatches(content)) {
      controllers[match.group(1)!] = match.group(2)!;
    }

    // Scan all .g.dart files for RouteEntry definitions
    final libDir = Directory('lib');
    await for (final entity in libDir.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.g.dart')) continue;
      final gContent = entity.readAsStringSync();

      // Find which class this routes file is for
      final classMatch = RegExp(r'class \$(\w+)Routes').firstMatch(gContent);
      if (classMatch == null) continue;
      final routesClassName = classMatch.group(1)!;
      final controllerName = controllers[routesClassName] ?? routesClassName;

      for (final match in entryPattern.allMatches(gContent)) {
        routes.add(_RouteInfo(
          method: match.group(1)!,
          path: match.group(2)!,
          controller: controllerName,
        ));
      }
    }

    if (routes.isEmpty) {
      print('No routes found.');
      return 0;
    }

    // Print formatted table
    print('🛣️  Boot Routes\n');
    final maxMethod = routes.fold<int>(0, (m, r) => r.method.length > m ? r.method.length : m);
    final maxPath = routes.fold<int>(0, (m, r) => r.path.length > m ? r.path.length : m);

    for (final route in routes) {
      final method = route.method.padRight(maxMethod + 1);
      final path = route.path.padRight(maxPath + 1);
      print('  $method $path → ${route.controller}');
    }

    print('\n${routes.length} route${routes.length != 1 ? 's' : ''} registered');
    return 0;
  }
}

class _RouteInfo {
  final String method;
  final String path;
  final String controller;
  _RouteInfo({required this.method, required this.path, required this.controller});
}
