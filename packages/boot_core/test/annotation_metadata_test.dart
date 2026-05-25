import 'package:boot_core/boot_core.dart';
import 'package:test/test.dart';

void main() {
  group('AnnotationType', () {
    test('equality by uri', () {
      const a = AnnotationType('package:foo/bar.dart#Baz');
      const b = AnnotationType('package:foo/bar.dart#Baz');
      const c = AnnotationType('package:foo/bar.dart#Other');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode consistent with equality', () {
      const a = AnnotationType('package:foo/bar.dart#X');
      const b = AnnotationType('package:foo/bar.dart#X');
      expect(a.hashCode, b.hashCode);
    });

    test('toString returns uri', () {
      const t = AnnotationType('package:foo/bar.dart#Baz');
      expect(t.toString(), 'package:foo/bar.dart#Baz');
    });
  });

  group('AnnotationMetadataQuery', () {
    const filterType = AnnotationType('package:test/filter.dart#Filter');
    const securedType = AnnotationType('package:test/secured.dart#Secured');
    final metadata = [
      AnnotationValue(filterType, {'pattern': '/**'}),
      AnnotationValue(securedType, {'roles': ['admin']}),
    ];

    test('byType finds matching annotation', () {
      final result = metadata.byType(filterType);
      expect(result, isNotNull);
      expect(result!.values['pattern'], '/**');
    });

    test('byType returns null for missing type', () {
      const other = AnnotationType('package:test/other.dart#Other');
      expect(metadata.byType(other), isNull);
    });

    test('hasType returns true for present type', () {
      expect(metadata.hasType(securedType), isTrue);
    });

    test('hasType returns false for absent type', () {
      const other = AnnotationType('package:test/other.dart#Other');
      expect(metadata.hasType(other), isFalse);
    });

    test('works on empty list', () {
      final empty = <AnnotationValue>[];
      expect(empty.byType(filterType), isNull);
      expect(empty.hasType(filterType), isFalse);
    });
  });
}
