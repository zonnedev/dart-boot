import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:boot_http/boot_http.dart';
import 'package:boot_core/boot_core.dart';
import 'package:boot_aop/boot_aop.dart';

import 'annotation_metadata_emitter.dart';


final _injectChecker = TypeChecker.fromRuntime(Inject);
final _namedChecker = TypeChecker.fromRuntime(Named);
final _valueChecker = TypeChecker.fromRuntime(Value);

/// Generates BeanDefinition classes for @Singleton annotated classes.
class BeanGenerator extends GeneratorForAnnotation<Singleton> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // Skip if also has @Controller — ControllerBeanGenerator handles it
    if (element is ClassElement && TypeChecker.fromRuntime(Controller).hasAnnotationOf(element)) {
      return '';
    }
    return generateBeanDefinition(element, annotation);
  }

  static String generateBeanDefinition(Element element, ConstantReader annotation) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@Singleton can only be applied to classes.',
        element: element,
      );
    }

    if (element.isPrivate) {
      throw InvalidGenerationSourceError(
        '@Singleton cannot be applied to private classes.',
        element: element,
      );
    }

    if (element.isAbstract) {
      throw InvalidGenerationSourceError(
        '@Singleton cannot be applied to abstract class "${element.name}". '
        'Use a @Factory method to produce instances of abstract types.',
        element: element,
      );
    }

    final constructor = element.unnamedConstructor;
    if (constructor == null) {
      throw InvalidGenerationSourceError(
        '@Singleton class "${element.name}" must have an unnamed constructor.',
        element: element,
      );
    }

    final className = element.name;
    final params = constructor.parameters;

    // Check for @ConfigurationProperties
    final configPropsChecker = TypeChecker.fromRuntime(ConfigurationProperties);
    final configPropsAnnotation = configPropsChecker.firstAnnotationOf(element);
    final String createArgs;

    if (configPropsAnnotation != null) {
      final prefix = configPropsAnnotation.getField('prefix')!.toStringValue()!;
      createArgs = params.map((p) {
        final value = _buildConfigArg(p, prefix);
        return p.isNamed ? '${p.name}: $value' : value;
      }).join(', ');
    } else {
      createArgs = params.map((p) => _buildArg(p)).join(', ');
    }

    final postConstruct = _findAnnotatedMethod(element, 'PostConstruct');
    final preDestroy = _findAnnotatedMethod(element, 'PreDestroy');

    // Detect methods annotated with @MethodHook annotations
    final hookMethods = <MethodElement>[];
    for (final method in element.methods) {
      if (method.isPrivate || method.isStatic) continue;
      for (final ann in method.metadata) {
        final annElement = ann.element?.enclosingElement3;
        if (annElement is ClassElement) {
          // Check if the annotation class is meta-annotated with @MethodHook
          if (annElement.metadata.any((m) => m.element?.enclosingElement3?.name == 'MethodHook')) {
            hookMethods.add(method);
            break;
          }
        }
      }
    }

    // Check if postConstruct is async
    final isPostConstructAsync = postConstruct != null &&
        postConstruct.returnType.isDartAsyncFuture;

    // Build class
    final buf = StringBuffer();
    buf.writeln('class \$${className}Definition extends BeanDefinition {');

    buf.writeln('  @override');
    buf.writeln('  get beanType => $className;');

    // Emit annotation metadata (includes ExceptionHandler<E> type detection)
    final annotationItems = emitAnnotationValues(element);

    // Detect ExceptionHandler<E> and add handledType
    final exceptionHandlerChecker = TypeChecker.fromRuntime(ExceptionHandler);
    if (exceptionHandlerChecker.isAssignableFromType(element.thisType)) {
      final ehInterface = element.allSupertypes
          .where((i) => exceptionHandlerChecker.isExactlyType(i))
          .firstOrNull;
      if (ehInterface != null && ehInterface.typeArguments.isNotEmpty) {
        final exceptionType = ehInterface.typeArguments.first.getDisplayString();
        annotationItems.add(
          "const AnnotationValue(AnnotationType('package:boot_http_common/src/http/exception_handler.dart#ExceptionHandler'), {'handledType': $exceptionType})");
      }
    }

    if (annotationItems.isNotEmpty) {
      buf.writeln();
      buf.writeln('  @override');
      buf.writeln('  List<AnnotationValue> get annotationMetadata => const [');
      buf.writeln('    ${annotationItems.join(',\n    ')},');
      buf.writeln('  ];');
    }

    // Emit methodMetadata for @MethodHook methods
    if (hookMethods.isNotEmpty) {
      buf.writeln();
      buf.writeln('  @override');
      buf.writeln('  List<MethodMetadata> get methodMetadata => const [');
      for (final m in hookMethods) {
        final methodAnnotations = emitAnnotationValues(m);
        final paramTypes = m.parameters.map((p) => p.type.getDisplayString()).toList();
        final paramTypesCode = paramTypes.isNotEmpty
            ? ', [${paramTypes.join(', ')}]'
            : '';
        buf.writeln("    MethodMetadata('${m.name}', [${methodAnnotations.join(', ')}]$paramTypesCode),");
      }
      buf.writeln('  ];');

      // Emit dispatch
      buf.writeln();
      buf.writeln('  @override');
      buf.writeln('  dynamic dispatch(Object instance, String method, List<dynamic> args) {');
      buf.writeln('    final bean = instance as $className;');
      buf.writeln('    switch (method) {');
      for (final m in hookMethods) {
        final args = List.generate(m.parameters.length, (i) {
          final paramType = m.parameters[i].type.getDisplayString();
          return 'args[$i] as $paramType';
        }).join(', ');
        buf.writeln("      case '${m.name}': return bean.${m.name}($args);");
      }
      buf.writeln("      default: return super.dispatch(instance, method, args);");
      buf.writeln('    }');
      buf.writeln('  }');
    }

    buf.writeln();
    buf.writeln('  @override');
    buf.writeln('  $className create(BeanContainer container) => $className($createArgs);');

    // PostConstruct — only actual @PostConstruct, no event/scheduled wiring
    if (postConstruct != null) {
      if (isPostConstructAsync) {
        buf.writeln('  @override');
        buf.writeln('  bool get hasPostConstructAsync => true;');
        buf.writeln('  @override');
        buf.writeln('  Future<void> postConstructAsync(dynamic instance) async {');
        buf.writeln('    await (instance as $className).${postConstruct.name}();');
        buf.writeln('  }');
      } else {
        buf.writeln('  @override');
        buf.writeln('  bool get hasPostConstruct => true;');
        buf.writeln('  @override');
        buf.writeln('  void postConstruct(dynamic instance) {');
        buf.writeln('    (instance as $className).${postConstruct.name}();');
        buf.writeln('  }');
      }
    }

    if (preDestroy != null) {
      final isPreDestroyAsync = preDestroy.returnType.isDartAsyncFuture;
      if (isPreDestroyAsync) {
        buf.writeln('  @override');
        buf.writeln('  bool get hasPreDestroyAsync => true;');
        buf.writeln('  @override');
        buf.writeln('  Future<void> preDestroyAsync(dynamic instance) => (instance as $className).${preDestroy.name}();');
      } else {
        buf.writeln('  @override');
        buf.writeln('  bool get hasPreDestroy => true;');
        buf.writeln('  @override');
        buf.writeln('  void preDestroy(dynamic instance) => (instance as $className).${preDestroy.name}();');
      }
    }

    buf.writeln('}');
    return buf.toString();
  }

  static String _buildArg(ParameterElement p) {
    final valueAnnotation = _valueChecker.firstAnnotationOf(p);
    if (valueAnnotation != null) {
      final placeholder = valueAnnotation.getField('value')!.toStringValue()!;
      final escaped = placeholder.replaceAll(r'$', r'\$');
      final type = p.type;
      if (type.isDartCoreInt) return "int.parse(container.get<BootConfig>().resolvePlaceholder('$escaped'))";
      if (type.isDartCoreDouble) return "double.parse(container.get<BootConfig>().resolvePlaceholder('$escaped'))";
      if (type.isDartCoreBool) return "container.get<BootConfig>().resolvePlaceholder('$escaped') == 'true'";
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

  static String _buildConfigArg(ParameterElement p, String prefix) {
    final kebabName = p.name.replaceAllMapped(
        RegExp(r'[A-Z]'), (m) => '-${m.group(0)!.toLowerCase()}');
    final key = '$prefix.$kebabName';
    final getter = "container.get<BootConfig>().get('$key')";
    final type = p.type;
    final defaultCode = p.defaultValueCode;

    if (type.getDisplayString() == 'Duration') {
      final fallback = defaultCode ?? 'Duration.zero';
      return "parseDurationOrNull($getter) ?? $fallback";
    }
    if (type.isDartCoreInt) {
      final fallback = defaultCode ?? '0';
      return "int.tryParse($getter ?? '') ?? $fallback";
    }
    if (type.isDartCoreDouble) {
      final fallback = defaultCode ?? '0.0';
      return "double.tryParse($getter ?? '') ?? $fallback";
    }
    if (type.isDartCoreBool) {
      return "$getter == 'true'";
    }
    if (type.isDartCoreString) {
      final fallback = defaultCode ?? "''";
      return "$getter ?? $fallback";
    }
    // Fallback: try to resolve as a bean (nested config or dependency)
    return 'container.get<${type.getDisplayString()}>()';
  }

  static MethodElement? _findAnnotatedMethod(ClassElement cls, String annotationName) {
    for (final method in cls.methods) {
      for (final meta in method.metadata) {
        if (meta.element?.enclosingElement3?.name == annotationName) {
          return method;
        }
      }
    }
    return null;
  }
}

/// Generates BeanDefinition for @Controller classes (implies @Singleton).
class ControllerBeanGenerator extends GeneratorForAnnotation<Controller> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    return BeanGenerator.generateBeanDefinition(element, annotation);
  }
}

/// Generates BeanDefinition for @ServerFilter classes (implies @Singleton).
class ServerFilterBeanGenerator extends GeneratorForAnnotation<ServerFilter> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    return BeanGenerator.generateBeanDefinition(element, annotation);
  }
}

/// Generates BeanDefinition for @ClientFilter classes (implies @Singleton).
class ClientFilterBeanGenerator extends GeneratorForAnnotation<ClientFilter> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    return BeanGenerator.generateBeanDefinition(element, annotation);
  }
}

/// Generates BeanDefinition for @InterceptorBean classes (implies @Singleton).
class InterceptorBeanBeanGenerator extends GeneratorForAnnotation<InterceptorBean> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    return BeanGenerator.generateBeanDefinition(element, annotation);
  }
}
