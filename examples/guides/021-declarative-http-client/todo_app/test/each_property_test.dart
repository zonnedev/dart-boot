import 'dart:convert';
import 'dart:io';

import 'package:boot_test/boot_test.dart';
import 'package:boot_http_client/boot_http_client.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/clients/post_client.dart';
import 'package:test/test.dart';

void main() {
  group('@EachProperty integration', () {
    test('HttpClientServiceConfig resolved from YAML', () async {
      await bootTest($configure, test: (client, container) async {
        // The @EachProperty('boot.http.client.services') should have registered
        // a named HttpClientServiceConfig from application.yml
        final config = container.container.getNamed<HttpClientServiceConfig>('jsonplaceholder');
        expect(config.url, 'https://jsonplaceholder.typicode.com');
        expect(config.connectTimeout, Duration(seconds: 5)); // default
        expect(config.readTimeout, Duration(seconds: 30)); // default
      });
    });

    test('PostClient resolves via HttpClientServiceConfig from YAML', () async {
      // Start a mock server and override the config URL to point to it
      final mockServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final mockUrl = 'http://localhost:${mockServer.port}';
      mockServer.listen((req) async {
        if (req.method == 'GET' && req.uri.path == '/posts/') {
          req.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode([{'id': 1, 'title': 'From YAML config'}]));
        } else {
          req.response.statusCode = 404;
        }
        await req.response.close();
      });

      try {
        await bootTest($configure, properties: {
          'boot.http.client.services.jsonplaceholder.url': mockUrl,
        }, test: (client, container) async {
          final postClient = container.get<PostClient>();
          final posts = await postClient.list();
          expect(posts, hasLength(1));
          expect(posts[0]['title'], 'From YAML config');
        });
      } finally {
        await mockServer.close(force: true);
      }
    });
  });
}
