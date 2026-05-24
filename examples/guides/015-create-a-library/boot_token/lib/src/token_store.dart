abstract class TokenStore {
  String get name;
  String? getToken(String key);
  void setToken(String key, String value);
}
