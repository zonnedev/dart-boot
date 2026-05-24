import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:boot_http/boot_http.dart';
import 'package:boot_core/boot_core.dart';
import 'package:boot_aop/boot_aop.dart';

final _aroundChecker = TypeChecker.fromRuntime(Around);
final _controllerChecker = TypeChecker.fromRuntime(Controller);

/// Generates proxy subclasses for beans with @Around-annotated methods.
class AopProxyGenerator extends GeneratorForAnnotation<Singleton> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) return '';
    if (_controllerChecker.hasAnnotationOf(element)) return '';
    return _generateProxy(element);
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
    final createArgs = params.map((p) => _buildArg(p)).join(', ');

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

      // Combine interceptors from all @Around annotations on this method
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
  String get typeName => '$className (proxy)';

  @override
  $className create(BeanContainer container) =>
      \$${className}\$Proxy(container, $createArgs);
}
''';
  }

  static String _buildArg(ParameterElement p) {
    return 'container.get<${p.type.getDisplayString()}>()';
  }
}

/// AOP proxy generation for @Controller classes.
class ControllerAopProxyGenerator extends GeneratorForAnnotation<Controller> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) return '';
    return AopProxyGenerator._generateProxy(element);
  }
}
