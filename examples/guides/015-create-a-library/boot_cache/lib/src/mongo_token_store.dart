import 'package:boot/boot.dart';
import 'package:boot_token/boot_token.dart';

part 'mongo_token_store.g.dart';

/// Mongo-backed token store. Only loads if mongo is enabled AND no other TokenStore exists.
@Singleton()
@Requires(property: 'mongo.enabled', value: 'true', missingBeans: [TokenStore])
class MongoTokenStore implements TokenStore {
  final _store = <String, String>{};

  @override
  String get name => 'mongo';

  @override
  String? getToken(String key) => _store[key];

  @override
  void setToken(String key, String value) => _store[key] = value;
}
