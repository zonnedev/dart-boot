import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:boot_cli/src/commands/beans_command.dart';
import 'package:boot_cli/src/commands/build_command.dart';
import 'package:boot_cli/src/commands/clean_command.dart';
import 'package:boot_cli/src/commands/create_command.dart';
import 'package:boot_cli/src/commands/doctor_command.dart';
import 'package:boot_cli/src/commands/routes_command.dart';
import 'package:boot_cli/src/commands/serve_command.dart';
import 'package:boot_cli/src/commands/test_command.dart';

void main(List<String> args) async {
  final runner = CommandRunner<int>('boot', 'Boot framework CLI')
    ..addCommand(BuildCommand())
    ..addCommand(ServeCommand())
    ..addCommand(CreateCommand())
    ..addCommand(TestCommand())
    ..addCommand(CleanCommand())
    ..addCommand(DoctorCommand())
    ..addCommand(BeansCommand())
    ..addCommand(RoutesCommand());

  try {
    final code = await runner.run(args) ?? 0;
    exit(code);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exit(64);
  }
}
