import 'authentication_request.dart';
import 'token_reader.dart';

/// Default [TokenReader] that extracts tokens from the Authorization: Bearer header.
class BearerTokenReader implements TokenReader {
  @override
  String? read(AuthenticationRequest request) {
    final header = request.authorization;
    if (header == null || !header.startsWith('Bearer ')) return null;
    return header.substring(7);
  }
}
