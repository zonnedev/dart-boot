import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

class DoctorCommand extends Command<int> {
  @override
  String get name => 'doctor';

  @override
  String get description => 'Diagnose common Boot project issues.';

  @override
  Future<int> run() async {
    print('🔍 Boot Doctor\n');
    var issues = 0;

    // Check pubspec.yaml exists
    final pubspec = File('pubspec.yaml');
    if (!pubspec.existsSync()) {
      _error('No pubspec.yaml found. Are you in a Dart project?');
      return 1;
    }
    _ok('pubspec.yaml found');

    final pubspecContent = pubspec.readAsStringSync();

    // Check boot dependency
    if (!pubspecContent.contains('boot:')) {
      _error('Missing "boot" dependency in pubspec.yaml');
      issues++;
    } else {
      _ok('boot dependency present');
    }

    // Check boot_generator dev dependency
    if (!pubspecContent.contains('boot_generator:')) {
      _error('Missing "boot_generator" dev dependency');
      issues++;
    } else {
      _ok('boot_generator dependency present');
    }

    // Check build_runner dev dependency
    if (!pubspecContent.contains('build_runner:')) {
      _error('Missing "build_runner" dev dependency');
      issues++;
    } else {
      _ok('build_runner dependency present');
    }

    // Check build.yaml
    final buildYaml = File('build.yaml');
    if (!buildYaml.existsSync()) {
      _warn('No build.yaml found (optional but recommended)');
    } else {
      _ok('build.yaml found');
    }

    // Check generated context file
    final packageName = _extractPackageName(pubspecContent);
    final contextFile = File('lib/src/generated/boot_context.g.dart');
    if (!contextFile.existsSync()) {
      _error('Missing lib/src/generated/boot_context.g.dart — run "boot build"');
      issues++;
    } else {
      _ok('boot_context.g.dart exists');

      // Check if stale
      final sourceDir = Directory('lib/src');
      if (sourceDir.existsSync()) {
        final contextMod = contextFile.lastModifiedSync();
        final staleFiles = <String>[];
        for (final entity in sourceDir.listSync(recursive: true)) {
          if (entity is File &&
              entity.path.endsWith('.dart') &&
              !entity.path.endsWith('.g.dart') &&
              entity.lastModifiedSync().isAfter(contextMod)) {
            staleFiles.add(p.relative(entity.path));
          }
        }
        if (staleFiles.isNotEmpty) {
          _warn('Generated code may be stale. Modified since last build:');
          for (final f in staleFiles.take(5)) {
            print('       - $f');
          }
          if (staleFiles.length > 5) {
            print('       ... and ${staleFiles.length - 5} more');
          }
        } else {
          _ok('Generated code is up to date');
        }
      }
    }

    // Check if this is a @BootLibrary
    if (packageName != null) {
      final barrelFile = File('lib/$packageName.dart');
      if (barrelFile.existsSync()) {
        final barrelContent = barrelFile.readAsStringSync();
        if (barrelContent.contains('@BootLibrary')) {
          _ok('This is a @BootLibrary package');

          // Check module file
          final moduleFile = File('lib/src/generated/boot_module.g.dart');
          if (!moduleFile.existsSync()) {
            _error('Missing boot_module.g.dart — run "boot build"');
            issues++;
          } else {
            _ok('boot_module.g.dart exists');
          }

          // Check module is exported
          if (!barrelContent.contains('boot_module.g.dart')) {
            _error('boot_module.g.dart is NOT exported from barrel file');
            _hint('Add: export \'src/generated/boot_module.g.dart\';');
            issues++;
          } else {
            _ok('boot_module.g.dart is exported from barrel');
          }
        }
      }
    }

    // Check for .g.dart files that should exist
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));

    var missingGDart = 0;
    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      if (content.contains("part '") && content.contains(".g.dart'")) {
        final gFile = File(file.path.replaceAll('.dart', '.g.dart'));
        if (!gFile.existsSync()) {
          missingGDart++;
          if (missingGDart <= 3) {
            _error('Missing ${p.relative(gFile.path)}');
          }
        }
      }
    }
    if (missingGDart > 3) {
      print('       ... and ${missingGDart - 3} more missing .g.dart files');
    }
    if (missingGDart > 0) {
      _hint('Run "boot build" to generate missing files');
      issues += missingGDart;
    } else if (missingGDart == 0) {
      _ok('All .g.dart files present');
    }

    // Summary
    print('');
    if (issues == 0) {
      print('✅ No issues found!');
    } else {
      print('⚠️  Found $issues issue${issues > 1 ? 's' : ''}. Run "boot build" to fix most.');
    }

    return issues > 0 ? 1 : 0;
  }

  String? _extractPackageName(String pubspec) {
    final match = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(pubspec);
    return match?.group(1);
  }

  void _ok(String msg) => print('  ✓ $msg');
  void _error(String msg) => print('  ✗ $msg');
  void _warn(String msg) => print('  ⚠ $msg');
  void _hint(String msg) => print('    → $msg');
}
