import 'package:boot/boot.dart';
import 'package:boot_token/boot_token.dart';

part 'redis_token_store.g.dart';

@Singleton()
@Requires(property: 'redis.enabled', value: 'true')
class RedisTokenStore implements TokenStore {
  final _store = <String, String>{};

  @override
  String get name => 'redis';

  @override
  String? getToken(String key) => _store[key];

  @override
  void setToken(String key, String value) => _store[key] = value;
}
