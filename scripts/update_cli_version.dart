// ignore_for_file: avoid_print
import 'dart:io';
import 'package:yaml/yaml.dart';

/// Reads boot_cli's pubspec.yaml version and writes it to version.dart.
void main() {
  final pubspec = File('packages/boot_cli/pubspec.yaml').readAsStringSync();
  final yaml = loadYaml(pubspec) as YamlMap;
  final version = yaml['version'] as String;

  File('packages/boot_cli/lib/src/version.dart').writeAsStringSync(
    "/// Package version. Updated by melos version.\nconst String version = '$version';\n",
  );

  // Stage the updated file
  Process.runSync('git', ['add', 'packages/boot_cli/lib/src/version.dart']);
  print('Updated boot_cli version.dart to $version');
}
