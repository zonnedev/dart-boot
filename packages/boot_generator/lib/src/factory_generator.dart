import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'package:boot_core/boot_core.dart';



final _singletonChecker = TypeChecker.fromRuntime(Singleton);
final _prototypeChecker = TypeChecker.fromRuntime(Prototype);

/// Generates BeanDefinition classes for methods in @Factory classes.
class FactoryGenerator extends GeneratorForAnnotation<Factory> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@Factory can only be applied to classes.',
        element: element,
      );
    }

    final factoryClass = element.name;
    final output = StringBuffer();

    for (final method in element.methods) {
      final isBeanMethod = _singletonChecker.hasAnnotationOf(method) ||
          _prototypeChecker.hasAnnotationOf(method);

      if (!isBeanMethod) continue;

      final returnType = method.returnType.getDisplayString();
      final methodName = method.name;

      // Read preDestroy from @Singleton annotation
      final singletonAnnotation = _singletonChecker.firstAnnotationOf(method);
      final preDestroy = singletonAnnotation?.getField('preDestroy')?.toStringValue();
      final hasPreDestroy = preDestroy != null && preDestroy.isNotEmpty;

      // Build method args
      final args = method.parameters
          .map((p) => 'container.get<${p.type.getDisplayString()}>()')
          .join(', ');

      final preDestroyOverride = hasPreDestroy
          ? '''
  @override
  bool get hasPreDestroy => true;
  @override
  void preDestroy(dynamic instance) => (instance as $returnType).$preDestroy();'''
          : '';

      output.writeln('''
class \$${factoryClass}_${methodName}Definition extends BeanDefinition {
  @override
  String get typeName => '$returnType (from $factoryClass.$methodName)';

  @override
  $returnType create(BeanContainer container) {
    final factory = container.get<$factoryClass>();
    return factory.$methodName($args);
  }
$preDestroyOverride
}
''');
    }

    return output.toString();
  }
}
