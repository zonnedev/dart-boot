# boot_serialization

Serialization annotations for the Boot Framework.

## Features

- `@Serdeable()` — generates both `toJson()` and `$FromJson()`
- `@Serializable()` — generates `toJson()` only
- `@Deserializable()` — generates `$FromJson()` only

## Usage

```dart
@Serdeable()
class User {
  final String name;
  final int age;
  User({required this.name, required this.age});
}
// Generates: extension $UserSerialization on User { Map toJson() => ... }
// Generates: User $UserFromJson(Map json) => ...
```
