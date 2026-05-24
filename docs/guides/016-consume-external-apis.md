# Guide 016: Consume External APIs

## What you'll build

A weather service that calls an external API, with error handling, timeouts, and a client filter that adds API keys automatically.

## What you'll learn

- How to use Boot's `HttpClient` to call external services
- How to add client filters (auth headers, logging)
- How to handle errors from external APIs
- How to configure timeouts
- How to test with mocked HTTP responses

## Prerequisites

- Completed [Guide 001](001-build-a-rest-api.md)

---

## Step 1: Create a service that calls an external API

**`lib/src/services/weather_service.dart`**

```dart
import 'dart:convert';
import 'package:boot/boot.dart';

part 'weather_service.g.dart';

@Singleton()
class WeatherService {
  final HttpClient _client;
  final String _apiKey;
  final String _baseUrl;

  WeatherService(
    this._client,
    @Value('\${weather.api-key}') this._apiKey,
    @Value('\${weather.base-url:https://api.openweathermap.org/data/2.5}') this._baseUrl,
  );

  /// Get current weather for a city.
  Future<Map<String, dynamic>> getWeather(String city) async {
    final response = await _client.get(
      '$_baseUrl/weather?q=$city&appid=$_apiKey&units=metric',
    );

    if (response.statusCode != 200) {
      throw HttpException(response.statusCode, 'Weather API error: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
```

**What's happening:**

- `HttpClient` is injected by Boot — it's a built-in bean
- `@Value` reads the API key and base URL from config
- The service makes a GET request and parses the JSON response
- If the external API returns an error, we throw an `HttpException`

---

## Step 2: Configure the API

**`application.yml`**:

```yaml
weather:
  api-key: your-api-key-here
  base-url: https://api.openweathermap.org/data/2.5
```

---

## Step 3: Create a controller

**`lib/src/controllers/weather_controller.dart`**

```dart
import 'package:boot/boot.dart';
import '../services/weather_service.dart';

part 'weather_controller.g.dart';

@Controller('/weather')
class WeatherController {
  final WeatherService _weather;
  WeatherController(this._weather);

  @Get('/<city>')
  Future<Response> getWeather(Request request, @PathParam() String city) async {
    final data = await _weather.getWeather(city);
    return Response.json({
      'city': city,
      'temperature': data['main']['temp'],
      'description': data['weather'][0]['description'],
    });
  }
}
```

---

## Step 4: Add a client filter for API key

Instead of passing the API key in every request URL, use a client filter:

**`lib/src/filters/api_key_client_filter.dart`**

```dart
import 'package:boot/boot.dart';

part 'api_key_client_filter.g.dart';

/// Automatically adds the API key to all outgoing requests to the weather API.
@Singleton()
@ClientFilter()
class ApiKeyClientFilter implements HttpClientFilter {
  final String _apiKey;

  ApiKeyClientFilter(@Value('\${weather.api-key}') this._apiKey);

  @override
  Future<ClientResponse> filter(MutableRequest request, ClientFilterChain chain) async {
    // Add API key as query parameter
    final uri = request.uri;
    final newUri = uri.replace(queryParameters: {
      ...uri.queryParameters,
      'appid': _apiKey,
    });
    request.uri = newUri;

    return chain.proceed(request);
  }
}
```

Now the service doesn't need to include `&appid=$_apiKey` — the filter adds it automatically.

---

## Step 5: Handle timeouts

Configure timeouts in `application.yml`:

```yaml
boot:
  http:
    services:
      weather:
        url: https://api.openweathermap.org/data/2.5
        connect-timeout: 5s
        read-timeout: 10s
```

Handle timeout errors in the service:

```dart
Future<Map<String, dynamic>> getWeather(String city) async {
  try {
    final response = await _client.get('$_baseUrl/weather?q=$city&units=metric');
    if (response.statusCode != 200) {
      throw HttpException(response.statusCode, 'Weather API error');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  } on TimeoutException {
    throw HttpException(503, 'Weather service is temporarily unavailable');
  }
}
```

---

## Step 6: Test with mocked responses

You don't want tests calling the real weather API. Mock the `HttpClient`:

**`test/weather_test.dart`**

```dart
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  group('WeatherController', () {
    test('returns weather for a city', () async {
      await bootTest($configure, properties: {
        'weather.api-key': 'test-key',
        'weather.base-url': 'https://api.openweathermap.org/data/2.5',
      }, overrides: (container) {
        container.override<HttpClient>(MockHttpClient());
      }, test: (client, container) async {
        final res = await client.get('/weather/London');
        res.expectStatus(200);
        expect(res.json()['city'], 'London');
        expect(res.json()['temperature'], isA<num>());
      });
    });
  });
}

/// A mock HTTP client that returns fake weather data.
class MockHttpClient implements HttpClient {
  @override
  Future<ClientResponse> get(String url, {Map<String, String>? headers}) async {
    return ClientResponse(
      statusCode: 200,
      body: '{"main":{"temp":15.5},"weather":[{"description":"cloudy"}]}',
      headers: {'content-type': 'application/json'},
    );
  }

  // Implement other methods as needed...
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
```

---

## Step 7: Error handling for external APIs

Create a dedicated exception handler:

```dart
@Singleton()
class ExternalApiErrorHandler implements ExceptionHandler<HttpException> {
  @override
  Response handle(Request request, HttpException e) {
    if (e.statusCode == 503) {
      return Response(503,
        headers: {'content-type': 'application/json', 'retry-after': '30'},
        body: '{"error": "${e.message}", "retry_after": 30}',
      );
    }
    return Response(e.statusCode,
      headers: {'content-type': 'application/json'},
      body: '{"error": "${e.message}"}',
    );
  }
}
```

---

## Step 8: Test manually

```bash
boot build
boot serve
```

```bash
curl http://localhost:8080/weather/London
```

Response:
```json
{"city": "London", "temperature": 15.5, "description": "cloudy"}
```

---

## What you've learned

- `HttpClient` is a built-in bean — inject it anywhere
- Client filters add headers/params to all outgoing requests
- `@Value` for API keys and base URLs
- Handle timeouts and error responses from external APIs
- Mock `HttpClient` in tests to avoid real API calls
- Configure timeouts in `application.yml`

## Next steps

- [Guide 017: Configure for Multiple Environments](017-configure-for-multiple-envs.md)
