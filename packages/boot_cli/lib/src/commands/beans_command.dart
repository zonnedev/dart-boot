import 'dart:io';

import 'package:args/command_runner.dart';

class BeansCommand extends Command<int> {
  @override
  String get name => 'beans';

  @override
  String get description => 'List all registered beans in the application.';

  @override
  Future<int> run() async {
    final contextFile = File('lib/src/generated/boot_context.g.dart');
    if (!contextFile.existsSync()) {
      stderr.writeln('Error: boot_context.g.dart not found. Run "boot build" first.');
      return 1;
    }

    final content = contextFile.readAsStringSync();
    final beans = <_BeanInfo>[];

    // Parse module calls
    final moduleCalls = RegExp(r'\$(\w+Module)\(container, router, config\);')
        .allMatches(content)
        .map((m) => m.group(1)!)
        .toList();

    // Parse bean registrations
    final registerPattern = RegExp(
      r'container\.register(?:Named|Primary|Prototype)?<(\w+)>\((\$\w+)\(\)\);'
    );
    for (final match in registerPattern.allMatches(content)) {
      final type = match.group(1)!;
      final definition = match.group(2)!;
      if (type == 'BeanContainer') continue;

      // Check if conditional
      final lineStart = content.lastIndexOf('\n', match.start);
      final preceding = content.substring(lineStart, match.start);
      String? condition;
      if (preceding.contains('if (')) {
        final condMatch = RegExp(r"config\.get\('([^']+)'\)").firstMatch(preceding);
        condition = condMatch?.group(1);
      }

      // Check if @Replaces
      String? replaces;
      if (definition != '\$${type}Definition') {
        // Definition name doesn't match type — likely a @Replaces
        final replacesMatch = RegExp(r'container\.register<(\w+)>\(' + RegExp.escape(definition))
            .firstMatch(content);
        if (replacesMatch != null && replacesMatch.group(1) != type) {
          replaces = replacesMatch.group(1);
        }
      }

      beans.add(_BeanInfo(
        type: type,
        definition: definition,
        condition: condition,
        replaces: replaces,
      ));
    }

    // Parse routes
    final routePattern = RegExp(r'\$(\w+)Routes\(container\.get<(\w+)>\(\)\)\.routes');
    final routes = <String, String>{};
    for (final match in routePattern.allMatches(content)) {
      routes[match.group(2)!] = match.group(1)!;
    }

    // Print output
    print('📦 Boot Beans\n');

    if (moduleCalls.isNotEmpty) {
      print('Libraries:');
      for (final module in moduleCalls) {
        print('  ⬡ $module');
      }
      print('');
    }

    print('Beans:');
    final maxType = beans.fold<int>(0, (max, b) => b.type.length > max ? b.type.length : max);
    for (final bean in beans) {
      final pad = bean.type.padRight(maxType + 2);
      final flags = <String>[];
      if (bean.condition != null) flags.add('@Requires(${bean.condition})');
      if (bean.replaces != null) flags.add('@Replaces(${bean.replaces})');
      if (routes.containsKey(bean.type)) flags.add('⇢ routes');
      final suffix = flags.isNotEmpty ? '  ${flags.join(', ')}' : '';
      print('  • $pad$suffix');
    }

    print('\n${beans.length} bean${beans.length != 1 ? 's' : ''} registered');
    if (moduleCalls.isNotEmpty) {
      print('${moduleCalls.length} library module${moduleCalls.length != 1 ? 's' : ''} loaded');
    }

    return 0;
  }
}

class _BeanInfo {
  final String type;
  final String definition;
  final String? condition;
  final String? replaces;

  _BeanInfo({
    required this.type,
    required this.definition,
    this.condition,
    this.replaces,
  });
}
