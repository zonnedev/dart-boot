import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:boot_core/boot_core.dart';

import 'bean_generator.dart';

final _singletonChecker = TypeChecker.fromRuntime(Singleton);
final _prototypeChecker = TypeChecker.fromRuntime(Prototype);
final _beanSourceChecker = TypeChecker.fromRuntime(BeanSource);

/// Unified generator that produces $Definition for ANY class annotated with
/// any annotation meta-annotated with @BeanSource (including @Singleton,
/// @Prototype, @Controller, @ServerFilter, etc.).
class BeanDefinitionGenerator extends Generator {
  @override
  String? generate(LibraryReader library, BuildStep buildStep) {
    final output = StringBuffer();

    for (final annotatedElement in library.allElements) {
      if (annotatedElement is! ClassElement) continue;
      if (annotatedElement.isAbstract) continue;
      if (!_hasBeanSourceAnnotation(annotatedElement)) continue;

      final annotation = _singletonChecker.firstAnnotationOf(annotatedElement) ??
          _prototypeChecker.firstAnnotationOf(annotatedElement);
      final reader = ConstantReader(annotation ?? annotatedElement.metadata.first.computeConstantValue()!);

      try {
        final code = BeanGenerator.generateBeanDefinition(annotatedElement, reader);
        output.writeln(code);
      } catch (_) {
        // Skip elements that can't be processed (e.g., missing constructor)
      }
    }

    final result = output.toString();
    return result.isEmpty ? null : result;
  }

  bool _hasBeanSourceAnnotation(ClassElement element) {
    for (final annotation in element.metadata) {
      final annotationType = annotation.element;
      if (annotationType == null) continue;
      final enclosing = annotationType.enclosingElement3;
      if (enclosing == null) continue;
      if (enclosing is ClassElement) {
        if (_beanSourceChecker.hasAnnotationOf(enclosing)) return true;
        // Transitive check (e.g., @RouteSource has @BeanSource)
        for (final meta in enclosing.metadata) {
          final metaEnclosing = meta.element?.enclosingElement3;
          if (metaEnclosing is ClassElement && _beanSourceChecker.hasAnnotationOf(metaEnclosing)) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
