import 'package:boot/boot.dart';
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/security/device_cert_auth.dart';
import 'package:test/test.dart';

void main() {
  group('mTLS Authentication', () {
    test('DeviceCertAuth provider is registered', () async {
      await bootTest($configure, test: (client, container) async {
        final providers = container.getAll<AuthenticationProvider>();
        expect(providers.any((p) => p is DeviceCertAuth), isTrue);
      });
    });

    test('DeviceCertAuth returns null without certificates', () async {
      await bootTest($configure, test: (client, container) async {
        final auth = container.get<DeviceCertAuth>();
        final result = await auth.authenticate(AuthenticationRequest(
          headers: {},
          clientCertificates: null,
        ));
        expect(result, isNull);
      });
    });
  });
}
