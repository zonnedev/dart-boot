import 'dart:io';

/// Runs a command, streaming stdout/stderr to the terminal.
/// Returns the exit code.
Future<int> runProcess(
  String executable,
  List<String> args, {
  String? workingDir,
  bool silent = false,
}) async {
  final process = await Process.start(
    executable,
    args,
    workingDirectory: workingDir,
    mode: silent ? ProcessStartMode.normal : ProcessStartMode.inheritStdio,
  );
  return process.exitCode;
}

/// Find the project root (directory containing pubspec.yaml with boot dependency).
String findProjectRoot() {
  var dir = Directory.current;
  while (true) {
    final pubspec = File('${dir.path}/pubspec.yaml');
    if (pubspec.existsSync()) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      stderr.writeln('Error: No pubspec.yaml found. Are you in a Dart project?');
      exit(1);
    }
    dir = parent;
  }
}
