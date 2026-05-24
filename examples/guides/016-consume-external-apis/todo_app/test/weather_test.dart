import 'package:boot/boot.dart';
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

class MockHttpClient extends HttpClient {
  @override
  Future<ClientResponse> send(String method, String url, {Map<String, String>? headers, Object? body}) async {
    return ClientResponse(
      statusCode: 200,
      body: '{"main":{"temp":15.5},"weather":[{"description":"cloudy"}]}',
      headers: {'content-type': 'application/json'},
    );
  }
}

void main() {
  group('WeatherController', () {
    test('returns weather for a city', () async {
      await bootTest($configure, properties: {
        'weather.base-url': 'http://fake',
      }, overrides: (container) {
        container.override<HttpClient>(MockHttpClient());
      }, test: (client, container) async {
        final res = await client.get('/weather/London');
        res.expectStatus(200);
        expect(res.json()['city'], 'London');
        expect(res.json()['temperature'], 15.5);
        expect(res.json()['description'], 'cloudy');
      });
    });
  });
}
