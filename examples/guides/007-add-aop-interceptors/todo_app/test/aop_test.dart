import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/services/product_service.dart';
import 'package:test/test.dart';

void main() {
  group('AOP Interceptors', () {
    test('@Cached returns same result without re-executing', () async {
      await bootTest($configure, test: (client, container) async {
        final service = container.get<ProductService>();

        final result1 = await service.getProduct('1');
        expect(result1['id'], '1');
        expect(service.callCount, 1);

        final result2 = await service.getProduct('1');
        expect(result2['id'], '1');
        expect(service.callCount, 1); // still 1 — cached
      });
    });

    test('@Cached uses different cache per arguments', () async {
      await bootTest($configure, test: (client, container) async {
        final service = container.get<ProductService>();

        await service.getProduct('1');
        await service.getProduct('2'); // different arg = cache miss
        expect(service.callCount, 2);

        await service.getProduct('1'); // cached
        expect(service.callCount, 2); // still 2
      });
    });

    test('endpoint returns product', () async {
      await bootTest($configure, test: (client, container) async {
        final res = await client.get('/products/42');
        res.expectStatus(200);
        expect(res.json()['id'], '42');
        expect(res.json()['name'], 'Product 42');
      });
    });
  });
}
