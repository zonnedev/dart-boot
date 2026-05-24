import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:boot_core/boot_core.dart';
import 'package:boot_http/boot_http.dart';





final _injectChecker = TypeChecker.fromRuntime(Inject);
final _namedChecker = TypeChecker.fromRuntime(Named);
final _valueChecker = TypeChecker.fromRuntime(Value);

/// Generates BeanDefinition for @ServerWebSocket classes.
class WebSocketGenerator extends GeneratorForAnnotation<ServerWebSocket> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@ServerWebSocket can only be applied to classes.',
        element: element,
      );
    }

    final className = element.name;
    final constructor = element.unnamedConstructor;
    if (constructor == null) {
      throw InvalidGenerationSourceError(
        '@ServerWebSocket class "$className" must have an unnamed constructor.',
        element: element,
      );
    }

    final params = constructor.parameters;
    final createArgs = params.map((p) => _buildArg(p)).join(', ');

    return '''
class \$${className}Definition extends BeanDefinition {
  @override
  String get typeName => '$className';

  @override
  $className create(BeanContainer container) => $className($createArgs);
}
''';
  }

  String _buildArg(ParameterElement p) {
    final valueAnnotation = _valueChecker.firstAnnotationOf(p);
    if (valueAnnotation != null) {
      final placeholder = valueAnnotation.getField('value')!.toStringValue()!;
      final escaped = placeholder.replaceAll(r'$', r'\$');
      return "container.get<BootConfig>().resolvePlaceholder('$escaped')";
    }

    final injectAnnotation = _injectChecker.firstAnnotationOf(p);
    final namedAnnotation = _namedChecker.firstAnnotationOf(p);
    final qualifierName = injectAnnotation?.getField('name')?.toStringValue() ??
        namedAnnotation?.getField('value')?.toStringValue();

    if (qualifierName != null && qualifierName.isNotEmpty) {
      return "container.getNamed<${p.type.getDisplayString()}>('$qualifierName')";
    }
    return 'container.get<${p.type.getDisplayString()}>()';
  }
}
