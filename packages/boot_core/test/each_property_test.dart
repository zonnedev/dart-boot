import 'package:boot_core/boot_core.dart';
import 'package:test/test.dart';

void main() {
  group('@EachProperty', () {
    test('annotation stores prefix', () {
      const ann = EachProperty('boot.http.services');
      expect(ann.prefix, 'boot.http.services');
    });
  });
}
