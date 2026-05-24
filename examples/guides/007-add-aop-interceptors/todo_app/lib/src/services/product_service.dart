import 'package:boot/boot.dart';
import '../aop/timed.dart';
import '../aop/cached.dart';

part 'product_service.g.dart';

@Singleton()
class ProductService {
  var _callCount = 0;

  @Timed()
  @Cached()
  Future<Map<String, dynamic>> getProduct(String id) async {
    _callCount++;
    await Future.delayed(Duration(milliseconds: 50));
    return {'id': id, 'name': 'Product $id', 'price': 9.99};
  }

  int get callCount => _callCount;
}
