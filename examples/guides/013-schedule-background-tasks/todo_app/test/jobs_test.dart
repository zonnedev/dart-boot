import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/jobs/cleanup_job.dart';
import 'package:todo_app/src/jobs/production_jobs.dart';
import 'package:test/test.dart';

void main() {
  group('Scheduled Jobs', () {
    test('CleanupJob bean is registered', () async {
      await bootTest($configure, test: (client, container) async {
        final job = container.get<CleanupJob>();
        expect(job, isNotNull);
      });
    });

    test('cleanExpiredSessions runs without error', () async {
      await bootTest($configure, test: (client, container) async {
        final job = container.get<CleanupJob>();
        await job.cleanExpiredSessions();
        expect(job.cleanupCount, 1);
      });
    });

    test('ProductionJobs does not load in test env', () async {
      await bootTest($configure, test: (client, container) async {
        expect(container.container.has<ProductionJobs>(), isFalse);
      });
    });
  });
}
