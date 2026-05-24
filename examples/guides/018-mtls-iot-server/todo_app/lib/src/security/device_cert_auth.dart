import 'dart:io';
import 'package:boot/boot.dart';

part 'device_cert_auth.g.dart';

@Singleton()
@Order(0)
class DeviceCertAuth implements AuthenticationProvider {
  static final _log = Logger('DeviceCertAuth');

  @override
  Future<Authentication?> authenticate(AuthenticationRequest request) async {
    final certs = request.clientCertificates;
    if (certs == null || certs.isEmpty) return null;

    final cert = certs.first as X509Certificate;
    final cn = _extractCN(cert.subject);

    _log.info('Device authenticated', {'cn': cn});

    return Authentication(
      name: cn,
      roles: ['ROLE_DEVICE'],
      attributes: {'certSubject': cert.subject},
    );
  }

  String _extractCN(String subject) {
    final match = RegExp(r'CN=([^,]+)').firstMatch(subject);
    return match?.group(1) ?? subject;
  }
}
