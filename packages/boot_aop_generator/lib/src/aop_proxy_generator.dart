import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:boot_core/boot_core.dart';
import 'package:boot_aop/boot_aop.dart';

final _aroundChecker = TypeChecker.fromRuntime(Around);
final _beanSourceChecker = TypeChecker.fromRuntime(BeanSource);

/// Generates proxy subclasses for any bean class with @Around-annotated methods.
/// Scans all classes that have @BeanSource (transitively) — covers @Singleton,
/// @Prototype, @Controller, @ServerFilter, etc.
class AopProxyGenerator extends Generator {
  @override
  String? generate(LibraryReader library, BuildStep buildStep) {
    final output = StringBuffer();

    for (final element in library.allElements) {
      if (element is! ClassElement) continue;
      if (element.isAbstract) continue;
      if (!_hasBeanSourceAnnotation(element)) continue;

      final code = _generateProxy(element);
      if (code.isNotEmpty) output.writeln(code);
    }

    final result = output.toString();
    return result.isEmpty ? null : result;
  }

  static String _generateProxy(ClassElement element) {
    // Find methods with @Around-annotated annotations
    final interceptedMethods = <MethodElement, List<String>>{};
    for (final method in element.methods) {
      if (method.isPrivate || method.isStatic) continue;
      for (final meta in method.metadata) {
        final metaElement = meta.element;
        if (metaElement == null) continue;
        final annotationClass = metaElement.enclosingElement3;
        if (annotationClass is ClassElement &&
            _aroundChecker.hasAnnotationOf(annotationClass)) {
          interceptedMethods.putIfAbsent(method, () => []).add(annotationClass.name);
        }
      }
    }

    if (interceptedMethods.isEmpty) return '';

    final className = element.name;
    final constructor = element.unnamedConstructor;
    if (constructor == null) return '';

    final params = constructor.parameters;
    final superArgs = params.map((p) => p.name).join(', ');
    final createArgs = params.map((p) => 'container.get<${p.type.getDisplayString()}>()').join(', ');

    // Generate method overrides
    final overrides = StringBuffer();
    for (final entry in interceptedMethods.entries) {
      final method = entry.key;
      final adviceAnnotations = entry.value;
      final methodParams = method.parameters;

      final paramList = methodParams
          .map((p) => '${p.type.getDisplayString()} ${p.name}')
          .join(', ');
      final argNames = methodParams.map((p) => p.name).join(', ');

      final isAsync = method.returnType.isDartAsyncFuture;
      final returnType = method.returnType.getDisplayString();
      final asyncKw = isAsync ? 'async' : '';
      final awaitKw = isAsync ? 'await ' : '';
      final invokeMethod = isAsync ? 'invokeAsync()' : 'invoke()';

      final interceptorsList = adviceAnnotations
          .map((a) => '..._\$container.getInterceptors($a)')
          .join(', ');

      overrides.writeln('  @override');
      overrides.writeln('  $returnType ${method.name}($paramList) $asyncKw{');
      overrides.writeln('    return ${awaitKw}InterceptorChain(');
      overrides.writeln('      interceptors: [$interceptorsList],');
      overrides.writeln("      methodName: '${method.name}',");
      overrides.writeln('      args: [$argNames],');
      overrides.writeln('      target: this,');
      overrides.writeln('      originalMethod: () => super.${method.name}($argNames),');
      overrides.writeln('    ).$invokeMethod;');
      overrides.writeln('  }');
    }

    // Proxy class
    final proxyParams = params
        .map((p) => '${p.type.getDisplayString()} ${p.name}')
        .join(', ');
    final proxyConstructorParams = proxyParams.isEmpty
        ? 'this._\$container'
        : 'this._\$container, $proxyParams';

    return '''
class \$${className}\$Proxy extends $className {
  final BeanContainer _\$container;

  \$${className}\$Proxy($proxyConstructorParams) : super($superArgs);

$overrides}

class \$${className}\$ProxyDefinition extends BeanDefinition {
  @override
  Type get beanType => $className;

  @override
  $className create(BeanContainer container) =>
      \$${className}\$Proxy(container, $createArgs);
}
''';
  }

  bool _hasBeanSourceAnnotation(ClassElement element) {
    for (final annotation in element.metadata) {
      final annotationType = annotation.element;
      if (annotationType == null) continue;
      final enclosing = annotationType.enclosingElement3;
      if (enclosing == null) continue;
      if (enclosing is ClassElement) {
        if (_beanSourceChecker.hasAnnotationOf(enclosing)) return true;
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
