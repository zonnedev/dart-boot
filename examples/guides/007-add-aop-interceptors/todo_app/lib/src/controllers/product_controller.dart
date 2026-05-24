import 'package:boot/boot.dart';
import '../services/product_service.dart';

part 'product_controller.g.dart';

@Controller('/products')
class ProductController {
  final ProductService _service;
  ProductController(this._service);

  @Get('/<id>')
  Future<Response> get(Request request, @PathParam() String id) async {
    final product = await _service.getProduct(id);
    return Response.json(product);
  }
}
