import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:boot_serialization/boot_serialization.dart';

/// Generates toJson/fromJson for @Serdeable (both).
class SerdeableGenerator extends GeneratorForAnnotation<Serdeable> {
  @override
  String generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) =>
      _generate(element, serialize: true, deserialize: true);
}

/// Generates toJson only for @Serializable.
class SerializableGenerator extends GeneratorForAnnotation<Serializable> {
  @override
  String generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) =>
      _generate(element, serialize: true, deserialize: false);
}

/// Generates fromJson only for @Deserializable.
class DeserializableGenerator extends GeneratorForAnnotation<Deserializable> {
  @override
  String generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) =>
      _generate(element, serialize: false, deserialize: true);
}

String _generate(Element element, {required bool serialize, required bool deserialize}) {
  if (element is! ClassElement) {
    throw InvalidGenerationSourceError(
      'Serde annotations can only be applied to classes.',
      element: element,
    );
  }

  final className = element.name;
  final constructor = element.unnamedConstructor;
  if (constructor == null) {
    throw InvalidGenerationSourceError(
      'Serde class "$className" must have an unnamed constructor.',
      element: element,
    );
  }

  final params = constructor.parameters;
  final buf = StringBuffer();

  // Generate toJson
  if (serialize) {
    final toJsonFields = params
        .map((p) => "      '${p.name}': ${p.name},")
        .join('\n');
    final topLevelFields = params
        .map((p) => "      '${p.name}': instance.${p.name},")
        .join('\n');

    buf.writeln('''
extension \$${className}Serialization on $className {
  Map<String, dynamic> toJson() => <String, dynamic>{
$toJsonFields
    };
}

Map<String, dynamic> \$${className}ToJson($className instance) => <String, dynamic>{
$topLevelFields
  };
''');
  }

  // Generate fromJson
  if (deserialize) {
    final fromJsonArgs = params.map((p) {
      final isNullable = p.type.nullabilitySuffix == NullabilitySuffix.question;
      return '      ${p.name}: ${_deserializeField(p.name, p.type, isNullable)},';
    }).join('\n');

    buf.writeln('''
$className \$${className}FromJson(Map<String, dynamic> json) => $className(
$fromJsonArgs
  );
''');
  }

  return buf.toString();
}

String _deserializeField(String name, DartType type, bool isNullable) {
  final access = "json['$name']";
  final coreType = type;

  if (coreType.isDartCoreString) {
    return '$access as ${isNullable ? 'String?' : 'String'}';
  }
  if (coreType.isDartCoreInt) {
    return isNullable
        ? '($access as num?)?.toInt()'
        : '($access as num).toInt()';
  }
  if (coreType.isDartCoreDouble) {
    return isNullable
        ? '($access as num?)?.toDouble()'
        : '($access as num).toDouble()';
  }
  if (coreType.isDartCoreBool) {
    return '$access as ${isNullable ? 'bool?' : 'bool'}';
  }
  if (coreType is InterfaceType && coreType.element.name == 'DateTime') {
    return isNullable
        ? "$access != null ? DateTime.parse($access as String) : null"
        : "DateTime.parse($access as String)";
  }
  if (coreType.isDartCoreList) {
    return '($access as List<dynamic>?)${isNullable ? '' : '!'}.cast()';
  }
  if (coreType.isDartCoreMap) {
    return '($access as Map<String, dynamic>?)${isNullable ? '' : '!'}';
  }

  // Nested serdeable — assume fromJson exists
  final baseType = type.getDisplayString().replaceAll('?', '');
  if (isNullable) {
    return "$access != null ? \$${baseType}FromJson($access as Map<String, dynamic>) : null";
  }
  return "\$${baseType}FromJson($access as Map<String, dynamic>)";
}
