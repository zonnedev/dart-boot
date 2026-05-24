# boot_test

Testing utilities for the Boot Framework.

## Features

- `bootTest()` — in-memory HTTP testing without a real server
- `TestContainer` — bean access with get/getAll/getNamed/has/override
- `BootTestClient` — HTTP client with expectStatus, json, jsonList
- Overrides applied before configure (prevents @PostConstruct on fakes)
- Full configureRuntime (security, static files, WebSocket) in tests

## Usage

```dart
await bootTest($configure, test: (client, container) async {
  final res = await client.get('/hello/');
  res.expectStatus(200);
  expect(res.json()['message'], 'Hello!');
});
```
