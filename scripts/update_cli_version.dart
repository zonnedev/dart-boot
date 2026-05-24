// ignore_for_file: avoid_print
import 'dart:io';
import 'package:yaml/yaml.dart';

/// Reads versions from pubspecs and writes them to version.dart.
void main() {
  final cliPubspec = File('packages/boot_cli/pubspec.yaml').readAsStringSync();
  final cliVersion = (loadYaml(cliPubspec) as YamlMap)['version'] as String;

  final bootPubspec = File('packages/boot/pubspec.yaml').readAsStringSync();
  final frameworkVersion = (loadYaml(bootPubspec) as YamlMap)['version'] as String;

  File('packages/boot_cli/lib/src/version.dart').writeAsStringSync(
    "/// CLI version. Updated by melos version.\n"
    "const String version = '$cliVersion';\n"
    "\n"
    "/// Framework packages version. Updated by melos version hook.\n"
    "const String frameworkVersion = '$frameworkVersion';\n",
  );

  Process.runSync('git', ['add', 'packages/boot_cli/lib/src/version.dart']);
  print('Updated boot_cli: version=$cliVersion, frameworkVersion=$frameworkVersion');
}
