import 'dart:io';

import 'package:yaml/yaml.dart';

/// Runtime configuration source.
///
/// Resolution priority (highest first):
/// 1. CLI arguments (--key=value or --key value)
/// 2. Programmatic properties passed to Boot.run()
/// 3. Environment variables (app.db.name → APP_DB_NAME)
/// 4. application-{env}.yml
/// 5. application.yml
class BootConfig {
  final Map<String, String> _yamlProperties = {};
  final Map<String, String> _programmatic = {};
  final Map<String, String> _cliArgs = {};
  final String? activeEnv;

  BootConfig({
    Map<String, String>? properties,
    this.activeEnv,
    List<String>? args,
  }) {
    // Load base YAML
    _loadYaml('application.yml');

    // Load environment-specific YAML (overrides base)
    final env = activeEnv ?? Platform.environment['BOOT_ENV'];
    if (env != null && env.isNotEmpty) {
      _loadYaml('application-$env.yml');
      _yamlProperties['boot.env'] = env;
    }

    // Programmatic properties
    if (properties != null) _programmatic.addAll(properties);

    // Parse CLI args
    if (args != null) _parseCli(args);
  }

  void addAll(Map<String, String> props) => _programmatic.addAll(props);

  /// Resolve a property value.
  /// Priority: CLI > programmatic > env vars > YAML.
  String? get(String key) {
    // 1. CLI args (highest)
    if (_cliArgs.containsKey(key)) return _cliArgs[key];

    // 2. Programmatic
    if (_programmatic.containsKey(key)) return _programmatic[key];

    // 3. Environment variable: app.db-name → APP_DB_NAME
    final envKey = key.replaceAll('.', '_').replaceAll('-', '_').toUpperCase();
    final envValue = Platform.environment[envKey];
    if (envValue != null) return envValue;

    // 4. YAML (lowest)
    return _yamlProperties[key];
  }

  /// Get a list of values for a key (from YAML list stored as indexed keys).
  /// e.g. key "logging.stacktrace.exclude" reads "logging.stacktrace.exclude[0]", "[1]", etc.
  List<String>? getList(String key) {
    final results = <String>[];
    for (var i = 0; i < 100; i++) {
      final value = get('$key[$i]');
      if (value == null) break;
      results.add(value);
    }
    if (results.isNotEmpty) return results;
    // Fallback: try comma-separated single value
    final single = get(key);
    if (single != null) return single.split(',').map((s) => s.trim()).toList();
    return null;
  }

  /// Get all distinct sub-keys under a prefix.
  /// For prefix "datasources", if keys are "datasources.primary.url" and
  /// "datasources.analytics.url", returns ["primary", "analytics"].
  List<String> getSubKeys(String prefix) {
    final dotPrefix = '$prefix.';
    final keys = <String>{};
    for (final key in _yamlProperties.keys) {
      if (key.startsWith(dotPrefix)) {
        final rest = key.substring(dotPrefix.length);
        final subKey = rest.split('.').first;
        keys.add(subKey);
      }
    }
    return keys.toList();
  }

  /// Get all properties under a specific prefix as a flat map.
  /// For prefix "datasources.primary", returns {"url": "...", "port": "..."}.
  Map<String, String> getProperties(String prefix) {
    final dotPrefix = '$prefix.';
    final result = <String, String>{};
    for (final key in _yamlProperties.keys) {
      if (key.startsWith(dotPrefix)) {
        final shortKey = key.substring(dotPrefix.length);
        result[shortKey] = get(key) ?? _yamlProperties[key]!;
      }
    }
    return result;
  }

  /// Resolve a placeholder string like "${server.port:8080}".
  String resolvePlaceholder(String placeholder) {
    final match = _placeholderRegex.firstMatch(placeholder);
    if (match == null) return placeholder;

    final key = match.group(1)!;
    final defaultValue = match.group(3);
    return get(key) ?? defaultValue ?? '';
  }

  static bool isPlaceholder(String value) => _placeholderRegex.hasMatch(value);
  static final _placeholderRegex = RegExp(r'^\$\{([^:}]+)(:([^}]*))?\}$');

  void _loadYaml(String filename) {
    final file = File(filename);
    if (!file.existsSync()) return;

    final content = file.readAsStringSync();
    final yaml = loadYaml(content);
    if (yaml is YamlMap) _flattenYaml(yaml, '');
  }

  void _flattenYaml(YamlMap map, String prefix) {
    for (final entry in map.entries) {
      final key = prefix.isEmpty ? '${entry.key}' : '$prefix.${entry.key}';
      final value = entry.value;
      if (value is YamlMap) {
        _flattenYaml(value, key);
      } else if (value is YamlList) {
        for (var i = 0; i < value.length; i++) {
          final item = value[i];
          if (item is YamlMap) {
            _flattenYaml(item, '$key[$i]');
          } else {
            _yamlProperties['$key[$i]'] = item.toString();
          }
        }
      } else if (value != null) {
        _yamlProperties[key] = value.toString();
      }
    }
  }

  /// Parse CLI args: --server.port=9090 or --server.port 9090
  void _parseCli(List<String> args) {
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (!arg.startsWith('--')) continue;

      final withoutDashes = arg.substring(2);
      if (withoutDashes.contains('=')) {
        final parts = withoutDashes.split('=');
        _cliArgs[parts[0]] = parts.sublist(1).join('=');
      } else if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
        _cliArgs[withoutDashes] = args[++i];
      } else {
        _cliArgs[withoutDashes] = 'true';
      }
    }
  }
}
