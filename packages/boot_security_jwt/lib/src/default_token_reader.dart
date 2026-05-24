import 'package:boot_core/boot_core.dart';
import 'package:boot_security/boot_security.dart';

part 'default_token_reader.g.dart';

/// Default [TokenReader] — reads tokens from the `Authorization: Bearer` header.
///
/// Override by providing your own `@Singleton() @Replaces(TokenReader)` class.
@Singleton()
class DefaultTokenReader extends BearerTokenReader {}
