import 'dart:io';

import 'package:args/command_runner.dart';
import '../util.dart';

class CleanCommand extends Command<int> {
  @override
  String get name => 'clean';

  @override
  String get description => 'Remove generated files and build cache.';

  @override
  Future<int> run() async {
    final root = findProjectRoot();

    print('🧹 Cleaning...');

    // Remove .dart_tool/build
    final buildCache = Directory('$root/.dart_tool/build');
    if (buildCache.existsSync()) {
      buildCache.deleteSync(recursive: true);
      print('  Removed .dart_tool/build');
    }

    // Remove generated .g.dart files
    var count = 0;
    await for (final entity in Directory('$root/lib').list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.g.dart')) {
        entity.deleteSync();
        count++;
      }
    }
    if (count > 0) print('  Removed $count generated files');

    print('✓ Clean complete.');
    return 0;
  }
}
