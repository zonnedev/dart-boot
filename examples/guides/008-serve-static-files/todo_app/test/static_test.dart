import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('Static files', () {
    test('serves index.html at /static/', () async {
      await bootTest($configure, properties: {
        'boot.static.enabled': 'true',
        'boot.static.path': '/static',
        'boot.static.directory': 'public',
        'boot.static.index': 'index.html',
      }, test: (client, container) async {
        final res = await client.get('/static/');
        res.expectStatus(200);
        expect(res.headers['content-type'], contains('text/html'));
        expect(res.body, contains('<title>Todo App</title>'));
      });
    });

    test('serves CSS with correct content-type', () async {
      await bootTest($configure, properties: {
        'boot.static.enabled': 'true',
        'boot.static.path': '/static',
        'boot.static.directory': 'public',
      }, test: (client, container) async {
        final res = await client.get('/static/css/style.css');
        res.expectStatus(200);
        expect(res.headers['content-type'], contains('text/css'));
        expect(res.body, contains('font-family'));
      });
    });

    test('returns 404 for missing files', () async {
      await bootTest($configure, properties: {
        'boot.static.enabled': 'true',
        'boot.static.path': '/static',
        'boot.static.directory': 'public',
      }, test: (client, container) async {
        final res = await client.get('/static/nonexistent.txt');
        res.expectStatus(404);
      });
    });

    test('path traversal is blocked', () async {
      await bootTest($configure, properties: {
        'boot.static.enabled': 'true',
        'boot.static.path': '/static',
        'boot.static.directory': 'public',
      }, test: (client, container) async {
        final res = await client.get('/static/../../pubspec.yaml');
        res.expectStatus(404);
      });
    });
  });
}
