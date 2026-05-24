import 'dart:convert';
import 'package:boot/boot.dart';

part 'weather_service.g.dart';

@Singleton()
class WeatherService {
  final HttpClient _client;
  final String _baseUrl;

  WeatherService(
    this._client,
    @Value('\${weather.base-url:https://api.openweathermap.org/data/2.5}') this._baseUrl,
  );

  Future<Map<String, dynamic>> getWeather(String city) async {
    final response = await _client.send('GET', '$_baseUrl/weather?q=$city&units=metric');
    if (response.statusCode != 200) {
      throw BadRequestException('Weather API error: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
