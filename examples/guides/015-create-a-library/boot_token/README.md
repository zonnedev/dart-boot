# boot_token

A Boot framework library.

## Usage

Add to your app's `pubspec.yaml`:

```yaml
dependencies:
  boot_token: ^0.1.0
```

Configure in `application.yml`:

```yaml
boot_token:
  enabled: true
```

## Development

```bash
dart pub get
dart run build_runner build --delete-conflicting-outputs
dart test
```

Commit all `.g.dart` files before publishing.
