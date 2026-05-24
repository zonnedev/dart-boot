# Guide 018: mTLS IoT Server

## What you'll build

A server that authenticates IoT devices (like EV chargers) using client certificates over TLS. Devices connect via WebSocket with their certificate — no passwords, no tokens.

## What you'll learn

- What mTLS is and why it's used for IoT
- How to configure TLS with client certificate verification
- How to write an auth provider that validates certificates
- How HTTP and WebSocket both use the same auth flow
- How to test without real certificates

## Prerequisites

- Completed [Guide 003](003-add-authentication.md) (auth concepts)
- Completed [Guide 012](012-websocket-with-auth.md) (WebSocket auth)
- Basic understanding of TLS/certificates

---

## Step 1: What is mTLS?

Normal TLS (HTTPS): the server proves its identity to the client with a certificate. The client is anonymous.

**Mutual TLS (mTLS):** BOTH sides prove their identity. The server has a certificate, AND the client has a certificate. The server verifies the client's certificate before allowing the connection.

```
Normal TLS:   Client ←(server cert)← Server     (server proves identity)
mTLS:         Client →(client cert)→ Server     (BOTH prove identity)
              Client ←(server cert)← Server
```

Use mTLS when:
- IoT devices need to authenticate without passwords
- Service-to-service communication in a zero-trust network
- EV charger protocols (OCPP) require certificate-based auth
- You need stronger security than tokens

---

## Step 2: Generate certificates (for development)

Create a CA (Certificate Authority) and device certificates:

```bash
mkdir -p certs && cd certs

# 1. Create a CA (signs both server and device certs)
openssl req -x509 -newkey rsa:4096 -keyout ca-key.pem -out ca.pem -days 365 -nodes -subj "/CN=Boot CA"

# 2. Create server certificate (signed by CA)
openssl req -newkey rsa:4096 -keyout server-key.pem -out server-csr.pem -nodes -subj "/CN=localhost"
openssl x509 -req -in server-csr.pem -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server.pem -days 365

# 3. Create a device certificate (signed by same CA)
openssl req -newkey rsa:4096 -keyout device-key.pem -out device-csr.pem -nodes -subj "/CN=charger-001"
openssl x509 -req -in device-csr.pem -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out device.pem -days 365

cd ..
```

Now you have:
- `ca.pem` — the CA that both server and devices trust
- `server.pem` + `server-key.pem` — server's identity
- `device.pem` + `device-key.pem` — a device's identity (CN=charger-001)

---

## Step 3: Configure the server for mTLS

**`application.yml`**:

```yaml
boot:
  env: dev
  server:
    ssl:
      enabled: true
      cert: certs/server.pem
      key: certs/server-key.pem
      client-auth: required
      trust-store: certs/ca.pem
  websocket:
    enabled: true
    auth: true

server:
  port: 8443
```

**What each setting does:**

| Setting | Meaning |
|---|---|
| `ssl.enabled: true` | Enable TLS |
| `ssl.cert` | Server's certificate file |
| `ssl.key` | Server's private key |
| `ssl.client-auth: required` | Reject connections without a valid client cert |
| `ssl.trust-store` | CA certificate — only certs signed by this CA are accepted |

---

## Step 4: Write the certificate auth provider

**`lib/src/security/device_cert_auth.dart`**

```dart
import 'dart:io';
import 'package:boot/boot.dart';

part 'device_cert_auth.g.dart';

/// Authenticates devices by their client certificate CN (Common Name).
@Singleton()
@Order(0)  // highest priority — check certs before tokens
class DeviceCertAuth implements AuthenticationProvider {
  static final _log = Logger('DeviceCertAuth');

  @override
  Future<Authentication?> authenticate(AuthenticationRequest request) async {
    final certs = request.clientCertificates;
    if (certs == null || certs.isEmpty) return null;

    final cert = certs.first as X509Certificate;
    final cn = _extractCN(cert.subject);

    _log.info('Device authenticated', {'cn': cn, 'remote': request.remoteAddress});

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
```

**What's happening:**

- `request.clientCertificates` — Boot extracts the client cert from the TLS session
- We read the CN (Common Name) from the certificate subject — this identifies the device
- Returns `Authentication(name: 'charger-001', roles: ['device'])`
- `@Order(0)` — check certificates before any token-based auth

---

## Step 5: Create a device WebSocket endpoint

**`lib/src/websocket/device_socket.dart`**

```dart
import 'package:boot/boot.dart';

part 'device_socket.g.dart';

/// WebSocket endpoint for IoT devices.
/// Devices connect with their client certificate — no token needed.
@ServerWebSocket('/devices/<deviceId>')
class DeviceSocket {
  static final _log = Logger('DeviceSocket');

  @OnOpen()
  void onOpen(WebSocketSession session, String deviceId) {
    final auth = session.authentication;
    _log.info('Device connected', {
      'deviceId': deviceId,
      'certCN': auth.name,
      'roles': auth.roles,
    });

    // Verify the cert CN matches the requested device ID
    if (auth.name != deviceId) {
      _log.warn('Certificate CN does not match device ID', {
        'certCN': auth.name,
        'requestedId': deviceId,
      });
      session.send('{"error": "Certificate does not match device ID"}');
      session.close(4001, 'Certificate mismatch');
      return;
    }

    session.send('{"status": "connected", "device": "$deviceId"}');
  }

  @OnMessage()
  void onMessage(WebSocketSession session, String message, String deviceId) {
    _log.info('Message from $deviceId: $message');
    // Process device message (telemetry, status updates, etc.)
    session.send('{"ack": true}');
  }

  @OnClose()
  void onClose(WebSocketSession session, String deviceId) {
    _log.info('Device disconnected: $deviceId');
  }
}
```

**What's happening:**

- The device connects to `wss://server:8443/devices/charger-001`
- Boot validates the client certificate before upgrading
- `session.authentication.name` is the CN from the cert (e.g., "charger-001")
- We verify the cert CN matches the URL device ID — prevents a device from impersonating another

---

## Step 6: Also support HTTP endpoints for devices

The same auth provider works for regular HTTP too. Use `@Secured` to restrict endpoints to devices only:

```dart
@Controller('/api/devices')
@Secured(['ROLE_DEVICE'])  // only users with ROLE_DEVICE in their roles list
class DeviceApiController {
  @Post('/telemetry')
  Future<Response> telemetry(Request request, Authentication auth) async {
    final body = await request.json();
    return Response.json({'received': true, 'device': auth.name});
  }
}
```

This works because `DeviceCertAuth` returns `roles: ['ROLE_DEVICE']`:

```dart
return Authentication(
  name: cn,
  roles: ['ROLE_DEVICE'],  // ← this must match @Secured(['ROLE_DEVICE'])
);
```

If a web user with `roles: ['ROLE_ADMIN']` tries to access `/api/devices/telemetry`, they get 403 Forbidden — they're authenticated but don't have the `ROLE_DEVICE` role.

---

## Step 7: Test manually

**Connect as a device with its certificate:**

```bash
# WebSocket
websocat --tls-cert certs/device.pem --tls-key certs/device-key.pem \
  -k wss://localhost:8443/devices/charger-001

# HTTP
curl --cert certs/device.pem --key certs/device-key.pem \
  -k https://localhost:8443/api/devices/telemetry \
  -H "Content-Type: application/json" \
  -d '{"voltage": 230, "current": 32}'
```

**Try without a certificate:**

```bash
curl -k https://localhost:8443/api/devices/telemetry
# Connection refused or SSL handshake error (client-auth: required)
```

---

## Step 8: Write tests

**`test/mtls_test.dart`**

```dart
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
```

---

## Step 9: Production setup

In production, you'd use a real CA (not self-signed):

1. **Company CA** signs device certificates during manufacturing/provisioning
2. **Server certificate** from Let's Encrypt or your company CA
3. **Trust store** contains only your company CA — rejects all other certs
4. **Certificate revocation** — maintain a CRL or use short-lived certs

```yaml
# application-prod.yml
boot:
  server:
    ssl:
      enabled: true
      cert: /etc/ssl/server.pem
      key: /etc/ssl/server-key.pem
      client-auth: required
      trust-store: /etc/ssl/company-ca.pem
```

---

## What you've learned

- mTLS = both client and server prove identity with certificates
- `boot.server.ssl.client-auth: required` enforces client certificates
- `AuthenticationRequest.clientCertificates` carries the client cert
- Same `AuthenticationProvider` interface for tokens AND certificates
- WebSocket and HTTP use the same auth flow — no separate code
- Verify cert CN matches the requested resource (prevent impersonation)
- `@Order(0)` makes cert auth run before token auth

## Next steps

- [Guide 019: Deploy with Docker](019-deploy-with-docker.md)
