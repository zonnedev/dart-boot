# Serialization

Compile-time JSON serialization — no runtime reflection, no manual `toJson`/`fromJson`.

## @Serializable — JSON Output

```dart
import 'package:boot/boot.dart';
part 'user_response.g.dart';

@Serializable()
class UserResponse {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  UserResponse({required this.id, required this.name, required this.email, required this.createdAt});
}
```

The generator produces a `toJson()` extension method. Use it in controllers:

```dart
@Get('/<id>')
Future<UserResponse> getUser(Request req, @PathParam() String id) async {
  final user = await _repo.findById(id);
  return UserResponse(id: user.id, name: user.name, email: user.email, createdAt: user.createdAt);
  // Automatically serialized to JSON
}
```

**Test:**
```dart
test('returns serialized user', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/users/1');
    res.expectStatus(200);
    expect(res.json()['id'], '1');
    expect(res.json()['name'], isA<String>());
    expect(res.json()['email'], contains('@'));
    expect(res.headers['content-type'], contains('application/json'));
  });
});
```

## @Deserializable — JSON Input

```dart
@Deserializable()
class CreateUserRequest {
  final String name;
  final String email;

  CreateUserRequest({required this.name, required this.email});
}
```

The generator produces a `fromJson()` factory. Use with `@Body()`:

```dart
@Post('/')
Future<Response> create(Request req, @Body() CreateUserRequest body) async {
  // body is already deserialized from JSON
  final user = await _repo.save(body.name, body.email);
  return Response.created(user.toJson());
}
```

**Test:**
```dart
test('deserializes request body', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.post('/users/', body: {
      'name': 'Alice',
      'email': 'alice@test.com',
    });
    res.expectStatus(201);
    expect(res.json()['name'], 'Alice');
  });
});
```

## @Serdeable — Both Directions

```dart
@Serdeable()  // generates both toJson() and fromJson()
class Product {
  final String id;
  final String name;
  final double price;
  final bool inStock;

  Product({required this.id, required this.name, required this.price, required this.inStock});
}
```

**Test:**
```dart
test('Serdeable works both ways', () async {
  await bootTest($configure, test: (client, container) async {
    // Create (fromJson)
    final createRes = await client.post('/products/', body: {
      'name': 'Widget',
      'price': 9.99,
      'inStock': true,
    });
    createRes.expectStatus(201);
    final id = createRes.json()['id'];

    // Read (toJson)
    final getRes = await client.get('/products/$id');
    getRes.expectStatus(200);
    expect(getRes.json()['name'], 'Widget');
    expect(getRes.json()['price'], 9.99);
  });
});
```

## Controller Integration

Classes with `@Serializable()` can be returned directly from controllers — no `Response.json()` wrapper needed:

```dart
@Get('/stats')
Future<DashboardStats> stats(Request req) async {
  return DashboardStats(users: 1000, orders: 5000, revenue: 49999.99);
}
```

The controller generator sees `@Serializable()` on the return type and generates `result.toJson()` automatically.

## Nested Objects

```dart
@Serdeable()
class Order {
  final String id;
  final Customer customer;
  final List<LineItem> items;
  final double total;

  Order({required this.id, required this.customer, required this.items, required this.total});
}

@Serdeable()
class Customer {
  final String name;
  final String email;
  Customer({required this.name, required this.email});
}

@Serdeable()
class LineItem {
  final String product;
  final int quantity;
  final double price;
  LineItem({required this.product, required this.quantity, required this.price});
}
```

**Test:**
```dart
test('nested serialization', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.get('/orders/1');
    res.expectStatus(200);
    expect(res.json()['customer']['name'], isA<String>());
    expect(res.json()['items'], isList);
    expect(res.json()['items'][0]['product'], isA<String>());
  });
});
```

## Optional Fields

```dart
@Serdeable()
class UpdateUserRequest {
  final String? name;     // omitted from JSON if null
  final String? email;
  final String? avatar;

  UpdateUserRequest({this.name, this.email, this.avatar});
}
```

**Test:**
```dart
test('partial update with optional fields', () async {
  await bootTest($configure, test: (client, container) async {
    final res = await client.patch('/users/1', body: {
      'name': 'New Name',
      // email and avatar not sent — will be null
    });
    res.expectStatus(200);
  });
});
```

## Summary

| Annotation | Generates | Use for |
|---|---|---|
| `@Serializable()` | `toJson()` | Response bodies |
| `@Deserializable()` | `fromJson()` | Request bodies (`@Body`) |
| `@Serdeable()` | Both | DTOs used in both directions |
