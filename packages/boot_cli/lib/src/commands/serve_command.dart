import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import '../util.dart';

class ServeCommand extends Command<int> {
  @override
  String get name => 'serve';

  @override
  String get description => 'Build and run the application.';

  ServeCommand() {
    argParser.addOption('port',
        abbr: 'p', help: 'Port to run on.', defaultsTo: '8080');
    argParser.addOption('entry',
        abbr: 'e', help: 'Entry point file.', defaultsTo: 'bin/main.dart');
    argParser.addFlag('watch',
        abbr: 'w', help: 'Rebuild and restart on changes.');
  }

  @override
  Future<int> run() async {
    final root = findProjectRoot();
    final entry = argResults!['entry'] as String;
    final watch = argResults!['watch'] as bool;

    print('⚡ Building...');
    final buildCode = await runProcess('dart', [
      'run', 'build_runner', 'build', '--delete-conflicting-outputs',
    ], workingDir: root);

    if (buildCode != 0) {
      stderr.writeln('❌ Build failed.');
      return buildCode;
    }

    if (watch) return _serveWithWatch(root, entry);

    print('🚀 Starting server...');
    return runProcess('dart', ['run', entry], workingDir: root);
  }

  Future<int> _serveWithWatch(String root, String entry) async {
    Process? serverProcess;
    var restartCount = 0;
    DateTime? buildStart;

    Future<void> stopServer() async {
      if (serverProcess != null) {
        serverProcess!.kill(ProcessSignal.sigterm);
        // Give it 2s to shut down gracefully
        await serverProcess!.exitCode.timeout(
          Duration(seconds: 2),
          onTimeout: () { serverProcess!.kill(ProcessSignal.sigkill); return -1; },
        );
        serverProcess = null;
      }
    }

    Future<void> startServer() async {
      await stopServer();
      if (restartCount > 0) {
        final elapsed = buildStart != null
            ? DateTime.now().difference(buildStart!).inMilliseconds
            : 0;
        print('\n┌─────────────────────────────────────');
        print('│ ♻️  Rebuilt in ${elapsed}ms — restarting...');
        print('└─────────────────────────────────────\n');
      } else {
        print('🚀 Starting server...');
      }
      restartCount++;
      serverProcess = await Process.start('dart', ['run', entry],
          workingDirectory: root, mode: ProcessStartMode.inheritStdio);
    }

    // Start build_runner in watch mode
    final buildProcess = await Process.start(
      'dart',
      ['run', 'build_runner', 'watch', '--delete-conflicting-outputs'],
      workingDirectory: root,
    );

    final completer = Completer<void>();
    buildProcess.stdout.listen((data) {
      final line = String.fromCharCodes(data);
      if (line.contains('Starting Build') || line.contains('Building new asset')) {
        buildStart = DateTime.now();
        if (restartCount > 0) print('🔨 Rebuilding...');
      } else if (line.contains('Succeeded') || line.contains('Built with')) {
        if (!completer.isCompleted) {
          completer.complete();
        } else {
          startServer();
        }
      } else if (line.contains('Failed')) {
        print('❌ Build failed — fix errors and save to retry');
      }
    });
    buildProcess.stderr.listen(stderr.add);

    // Watch application*.yml for config changes
    final yamlFiles = Directory(root).listSync()
        .whereType<File>()
        .where((f) => f.path.contains('application') && f.path.endsWith('.yml'));
    for (final yf in yamlFiles) {
      var lastMod = yf.lastModifiedSync();
      Stream.periodic(Duration(seconds: 1)).listen((_) {
        if (!yf.existsSync()) return;
        final mod = yf.lastModifiedSync();
        if (mod.isAfter(lastMod)) {
          lastMod = mod;
          print('\n📝 Config changed: ${yf.uri.pathSegments.last}');
          startServer();
        }
      });
    }

    // Handle ctrl+c
    ProcessSignal.sigint.watch().listen((_) async {
      print('\n⏹️  Shutting down...');
      await stopServer();
      buildProcess.kill();
      exit(0);
    });

    await completer.future;
    await startServer();

    final code = await buildProcess.exitCode;
    await stopServer();
    return code;
  }
}
