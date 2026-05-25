import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/constant/value.dart';

/// Generates the `annotationMetadata` getter code for a BeanDefinition.
String generateAnnotationMetadata(ClassElement element) {
  final items = emitAnnotationValues(element);
  if (items.isEmpty) return '';

  return '''
  @override
  List<AnnotationValue> get annotationMetadata => const [
${items.map((i) => '    $i').join(',\n')},
  ];''';
}

/// Emits annotation values for any element (class, method, etc.)
/// Returns a list of code strings, each representing an AnnotationValue const.
List<String> emitAnnotationValues(Element element) {
  final annotations = <String>[];

  for (final metadata in element.metadata) {
    final annotationElement = metadata.element;
    if (annotationElement == null) continue;

    final enclosing = annotationElement.enclosingElement3;
    if (enclosing == null) continue;
    if (enclosing is! ClassElement) continue;

    final source = enclosing.source;
    final uri = '${source.uri}#${enclosing.name}';

    final constantValue = metadata.computeConstantValue();
    if (constantValue == null) continue;

    final values = _extractValues(constantValue, enclosing);

    if (values.isEmpty) {
      annotations.add("const AnnotationValue(AnnotationType('$uri'))");
    } else {
      final mapEntries = values.entries
          .map((e) => "'${e.key}': ${_dartLiteral(e.value)}")
          .join(', ');
      annotations.add(
          "const AnnotationValue(AnnotationType('$uri'), {$mapEntries})");
    }
  }

  return annotations;
}

Map<String, dynamic> _extractValues(DartObject obj, ClassElement annotationClass) {
  final values = <String, dynamic>{};
  for (final field in annotationClass.fields) {
    if (field.isStatic || field.isSynthetic) continue;
    final fieldValue = obj.getField(field.name);
    if (fieldValue == null || fieldValue.isNull) continue;
    final value = _toDartValue(fieldValue);
    if (value != null) values[field.name] = value;
  }
  return values;
}

dynamic _toDartValue(DartObject obj) {
  if (obj.isNull) return null;
  if (obj.toBoolValue() != null) return obj.toBoolValue();
  if (obj.toIntValue() != null) return obj.toIntValue();
  if (obj.toDoubleValue() != null) return obj.toDoubleValue();
  if (obj.toStringValue() != null) return obj.toStringValue();
  if (obj.toListValue() != null) {
    return obj.toListValue()!.map(_toDartValue).toList();
  }
  return null;
}

String _dartLiteral(dynamic value) {
  if (value == null) return 'null';
  if (value is bool) return value.toString();
  if (value is int) return value.toString();
  if (value is double) return value.toString();
  if (value is String) return "'${value.replaceAll("'", "\\'")}'";
  if (value is List) return '[${value.map(_dartLiteral).join(', ')}]';
  return 'null';
}
