# Guide 005: Use Dependency Injection

## What you'll build

A notification system with multiple implementations (email, SMS, push) that demonstrates Boot's DI features — interfaces, qualifiers, and bean replacement.

## What you'll learn

- How to use interfaces with multiple implementations
- How `@Named` selects a specific bean
- How `@Primary` sets a default
- How `@Replaces` overrides a bean (useful for testing and customization)
- How `getAll<T>()` collects all beans of a type

## Prerequisites

- Completed [Guide 001](001-build-a-rest-api.md)
- Understanding of what a bean is (a class managed by Boot)

---

## Step 1: Define an interface

An interface defines **what** something does, without saying **how**. Multiple classes can implement the same interface differently.

**`lib/src/services/notification_channel.dart`**

```dart
/// A channel that can send notifications.
/// Multiple implementations will exist (email, SMS, push).
abstract class NotificationChannel {
  String get name;
  Future<void> send(String recipient, String message);
}
```

**What's happening:** This is just an abstract class. It says "a notification channel has a name and can send messages" — but doesn't say how.

---

## Step 2: Create multiple implementations

**`lib/src/services/email_channel.dart`**

```dart
import 'package:boot/boot.dart';
import 'notification_channel.dart';

part 'email_channel.g.dart';

/// Sends notifications via email.
@Singleton()
@Primary()
class EmailChannel implements NotificationChannel {
  @override
  String get name => 'email';

  @override
  Future<void> send(String recipient, String message) async {
    print('📧 Sending email to $recipient: $message');
    // In a real app: call SMTP server
  }
}
```

**`lib/src/services/sms_channel.dart`**

```dart
import 'package:boot/boot.dart';
import 'notification_channel.dart';

part 'sms_channel.g.dart';

/// Sends notifications via SMS.
@Singleton()
@Named('sms')
class SmsChannel implements NotificationChannel {
  @override
  String get name => 'sms';

  @override
  Future<void> send(String recipient, String message) async {
    print('📱 Sending SMS to $recipient: $message');
    // In a real app: call Twilio API
  }
}
```

**`lib/src/services/push_channel.dart`**

```dart
import 'package:boot/boot.dart';
import 'notification_channel.dart';

part 'push_channel.g.dart';

/// Sends push notifications.
@Singleton()
@Named('push')
class PushChannel implements NotificationChannel {
  @override
  String get name => 'push';

  @override
  Future<void> send(String recipient, String message) async {
    print('🔔 Sending push to $recipient: $message');
    // In a real app: call Firebase/APNs
  }
}
```

**What's happening:**

- All three implement `NotificationChannel`
- Boot auto-detects `implements NotificationChannel` and registers each under that interface
- `@Primary()` on `EmailChannel` means: when someone asks for `NotificationChannel` without specifying which one, they get email
- `@Named('sms')` and `@Named('push')` let you ask for a specific one

---

## Step 3: Inject by interface

### Get the default (primary)

```dart
@Singleton()
class AlertService {
  final NotificationChannel _channel;

  /// Gets the @Primary channel (EmailChannel)
  AlertService(this._channel);

  Future<void> alert(String recipient, String message) async {
    await _channel.send(recipient, message);
  }
}
```

### Get a specific one by name

```dart
@Singleton()
class SmsVerificationService {
  final NotificationChannel _sms;

  /// Gets specifically the SMS channel
  SmsVerificationService(@Named('sms') this._sms);

  Future<void> sendCode(String phone, String code) async {
    await _sms.send(phone, 'Your code is: $code');
  }
}
```

### Get all of them

```dart
import 'package:boot/boot.dart';
import 'notification_channel.dart';

part 'notification_dispatcher.g.dart';

/// Sends a notification through ALL channels at once.
@Singleton()
class NotificationDispatcher {
  final BeanContainer _container;

  NotificationDispatcher(this._container);

  Future<void> broadcast(String recipient, String message) async {
    final channels = _container.getAll<NotificationChannel>();
    for (final channel in channels) {
      await channel.send(recipient, message);
    }
  }
}
```

**What's happening:**

- `AlertService(this._channel)` — no qualifier, gets `@Primary` (email)
- `SmsVerificationService(@Named('sms') this._sms)` — gets specifically SMS
- `_container.getAll<NotificationChannel>()` — gets ALL implementations as a list

---

## Step 4: Create a controller to demonstrate

**`lib/src/controllers/notification_controller.dart`**

```dart
import 'package:boot/boot.dart';
import '../services/notification_dispatcher.dart';
import '../services/sms_verification_service.dart';
import '../services/alert_service.dart';

part 'notification_controller.g.dart';

@Controller('/notifications')
class NotificationController {
  final AlertService _alerts;
  final SmsVerificationService _smsVerify;
  final NotificationDispatcher _dispatcher;

  NotificationController(this._alerts, this._smsVerify, this._dispatcher);

  /// Send via default channel (email, because it's @Primary)
  @Post('/alert')
  Future<Response> alert(Request request) async {
    final body = await request.json();
    await _alerts.alert(body['to'] as String, body['message'] as String);
    return Response.json({'sent_via': 'email'});
  }

  /// Send SMS verification code
  @Post('/verify')
  Future<Response> verify(Request request) async {
    final body = await request.json();
    await _smsVerify.sendCode(body['phone'] as String, '123456');
    return Response.json({'sent_via': 'sms'});
  }

  /// Broadcast to ALL channels
  @Post('/broadcast')
  Future<Response> broadcast(Request request) async {
    final body = await request.json();
    await _dispatcher.broadcast(body['to'] as String, body['message'] as String);
    return Response.json({'sent_via': 'all'});
  }
}
```

---

## Step 5: Export, build, and test

**`lib/todo_app.dart`** — add exports:

```dart
export 'src/services/notification_channel.dart';
export 'src/services/email_channel.dart';
export 'src/services/sms_channel.dart';
export 'src/services/push_channel.dart';
export 'src/services/alert_service.dart';
export 'src/services/sms_verification_service.dart';
export 'src/services/notification_dispatcher.dart';
export 'src/controllers/notification_controller.dart';
```

```bash
boot build
boot serve
```

**Test manually:**

```bash
curl -X POST http://localhost:8080/notifications/broadcast \
  -H "Content-Type: application/json" \
  -d '{"to": "user@example.com", "message": "Hello!"}'
```

Server output:
```
📧 Sending email to user@example.com: Hello!
📱 Sending SMS to user@example.com: Hello!
🔔 Sending push to user@example.com: Hello!
```

---

## Step 6: Write tests

**`test/notification_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/services/notification_channel.dart';
import 'package:todo_app/src/services/email_channel.dart';
import 'package:todo_app/src/services/sms_channel.dart';
import 'package:test/test.dart';

void main() {
  group('Dependency Injection', () {
    test('default NotificationChannel is EmailChannel (@Primary)', () async {
      await bootTest($configure, test: (client, container) async {
        final channel = container.get<NotificationChannel>();
        expect(channel, isA<EmailChannel>());
        expect(channel.name, 'email');
      });
    });

    test('@Named selects specific implementation', () async {
      await bootTest($configure, test: (client, container) async {
        final sms = container.getNamed<NotificationChannel>('sms');
        expect(sms, isA<SmsChannel>());
        expect(sms.name, 'sms');
      });
    });

    test('getAll returns all implementations', () async {
      await bootTest($configure, test: (client, container) async {
        final all = container.getAll<NotificationChannel>();
        expect(all.length, 3);
        expect(all.map((c) => c.name).toSet(), {'email', 'sms', 'push'});
      });
    });

    test('broadcast endpoint sends to all channels', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.post('/notifications/broadcast', body: {
          'to': 'test@test.com',
          'message': 'Test',
        });
        res.expectStatus(200);
        expect(res.json()['sent_via'], 'all');
      });
    });
  });
}
```

---

## Step 7: Replace a bean with @Replaces

Imagine you want to swap the email implementation in a specific deployment — maybe you use SendGrid instead of SMTP:

**`lib/src/services/sendgrid_channel.dart`**

```dart
import 'package:boot/boot.dart';
import 'notification_channel.dart';
import 'email_channel.dart';

part 'sendgrid_channel.g.dart';

/// Replaces EmailChannel with a SendGrid implementation.
@Singleton()
@Replaces(EmailChannel)
class SendGridChannel implements NotificationChannel {
  @override
  String get name => 'sendgrid';

  @override
  Future<void> send(String recipient, String message) async {
    print('📧 Sending via SendGrid to $recipient: $message');
  }
}
```

**What's happening:**

- `@Replaces(EmailChannel)` — removes `EmailChannel` from the container entirely and puts `SendGridChannel` in its place
- Since `EmailChannel` was `@Primary`, `SendGridChannel` now becomes the default `NotificationChannel`
- No other code changes needed — everything that injected `NotificationChannel` now gets SendGrid

**Test:**

```dart
test('@Replaces swaps the implementation', () async {
  await bootTest($configure, test: (client, container) async {
    final channel = container.get<NotificationChannel>();
    // If SendGridChannel is in the project, it replaces EmailChannel
    expect(channel.name, 'sendgrid');
  });
});
```

---

## Step 8: Override in tests only

You don't need `@Replaces` for testing — use `overrides`:

```dart
test('with mock notification channel', () async {
  final sent = <String>[];

  await bootTest($configure, overrides: (container) {
    container.override<NotificationChannel>(MockChannel(sent));
  }, test: (client, container) async {
    final res = await client.post('/notifications/alert', body: {
      'to': 'test@test.com',
      'message': 'Hello',
    });
    res.expectStatus(200);
    expect(sent, ['test@test.com: Hello']);
  });
});

class MockChannel implements NotificationChannel {
  final List<String> log;
  MockChannel(this.log);

  @override
  String get name => 'mock';

  @override
  Future<void> send(String recipient, String message) async {
    log.add('$recipient: $message');
  }
}
```

---

## Summary: When to use what

| Situation | Use |
|---|---|
| One implementation, one interface | Just `@Singleton()` — auto-registered under interface |
| Multiple implementations, one default | `@Primary()` on the default |
| Multiple implementations, inject specific | `@Named('x')` on the bean + `@Named('x')` on the parameter |
| Collect all implementations | `container.getAll<Interface>()` |
| Replace a bean permanently | `@Replaces(OriginalClass)` |
| Replace a bean in tests only | `overrides: (c) { c.override<Type>(mock) }` |

## What you've learned

- Interfaces let you swap implementations without changing consumers
- `@Primary` sets the default when multiple beans exist
- `@Named` selects a specific bean by name
- `getAll<T>()` collects all beans of a type
- `@Replaces` permanently swaps one bean for another
- Test overrides let you mock without changing production code
- Boot auto-detects `implements` — no manual `typed:` annotation needed

## Next steps

- [Guide 006: Write HTTP Filters](006-write-http-filters.md) — intercept requests for logging, auth, rate limiting
