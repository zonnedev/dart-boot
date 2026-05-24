import 'package:boot_core/boot_core.dart';
import 'package:boot_security/boot_security.dart';
import 'package:boot_security_jwt/boot_security_jwt.dart';
import 'package:test/test.dart';

void main() {
  late JwtConfig config;

  setUp(() {
    config = JwtConfig('test-secret-key', '1h', '7d', 'test-app');
  });

  group('JwtConfig', () {
    test('parses duration strings', () {
      expect(config.expirationDuration, Duration(hours: 1));
      expect(config.refreshExpirationDuration, Duration(days: 7));
    });

    test('handles empty issuer as null', () {
      final c = JwtConfig('secret', '1h', '7d', '');
      expect(c.issuer, isNull);
    });

    test('parses various duration formats', () {
      expect(JwtConfig('s', '500ms', '1d', '').expirationDuration, Duration(milliseconds: 500));
      expect(JwtConfig('s', '30s', '1d', '').expirationDuration, Duration(seconds: 30));
      expect(JwtConfig('s', '15m', '1d', '').expirationDuration, Duration(minutes: 15));
      expect(JwtConfig('s', '2h', '1d', '').expirationDuration, Duration(hours: 2));
      expect(JwtConfig('s', '3d', '1d', '').expirationDuration, Duration(days: 3));
    });
  });

  group('JwtTokenGenerator', () {
    test('generates valid token', () {
      final gen = JwtTokenGenerator(config);
      final token = gen.generate('alice', roles: ['ROLE_USER']);
      expect(token, isNotEmpty);

      final validator = JwtTokenValidator(config);
      final claims = validator.validate(token)!;
      expect(claims['sub'], 'alice');
      expect(claims['roles'], ['ROLE_USER']);
      expect(claims['iss'], 'test-app');
    });

    test('includes custom claims', () {
      final gen = JwtTokenGenerator(config);
      final token = gen.generate('bob', claims: {'tenant': 'acme'});
      final claims = JwtTokenValidator(config).validate(token)!;
      expect(claims['tenant'], 'acme');
    });
  });

  group('JwtRefreshTokenGenerator', () {
    test('generates refresh token with type claim', () {
      final gen = JwtRefreshTokenGenerator(config);
      final token = gen.generate('alice');
      final claims = JwtTokenValidator(config).validate(token)!;
      expect(claims['sub'], 'alice');
      expect(claims['type'], 'refresh');
    });
  });

  group('JwtTokenValidator', () {
    test('validates correct token', () {
      final token = JwtTokenGenerator(config).generate('alice');
      expect(JwtTokenValidator(config).validate(token), isNotNull);
    });

    test('returns null for invalid token', () {
      expect(JwtTokenValidator(config).validate('garbage'), isNull);
    });

    test('returns null for wrong secret', () {
      final token = JwtTokenGenerator(config).generate('alice');
      final other = JwtTokenValidator(JwtConfig('wrong-secret', '1h', '7d', ''));
      expect(other.validate(token), isNull);
    });

    test('returns null for wrong issuer', () {
      final noIssuer = JwtConfig('test-secret-key', '1h', '7d', '');
      final token = JwtTokenGenerator(noIssuer).generate('alice');
      // Validator with issuer rejects token without matching issuer
      expect(JwtTokenValidator(config).validate(token), isNull);
    });

    test('returns null for expired token', () {
      final expired = JwtConfig('test-secret-key', '0s', '7d', '');
      final token = JwtTokenGenerator(expired).generate('alice');
      expect(JwtTokenValidator(expired).validate(token), isNull);
    });
  });

  group('JwtAuthenticationProvider', () {
    late JwtAuthenticationProvider provider;

    setUp(() {
      provider = JwtAuthenticationProvider(BearerTokenReader(), JwtTokenValidator(config));
    });

    test('authenticates valid Bearer token', () async {
      final token = JwtTokenGenerator(config).generate('alice', roles: ['ROLE_ADMIN']);
      final request = AuthenticationRequest(authorization: 'Bearer $token');
      final auth = await provider.authenticate(request);
      expect(auth, isNotNull);
      expect(auth!.name, 'alice');
      expect(auth.roles, ['ROLE_ADMIN']);
    });

    test('returns null for missing header', () async {
      expect(await provider.authenticate(AuthenticationRequest()), isNull);
    });

    test('returns null for invalid token', () async {
      final request = AuthenticationRequest(authorization: 'Bearer invalid');
      expect(await provider.authenticate(request), isNull);
    });

    test('returns null for non-Bearer', () async {
      final request = AuthenticationRequest(authorization: 'Basic abc');
      expect(await provider.authenticate(request), isNull);
    });
  });

  group('DefaultTokenReader', () {
    test('extends BearerTokenReader', () {
      final reader = DefaultTokenReader();
      expect(reader, isA<BearerTokenReader>());
      expect(reader, isA<TokenReader>());
      expect(reader.read(AuthenticationRequest(authorization: 'Bearer xyz')), 'xyz');
    });
  });

  group('DI integration', () {
    test('full wiring via container', () {
      final container = BeanContainer();
      container.register<JwtConfig>(_Def('JwtConfig', (_) => config));
      container.register<TokenReader>(_Def('DefaultTokenReader', (_) => DefaultTokenReader()));
      container.register<BearerTokenReader>(_Def('DefaultTokenReader', (_) => DefaultTokenReader()));
      container.register<TokenValidator>(_Def('JwtTokenValidator', (c) => JwtTokenValidator(c.get<JwtConfig>())));
      container.register<TokenGenerator>(_Def('JwtTokenGenerator', (c) => JwtTokenGenerator(c.get<JwtConfig>())));
      container.register<RefreshTokenGenerator>(_Def('JwtRefreshTokenGenerator', (c) => JwtRefreshTokenGenerator(c.get<JwtConfig>())));
      container.register<AuthenticationProvider>(_Def('JwtAuthenticationProvider', (c) =>
          JwtAuthenticationProvider(c.get<TokenReader>(), c.get<TokenValidator>())));

      final gen = container.get<TokenGenerator>();
      final token = gen.generate('test-user', roles: ['ROLE_USER']);
      final validator = container.get<TokenValidator>();
      expect(validator.validate(token)?['sub'], 'test-user');
    });

    test('bean registered under concrete superclass is resolvable', () {
      // Simulates what the generator does: DefaultTokenReader extends BearerTokenReader
      // should be resolvable as both TokenReader (interface) and BearerTokenReader (concrete super)
      final container = BeanContainer();
      final reader = DefaultTokenReader();
      container.register<TokenReader>(_Def('DefaultTokenReader', (_) => reader));
      container.register<BearerTokenReader>(_Def('DefaultTokenReader', (_) => reader));
      container.register<DefaultTokenReader>(_Def('DefaultTokenReader', (_) => reader));

      // Resolve by interface
      expect(container.get<TokenReader>(), isA<DefaultTokenReader>());
      // Resolve by concrete superclass
      expect(container.get<BearerTokenReader>(), isA<DefaultTokenReader>());
      // Resolve by concrete type
      expect(container.get<DefaultTokenReader>(), isA<DefaultTokenReader>());
    });
  });
}

class _Def extends BeanDefinition {
  @override
  final String typeName;
  final dynamic Function(BeanContainer) _factory;
  _Def(this.typeName, this._factory);
  @override
  dynamic create(BeanContainer container) => _factory(container);
}
