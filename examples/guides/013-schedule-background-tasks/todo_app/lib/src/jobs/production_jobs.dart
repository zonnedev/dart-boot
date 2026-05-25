import 'package:boot/boot.dart';

part 'production_jobs.g.dart';

@Singleton()
@Requires(notEnv: ['test'])
class ProductionJobs {
  static final _log = Logger('ProductionJobs');

  @Scheduled(fixedRate: '1s')
  Future<void> compactDatabase() async {
    _log.info('Compacting database...');
  }
}
