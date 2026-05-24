import 'package:boot/boot.dart';
import 'token_store.dart';

part 'in_memory_token_store.g.dart';

@Singleton()
@Requires(missingBeans: [TokenStore])
class InMemoryTokenStore implements TokenStore {
  final _store = <String, String>{};

  @override
  String get name => 'in-memory';

  @override
  String? getToken(String key) => _store[key];

  @override
  void setToken(String key, String value) => _store[key] = value;
}
