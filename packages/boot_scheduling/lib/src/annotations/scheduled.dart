// coverage:ignore-file
import 'package:boot_core/boot_core.dart';

/// AnnotationType constant for runtime metadata queries.
const scheduledAnnotationType = AnnotationType(
    'package:boot_scheduling/src/annotations/scheduled.dart#Scheduled');

/// Schedules a method for periodic or delayed execution.
///
/// Exactly one of [fixedRate], [fixedDelay], or [cron] must be specified.
@MethodHook()
class Scheduled {
  /// Execute at a fixed rate (e.g., '5s', '1m', '500ms').
  final String? fixedRate;

  /// Execute with a fixed delay between completions (e.g., '10s').
  final String? fixedDelay;

  /// Cron expression (e.g., '0 */5 * * *' for every 5 minutes).
  final String? cron;

  /// Initial delay before first execution (e.g., '2s').
  final String? initialDelay;

  const Scheduled({this.fixedRate, this.fixedDelay, this.cron, this.initialDelay});
}
