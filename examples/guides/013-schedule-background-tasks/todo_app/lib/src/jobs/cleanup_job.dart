import 'package:boot/boot.dart';

part 'cleanup_job.g.dart';

@Singleton()
class CleanupJob {
  static final _log = Logger('CleanupJob');
  var cleanupCount = 0;

  @Scheduled(fixedRate: '5m')
  Future<void> cleanExpiredSessions() async {
    _log.info('Cleaning expired sessions...');
    cleanupCount++;
  }

  @Scheduled(fixedRate: '30s')
  void checkExternalServices() {
    _log.debug('Health check: all services OK');
  }
}
