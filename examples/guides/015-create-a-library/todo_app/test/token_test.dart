import 'package:boot_test/boot_test.dart';
import 'package:boot_token/boot_token.dart';
import 'package:boot_cache/boot_cache.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/services/redis_token_store.dart';
import 'package:test/test.dart';

void main() {
  group('Cross-library missingBeans resolution', () {
    test('redis.enabled=true → app RedisTokenStore wins over both libraries', () async {
      await bootTest($configure, properties: {
        'redis.enabled': 'true',
        'mongo.enabled': 'true',
      }, test: (client, container) async {
        final store = container.get<TokenStore>();
        expect(store, isA<RedisTokenStore>());
        expect(store.name, 'redis');
      });
    });

    test('mongo.enabled=true, redis=false → library 1 MongoTokenStore wins over library 2', () async {
      await bootTest($configure, properties: {
        'redis.enabled': 'false',
        'mongo.enabled': 'true',
      }, test: (client, container) async {
        final store = container.get<TokenStore>();
        expect(store, isA<MongoTokenStore>());
        expect(store.name, 'mongo');
      });
    });

    test('both disabled → library 2 InMemoryTokenStore is the last-resort default', () async {
      await bootTest($configure, properties: {
        'redis.enabled': 'false',
        'mongo.enabled': 'false',
      }, test: (client, container) async {
        final store = container.get<TokenStore>();
        expect(store, isA<InMemoryTokenStore>());
        expect(store.name, 'in-memory');
      });
    });
  });
}
