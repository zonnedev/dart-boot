/// JWT authentication module for the Boot Framework.
///
/// Add this package to your dependencies and configure via `application.yml`:
/// ```yaml
/// boot:
///   security:
///     jwt:
///       secret: my-secret-key
///       expiration: 1h
///       refresh-expiration: 7d
///       issuer: my-app
/// ```
///
/// All beans are auto-registered. Override any with `@Replaces`.
@BootLibrary()
library boot_security_jwt;

import 'package:boot_core/boot_core.dart';

export 'package:boot_security/boot_security.dart';

export 'src/jwt_config.dart';
export 'src/jwt_token_generator.dart';
export 'src/jwt_refresh_token_generator.dart';
export 'src/jwt_token_validator.dart';
export 'src/jwt_authentication_provider.dart';
export 'src/default_token_reader.dart';
export 'src/generated/boot_module.g.dart';
