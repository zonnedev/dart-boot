import 'package:boot/boot.dart';
import 'package:boot_http_client/boot_http_client.dart';

part 'post_client.g.dart';

/// Declarative HTTP client for JSONPlaceholder /posts API.
@Client(name: 'jsonplaceholder', path: '/posts')
abstract class PostClient {
  @Get('/')
  Future<List<Map<String, dynamic>>> list();

  @Get('/<id>')
  Future<Map<String, dynamic>> getById(@PathParam() String id);

  @Post('/')
  Future<Map<String, dynamic>> create(@Body() Map<String, dynamic> post);
}
