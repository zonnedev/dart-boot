import 'package:boot/boot.dart';
import '../clients/post_client.dart';

part 'post_controller.g.dart';

@Controller('/posts')
class PostController {
  final PostClient _client;

  PostController(this._client);

  @Get('/')
  Future<Response> list(Request request) async {
    final posts = await _client.list();
    return Response.json(posts.take(5).toList());
  }

  @Get('/<id>')
  Future<Response> getById(Request request, @PathParam() String id) async {
    final post = await _client.getById(id);
    return Response.json(post);
  }

  @Post('/')
  Future<Response> create(Request request) async {
    final body = await request.json();
    final created = await _client.create(body);
    return Response.created(created);
  }
}
