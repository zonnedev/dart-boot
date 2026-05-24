// ignore_for_file: avoid_print
import 'dart:io';
import 'package:yaml/yaml.dart';

/// Reads versions from pubspecs and writes them to version.dart.
void main() {
  final cliPubspec = File('packages/boot_cli/pubspec.yaml').readAsStringSync();
  final cliVersion = (loadYaml(cliPubspec) as YamlMap)['version'] as String;

  final bootPubspec = File('packages/boot/pubspec.yaml').readAsStringSync();
  final bootYaml = loadYaml(bootPubspec) as YamlMap;
  final frameworkVersion = bootYaml['version'] as String;

  final corePubspec = File('packages/boot_core/pubspec.yaml').readAsStringSync();
  final coreYaml = loadYaml(corePubspec) as YamlMap;
  final sdkConstraint = (coreYaml['environment'] as YamlMap)['sdk'] as String;
  final minSdk = sdkConstraint.replaceAll('^', '');

  File('packages/boot_cli/lib/src/version.dart').writeAsStringSync(
    "/// CLI version. Updated by melos version.\n"
    "const String version = '$cliVersion';\n"
    "\n"
    "/// Framework packages version. Updated by melos version hook.\n"
    "const String frameworkVersion = '$frameworkVersion';\n"
    "\n"
    "/// Minimum Dart SDK required by the framework. Updated by melos version hook.\n"
    "const String minSdk = '$minSdk';\n",
  );

  Process.runSync('git', ['add', 'packages/boot_cli/lib/src/version.dart']);
  print('Updated boot_cli: version=$cliVersion, frameworkVersion=$frameworkVersion, minSdk=$minSdk');
}
