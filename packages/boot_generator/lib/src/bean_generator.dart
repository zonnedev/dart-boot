import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:boot_http/boot_http.dart';
import 'package:boot_core/boot_core.dart';
import 'package:boot_events/boot_events.dart';
import 'package:boot_aop/boot_aop.dart';

import 'package:boot_scheduling/boot_scheduling.dart';


final _injectChecker = TypeChecker.fromRuntime(Inject);
final _namedChecker = TypeChecker.fromRuntime(Named);
final _valueChecker = TypeChecker.fromRuntime(Value);
final _eventListenerChecker = TypeChecker.fromRuntime(EventListener);
final _scheduledChecker = TypeChecker.fromRuntime(Scheduled);

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

    final createArgs = params.map((p) => _buildArg(p)).join(', ');

    final postConstruct = _findAnnotatedMethod(element, 'PostConstruct');
    final preDestroy = _findAnnotatedMethod(element, 'PreDestroy');

    // Detect @EventListener methods
    final eventListeners = element.methods
        .where((m) => _eventListenerChecker.hasAnnotationOf(m))
        .toList();

    // Detect @Scheduled methods
    final scheduledMethods = <MethodElement, Map<String, String>>{};
    for (final method in element.methods) {
      final annotation = _scheduledChecker.firstAnnotationOf(method);
      if (annotation == null) continue;
      scheduledMethods[method] = {
        'fixedRate': annotation.getField('fixedRate')?.toStringValue() ?? '',
        'fixedDelay': annotation.getField('fixedDelay')?.toStringValue() ?? '',
        'initialDelay': annotation.getField('initialDelay')?.toStringValue() ?? '',
      };
    }

    // Check if postConstruct is async
    final isPostConstructAsync = postConstruct != null &&
        postConstruct.returnType.isDartAsyncFuture;

    final hasPostLogic = postConstruct != null || eventListeners.isNotEmpty || scheduledMethods.isNotEmpty;
    final needsContainer = eventListeners.isNotEmpty || scheduledMethods.isNotEmpty;

    // Build class
    final buf = StringBuffer();
    buf.writeln('class \$${className}Definition extends BeanDefinition {');

    if (needsContainer) {
      buf.writeln('  BeanContainer? _container;');
    }

    buf.writeln('  @override');
    buf.writeln("  String get typeName => '$className';");
    buf.writeln();
    buf.writeln('  @override');

    if (needsContainer) {
      buf.writeln('  $className create(BeanContainer container) {');
      buf.writeln('    _container = container;');
      buf.writeln('    return $className($createArgs);');
      buf.writeln('  }');
    } else {
      buf.writeln('  $className create(BeanContainer container) => $className($createArgs);');
    }

    if (hasPostLogic) {
      if (isPostConstructAsync && eventListeners.isEmpty && scheduledMethods.isEmpty) {
        // Pure async postConstruct
        buf.writeln('  @override');
        buf.writeln('  bool get hasPostConstructAsync => true;');
        buf.writeln('  @override');
        buf.writeln('  Future<void> postConstructAsync(dynamic instance) async {');
        buf.writeln('    await (instance as $className).${postConstruct.name}();');
        buf.writeln('  }');
      } else {
        // Sync postConstruct (possibly with event listeners and scheduled tasks)
        buf.writeln('  @override');
        buf.writeln('  bool get hasPostConstruct => true;');
        buf.writeln('  @override');
        buf.writeln('  void postConstruct(dynamic instance) {');
        if (postConstruct != null && !isPostConstructAsync) {
          buf.writeln('    (instance as $className).${postConstruct.name}();');
        }
        if (eventListeners.isNotEmpty) {
          buf.writeln('    final bus = _container!.get<EventBus>();');
          for (final m in eventListeners) {
            final paramType = m.parameters.first.type.getDisplayString();
            buf.writeln('    bus.on<$paramType>((instance as $className).${m.name});');
          }
        }
        if (scheduledMethods.isNotEmpty) {
          buf.writeln('    final scheduler = _container!.get<TaskScheduler>();');
          for (final entry in scheduledMethods.entries) {
            final m = entry.key;
            final params = entry.value;
            final fixedRate = params['fixedRate']!;
            final fixedDelay = params['fixedDelay']!;
            final initialDelay = params['initialDelay']!;
            final initDelayArg = initialDelay.isNotEmpty
                ? ", initialDelay: parseDuration('$initialDelay')"
                : '';

            if (fixedRate.isNotEmpty) {
              buf.writeln("    scheduler.scheduleFixedRate('$className.${m.name}', parseDuration('$fixedRate'), (instance as $className).${m.name}$initDelayArg);");
            } else if (fixedDelay.isNotEmpty) {
              buf.writeln("    scheduler.scheduleFixedDelay('$className.${m.name}', parseDuration('$fixedDelay'), () async { (instance as $className).${m.name}(); }$initDelayArg);");
            }
          }
        }
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
