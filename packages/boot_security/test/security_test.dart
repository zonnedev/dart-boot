import 'package:boot_core/boot_core.dart';
import 'package:boot_http_common/boot_http_common.dart';
import 'package:boot_security/boot_security.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

Request _req(String method, String path, [Map<String, String> headers = const {}]) {
  return Request(shelf.Request(method.toLowerCase(), Uri.parse('http://localhost$path'), headers: headers));
}

void main() {
  group('BearerTokenReader', () {
    final reader = BearerTokenReader();

    test('extracts token from Bearer header', () {
      final request = AuthenticationRequest(authorization: 'Bearer abc123');
      expect(reader.read(request), 'abc123');
    });

    test('returns null for missing header', () {
      expect(reader.read(AuthenticationRequest()), isNull);
    });

    test('returns null for non-Bearer scheme', () {
      final request = AuthenticationRequest(authorization: 'Basic abc123');
      expect(reader.read(request), isNull);
    });
  });

  group('SecurityFilter', () {
    late _FakeProvider provider;

    setUp(() {
      provider = _FakeProvider();
    });

    test('allows anonymous access', () async {
      final filter = SecurityFilter([provider], [
        SecurityRuleEntry(pattern: '/public/**', access: [SecurityRule.isAnonymous]),
      ]);
      final res = await filter.filter(_req('GET', '/public/hello'), _Chain());
      expect(res.statusCode, 200);
    });

    test('rejects unauthenticated on protected route', () async {
      provider.result = null;
      final filter = SecurityFilter([provider], [
        SecurityRuleEntry(pattern: '/**', access: [SecurityRule.isAuthenticated]),
      ]);
      final res = await filter.filter(_req('GET', '/secret'), _Chain());
      expect(res.statusCode, 401);
    });

    test('allows authenticated on protected route', () async {
      provider.result = Authentication(name: 'alice', roles: ['ROLE_USER']);
      final filter = SecurityFilter([provider], [
        SecurityRuleEntry(pattern: '/**', access: [SecurityRule.isAuthenticated]),
      ]);
      final res = await filter.filter(_req('GET', '/secret', {'authorization': 'Bearer x'}), _Chain());
      expect(res.statusCode, 200);
    });

    test('rejects wrong role', () async {
      provider.result = Authentication(name: 'alice', roles: ['ROLE_USER']);
      final filter = SecurityFilter([provider], [
        SecurityRuleEntry(pattern: '/admin/**', access: ['ROLE_ADMIN']),
      ]);
      final res = await filter.filter(_req('GET', '/admin/dash', {'authorization': 'Bearer x'}), _Chain());
      expect(res.statusCode, 403);
    });

    test('allows correct role', () async {
      provider.result = Authentication(name: 'alice', roles: ['ROLE_ADMIN']);
      final filter = SecurityFilter([provider], [
        SecurityRuleEntry(pattern: '/admin/**', access: ['ROLE_ADMIN']),
      ]);
      final res = await filter.filter(_req('GET', '/admin/dash', {'authorization': 'Bearer x'}), _Chain());
      expect(res.statusCode, 200);
    });

    test('denyAll rejects everyone', () async {
      provider.result = Authentication(name: 'alice', roles: ['ROLE_ADMIN']);
      final filter = SecurityFilter([provider], [
        SecurityRuleEntry(pattern: '/locked/**', access: [SecurityRule.denyAll]),
      ]);
      final res = await filter.filter(_req('GET', '/locked/x', {'authorization': 'Bearer x'}), _Chain());
      expect(res.statusCode, 403);
    });

    test('default rules apply when no pattern matches', () async {
      provider.result = null;
      final filter = SecurityFilter([provider], [], defaultRules: [SecurityRule.isAuthenticated]);
      final res = await filter.filter(_req('GET', '/anything'), _Chain());
      expect(res.statusCode, 401);
    });

    test('tries multiple providers in order', () async {
      final p1 = _FakeProvider()..result = null;
      final p2 = _FakeProvider()..result = Authentication(name: 'bob');
      final filter = SecurityFilter([p1, p2], [
        SecurityRuleEntry(pattern: '/**', access: [SecurityRule.isAuthenticated]),
      ]);
      final res = await filter.filter(_req('GET', '/test', {'authorization': 'Bearer x'}), _Chain());
      expect(res.statusCode, 200);
    });
  });

  group('Authentication', () {
    test('defaults', () {
      final auth = Authentication(name: 'alice');
      expect(auth.roles, isEmpty);
      expect(auth.attributes, isEmpty);
    });

    test('carries roles and attributes', () {
      final auth = Authentication(name: 'bob', roles: ['ROLE_ADMIN'], attributes: {'tenant': 'acme'});
      expect(auth.name, 'bob');
      expect(auth.roles, ['ROLE_ADMIN']);
      expect(auth.attributes['tenant'], 'acme');
    });
  });

  group('SecurityRule', () {
    test('constants', () {
      expect(SecurityRule.isAuthenticated, 'isAuthenticated()');
      expect(SecurityRule.isAnonymous, 'isAnonymous()');
      expect(SecurityRule.denyAll, 'denyAll()');
    });
  });

  group('DI integration', () {
    test('registers TokenReader via container', () {
      final container = BeanContainer();
      container.register<TokenReader>(_Def('BearerTokenReader', (_) => BearerTokenReader()));

      final reader = container.get<TokenReader>();
      expect(reader, isA<BearerTokenReader>());
      expect(reader.read(AuthenticationRequest(authorization: 'Bearer tok')), 'tok');
    });
  });
}

class _FakeProvider implements AuthenticationProvider {
  Authentication? result;

  @override
  Future<Authentication?> authenticate(AuthenticationRequest request) async => result;
}

class _Chain implements FilterChain {
  @override
  Future<Response> proceed(Request request) async => Response(200, body: 'ok');
}

class _Def extends BeanDefinition {
  @override
  final String typeName;
  final dynamic Function(BeanContainer) _factory;
  _Def(this.typeName, this._factory);
  @override
  dynamic create(BeanContainer container) => _factory(container);
}
