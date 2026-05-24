/// Represents an authenticated user.
class Authentication {
  final String name;
  final List<String> roles;
  final Map<String, dynamic> attributes;

  Authentication({required this.name, this.roles = const [], this.attributes = const {}});
}
