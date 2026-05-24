import 'package:boot/boot.dart';
import 'package:postgres/postgres.dart';

part 'database.g.dart';

@Singleton()
@Requires(property: 'pg.host')
class Database {
  final String _host;
  final int _port;
  final String _database;
  final String _username;
  final String _password;
  late final Pool _pool;

  Database(
    @Value('\${pg.host}') this._host,
    @Value('\${pg.port:5432}') this._port,
    @Value('\${pg.database:postgres}') this._database,
    @Value('\${pg.username:postgres}') this._username,
    @Value('\${pg.password:postgres}') this._password,
  );

  @PostConstruct()
  void init() {
    _pool = Pool.withEndpoints(
      [Endpoint(host: _host, port: _port, database: _database, username: _username, password: _password)],
      settings: PoolSettings(maxConnectionCount: 10, sslMode: SslMode.disable),
    );
  }

  Future<Result> query(String sql, {Map<String, dynamic>? params}) =>
      _pool.execute(Sql.named(sql), parameters: params ?? {});

  Future<List<Map<String, dynamic>>> queryRows(String sql, {Map<String, dynamic>? params}) async {
    final result = await query(sql, params: params);
    return result.map((row) => row.toColumnMap()).toList();
  }

  @PreDestroy()
  void close() => _pool.close();
}
