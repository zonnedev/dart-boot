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
