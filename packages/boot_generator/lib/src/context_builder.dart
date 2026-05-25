import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';
import 'package:yaml/yaml.dart';
import 'package:boot_core/boot_core.dart';

import 'package:boot_aop/boot_aop.dart';
/// Aggregating builder that collects all bean/route metadata and generates
/// the application context wiring file.
class ContextBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {
        r'lib/$lib$': [
          'lib/src/generated/boot_context.g.dart',
          'lib/src/generated/boot_module.g.dart',
        ],
      };

  // Type checkers (initialized once, used across scans)
  final _singletonChecker = TypeChecker.fromRuntime(Singleton);
  final _beanSourceChecker = TypeChecker.fromRuntime(BeanSource);
  final _factoryChecker = TypeChecker.fromRuntime(Factory);
  final _prototypeChecker = TypeChecker.fromRuntime(Prototype);
  final _requiresChecker = TypeChecker.fromRuntime(Requires);
  final _replacesChecker = TypeChecker.fromRuntime(Replaces);
  final _interceptorBeanChecker = TypeChecker.fromRuntime(InterceptorBean);
  final _namedChecker = TypeChecker.fromUrl('package:boot_core/src/annotations/named.dart#Named');
  final _primaryChecker = TypeChecker.fromUrl('package:boot_core/src/annotations/primary.dart#Primary');
  final _aroundChecker = TypeChecker.fromRuntime(Around);

  @override
  Future<void> build(BuildStep buildStep) async {
    final beanMeta = <_BeanMeta>[];
    final routeMeta = <_RouteMeta>[];
    final interceptorMeta = <_InterceptorMeta>[];

    // Detect if this package is a @BootLibrary or an app
    bool isBootLibrary = false;
    final bootLibraryChecker = TypeChecker.fromRuntime(BootLibrary);
    final barrelId = AssetId(buildStep.inputId.package, 'lib/${buildStep.inputId.package}.dart');
    if (await buildStep.canRead(barrelId)) {
      try {
        final barrelLib = await buildStep.resolver.libraryFor(barrelId);
        if (bootLibraryChecker.hasAnnotationOf(barrelLib)) {
          isBootLibrary = true;
        }
      } catch (_) {}
    }

    // Scan current package's lib/ source
    await for (final input in buildStep.findAssets(Glob('lib/**.dart'))) {
      if (input.path.endsWith('.g.dart')) continue;
      LibraryElement library;
      try {
        library = await buildStep.resolver.libraryFor(input);
      } catch (_) {
        continue;
      }
      _scanLibrary(library, input, beanMeta, routeMeta, interceptorMeta);
    }

    if (isBootLibrary) {
      // ─── Library mode: generate $<package>Module() ─────────────────────────
      // Discover this library's own @BootLibrary dependencies
      final libraryDeps = <_LibraryModule>[];
      final libraryProvidedTypes = <String>{};
      final depPackages = await _getDepPackages(buildStep);
      final packageConfig = await buildStep.packageConfig;

      for (final package in packageConfig.packages) {
        final packageName = package.name;
        if (packageName == buildStep.inputId.package) continue;
        if (depPackages != null && !depPackages.contains(packageName)) continue;

        final depBarrelId = AssetId(packageName, 'lib/$packageName.dart');
        if (!await buildStep.canRead(depBarrelId)) continue;
        try {
          final depLib = await buildStep.resolver.libraryFor(depBarrelId);
          if (bootLibraryChecker.hasAnnotationOf(depLib)) {
            libraryDeps.add(_LibraryModule(
              packageName: packageName,
              functionName: '\$${_camelCase(packageName)}Module',
              import: 'package:$packageName/src/generated/boot_module.g.dart',
            ));
            // Collect exported bean types for validation
            for (final exported in depLib.exportedLibraries) {
              final uri = exported.source.uri;
              if (!uri.toString().startsWith('package:$packageName/')) continue;
              for (final element in exported.topLevelElements) {
                if (element is ClassElement) {
                  if (_hasBeanSourceAnnotation(element)) {
                    libraryProvidedTypes.add(element.name);
                    // Collect typed-as interfaces (explicit or auto-detected)
                    final ann = _singletonChecker.firstAnnotationOf(element);
                    final typed = ann?.getField('typed')?.toListValue()
                        ?.map((v) => v.toTypeValue()?.getDisplayString() ?? '')
                        .where((s) => s.isNotEmpty) ?? [];
                    if (typed.isNotEmpty) {
                      libraryProvidedTypes.addAll(typed);
                    } else {
                      // Auto-detect from interfaces (including inherited)
                      libraryProvidedTypes.addAll(
                        element.allSupertypes
                            .map((i) => i.element.name)
                            .where((s) => s != 'Object'));
                    }
                  }
                }
              }
            }
          }
        } catch (_) {}
      }

      final sorted = _topologicalSort(beanMeta);
      final moduleOutput = _generateModuleOutput(
          buildStep.inputId.package, sorted, routeMeta, interceptorMeta,
          libraryDeps: libraryDeps);

      final moduleId = AssetId(
        buildStep.inputId.package,
        'lib/src/generated/boot_module.g.dart',
      );
      await buildStep.writeAsString(moduleId, moduleOutput);

      // Warn if module is not exported from barrel
      if (await buildStep.canRead(barrelId)) {
        final barrelContent = await buildStep.readAsString(barrelId);
        if (!barrelContent.contains('boot_module.g.dart')) {
          log.warning(
            '\n╔══════════════════════════════════════════════════════════════\n'
            '║ MODULE NOT EXPORTED\n'
            '║\n'
            '║ Generated boot_module.g.dart but it is NOT exported from\n'
            '║ lib/${buildStep.inputId.package}.dart.\n'
            '║\n'
            '║ Apps that depend on this library won\'t discover its beans.\n'
            '║ Fix: Add to your barrel file:\n'
            '║   export \'src/generated/boot_module.g.dart\';\n'
            '╚══════════════════════════════════════════════════════════════',
          );
        }
      }

      // Also generate a boot_context.g.dart for the library's own tests
      _validateGraph(beanMeta, libraryProvided: libraryProvidedTypes);
      final contextOutput = _generateOutput(sorted, routeMeta, interceptorMeta,
          libraryModules: []);
      final contextId = AssetId(
        buildStep.inputId.package,
        'lib/src/generated/boot_context.g.dart',
      );
      await buildStep.writeAsString(contextId, contextOutput);
    } else {
      // ─── App mode: discover @BootLibrary deps and generate $configure() ────
      List<String>? scanFilter;
      final appChecker = TypeChecker.fromRuntime(BootApplication);
      await for (final input in buildStep.findAssets(Glob('lib/**/*.dart'))) {
        if (input.path.endsWith('.g.dart')) continue;
        try {
          final library = await buildStep.resolver.libraryFor(input);
          for (final element in library.topLevelElements) {
            if (element is ClassElement && appChecker.hasAnnotationOf(element)) {
              final annotation = appChecker.firstAnnotationOf(element);
              final scanList = annotation?.getField('scan')?.toListValue();
              if (scanList != null && scanList.isNotEmpty) {
                scanFilter = scanList
                    .map((e) => e.toStringValue() ?? '')
                    .where((s) => s.isNotEmpty)
                    .toList();
              }
            }
          }
        } catch (_) {}
      }

      // Discover @BootLibrary dependencies
      final libraryModules = <_LibraryModule>[];
      final libraryProvidedTypes = <String>{};
      final depPackages = await _getDepPackages(buildStep);
      final packageConfig = await buildStep.packageConfig;

      for (final package in packageConfig.packages) {
        final packageName = package.name;
        if (packageName == buildStep.inputId.package) continue;
        if (depPackages != null && !depPackages.contains(packageName)) continue;
        if (scanFilter != null && !scanFilter.contains(packageName)) continue;

        // Check if this dependency has @BootLibrary
        final depBarrelId = AssetId(packageName, 'lib/$packageName.dart');
        if (!await buildStep.canRead(depBarrelId)) continue;

        try {
          final depLib = await buildStep.resolver.libraryFor(depBarrelId);
          if (bootLibraryChecker.hasAnnotationOf(depLib)) {
            // This is a boot library — use its module function
            libraryModules.add(_LibraryModule(
              packageName: packageName,
              functionName: '\$${_camelCase(packageName)}Module',
              import: 'package:$packageName/src/generated/boot_module.g.dart',
            ));
            // Collect exported bean types for validation
            for (final exported in depLib.exportedLibraries) {
              final uri = exported.source.uri;
              if (!uri.toString().startsWith('package:$packageName/')) continue;
              for (final element in exported.topLevelElements) {
                if (element is ClassElement) {
                  if (_hasBeanSourceAnnotation(element)) {
                    libraryProvidedTypes.add(element.name);
                    // Collect typed-as interfaces (explicit or auto-detected)
                    final ann = _singletonChecker.firstAnnotationOf(element);
                    final typed = ann?.getField('typed')?.toListValue()
                        ?.map((v) => v.toTypeValue()?.getDisplayString() ?? '')
                        .where((s) => s.isNotEmpty) ?? [];
                    if (typed.isNotEmpty) {
                      libraryProvidedTypes.addAll(typed);
                    } else {
                      // Auto-detect from interfaces (including inherited)
                      libraryProvidedTypes.addAll(
                        element.allSupertypes
                            .map((i) => i.element.name)
                            .where((s) => s != 'Object'));
                    }
                  }
                }
              }
            }
          } else {
            // Not a boot library — try source scanning (legacy/workspace support)
            await _scanDependencyPackage(buildStep, packageName, beanMeta,
                routeMeta, interceptorMeta);
          }
        } catch (_) {}
      }

      // ─── Validate library integration ──────────────────────────────────────
      for (final module in libraryModules) {
        final moduleAsset = AssetId(module.packageName, 'lib/src/generated/boot_module.g.dart');
        if (!await buildStep.canRead(moduleAsset)) {
          log.severe(
            '\n╔══════════════════════════════════════════════════════════════\n'
            '║ MISSING MODULE\n'
            '║\n'
            '║ Package "${module.packageName}" has @BootLibrary but\n'
            '║ lib/src/generated/boot_module.g.dart was not found.\n'
            '║\n'
            '║ Fix: Run "dart run build_runner build" in the ${module.packageName}\n'
            '║ package, then ensure boot_module.g.dart is exported from the barrel.\n'
            '╚══════════════════════════════════════════════════════════════',
          );
        } else {
          // Check if module is exported from barrel
          final barrelId = AssetId(module.packageName, 'lib/${module.packageName}.dart');
          if (await buildStep.canRead(barrelId)) {
            final barrelContent = await buildStep.readAsString(barrelId);
            if (!barrelContent.contains('boot_module.g.dart')) {
              log.warning(
                '\n╔══════════════════════════════════════════════════════════════\n'
                '║ MODULE NOT EXPORTED\n'
                '║\n'
                '║ Package "${module.packageName}" has @BootLibrary and\n'
                '║ boot_module.g.dart exists, but is NOT exported from the barrel.\n'
                '║\n'
                '║ Fix: Add to lib/${module.packageName}.dart:\n'
                '║   export \'src/generated/boot_module.g.dart\';\n'
                '╚══════════════════════════════════════════════════════════════',
              );
            }
          }
        }
      }

      _validateGraph(beanMeta, libraryProvided: libraryProvidedTypes);
      final sorted = _topologicalSort(beanMeta);

      final output = _generateOutput(sorted, routeMeta, interceptorMeta,
          libraryModules: libraryModules);

      final outputId = AssetId(
        buildStep.inputId.package,
        'lib/src/generated/boot_context.g.dart',
      );
      await buildStep.writeAsString(outputId, output);

      // Write empty module file (required by buildExtensions)
      final emptyModuleId = AssetId(
        buildStep.inputId.package,
        'lib/src/generated/boot_module.g.dart',
      );
      await buildStep.writeAsString(emptyModuleId,
          '// No module generated — this is an application package.\n');
    }
  }

  /// Read direct dependencies from the current package's pubspec.yaml.
  Future<Set<String>?> _getDepPackages(BuildStep buildStep) async {
    final pubspecId = AssetId(buildStep.inputId.package, 'pubspec.yaml');
    if (!await buildStep.canRead(pubspecId)) return null;
    try {
      final content = await buildStep.readAsString(pubspecId);
      final pubspec = loadYaml(content) as YamlMap;
      final deps = <String>{};
      final dependencies = pubspec['dependencies'] as YamlMap?;
      if (dependencies != null) deps.addAll(dependencies.keys.cast<String>());
      return deps;
    } catch (_) {
      return null;
    }
  }

  /// Scan a dependency package's lib/ source for boot annotations.
  Future<void> _scanDependencyPackage(
    BuildStep buildStep,
    String packageName,
    List<_BeanMeta> beanMeta,
    List<_RouteMeta> routeMeta,
    List<_InterceptorMeta> interceptorMeta,
  ) async {
    // Check if this package depends on boot (i.e., is a boot library)
    final depPubspecId = AssetId(packageName, 'pubspec.yaml');
    if (!await buildStep.canRead(depPubspecId)) return;
    try {
      final content = await buildStep.readAsString(depPubspecId);
      final pubspec = loadYaml(content) as YamlMap;
      final deps = pubspec['dependencies'] as YamlMap?;
      if (deps == null || !deps.containsKey('boot')) return;
    } catch (_) {
      return;
    }

    // Find all .dart files in the package's lib/ by checking known entry point
    // We use the resolver to analyze the package's barrel file and its exports
    final barrelId = AssetId(packageName, 'lib/$packageName.dart');
    if (!await buildStep.canRead(barrelId)) return;

    try {
      final library = await buildStep.resolver.libraryFor(barrelId);
      // Scan the barrel file itself
      _scanLibrary(library, barrelId, beanMeta, routeMeta, interceptorMeta);

      // Scan all exported libraries (transitively)
      for (final exported in library.exportedLibraries) {
        final uri = exported.source.uri;
        if (!uri.toString().startsWith('package:$packageName/')) continue;
        final assetId = AssetId.resolve(uri);
        _scanLibrary(exported, assetId, beanMeta, routeMeta, interceptorMeta);
      }
    } catch (_) {}
  }

  /// Analyze a single library for boot annotations and collect metadata.
  void _scanLibrary(
    LibraryElement library,
    AssetId assetId,
    List<_BeanMeta> beanMeta,
    List<_RouteMeta> routeMeta,
    List<_InterceptorMeta> interceptorMeta,
  ) {
    final importUri = assetId.uri.toString();

    for (final element in library.topLevelElements) {
      if (element is! ClassElement) continue;

      final isManagedBean = _hasBeanSourceAnnotation(element);
      final hasRouteSource = _hasRouteSourceAnnotation(element);

      if (isManagedBean) {
        final className = element.name;
        final constructor = element.unnamedConstructor;
        final deps = constructor?.parameters
                .map((p) => p.type.getDisplayString())
                .toList() ??
            [];

        final namedAnnotation = _namedChecker.firstAnnotationOf(element);
        final namedValue = namedAnnotation != null
            ? (namedAnnotation.getField('value')?.toStringValue() ?? _classNameToQualifier(className))
            : null;
        final isPrimary = _primaryChecker.hasAnnotationOf(element);

        final beanAnnotation = _singletonChecker.firstAnnotationOf(element);
        final explicitTyped = beanAnnotation
                ?.getField('typed')
                ?.toListValue()
                ?.map((v) => v.toTypeValue()?.getDisplayString() ?? '')
                .where((s) => s.isNotEmpty)
                .toList() ??
            [];

        // Auto-detect implemented interfaces from AST (including inherited)
        final autoInterfaces = element.allSupertypes
            .map((i) => i.element.name)
            .where((s) => s != 'Object')
            .toSet()
            .toList();

        // Collect import URIs for interface types
        final interfaceImports = element.allSupertypes
            .where((t) => t.element.name != 'Object')
            .map((i) => i.element.source.uri.toString())
            .toSet()
            .toList();

        // Merge: explicit typed takes priority, otherwise use auto-detected
        final typedList = explicitTyped.isNotEmpty ? explicitTyped : autoInterfaces;

        bool hasAopProxy = false;
        for (final method in element.methods) {
          if (method.isPrivate || method.isStatic) continue;
          for (final meta in method.metadata) {
            final metaElement = meta.element;
            if (metaElement == null) continue;
            final annotationClass = metaElement.enclosingElement3;
            if (annotationClass is ClassElement &&
                _aroundChecker.hasAnnotationOf(annotationClass)) {
              hasAopProxy = true;
              break;
            }
          }
          if (hasAopProxy) break;
        }

        final conditions = <_RequiresCondition>[];
        for (final annotation in _requiresChecker.annotationsOf(element)) {
          final beansField = annotation.getField('beans')?.toListValue() ?? [];
          final missingBeansField = annotation.getField('missingBeans')?.toListValue() ?? [];
          conditions.add(_RequiresCondition(
            env: annotation.getField('env')?.toListValue()?.map((e) => e.toStringValue() ?? '').where((s) => s.isNotEmpty).toList() ?? [],
            notEnv: annotation.getField('notEnv')?.toListValue()?.map((e) => e.toStringValue() ?? '').where((s) => s.isNotEmpty).toList() ?? [],
            property: annotation.getField('property')?.toStringValue(),
            value: annotation.getField('value')?.toStringValue(),
            notEquals: annotation.getField('notEquals')?.toStringValue(),
            defaultValue: annotation.getField('defaultValue')?.toStringValue(),
            missingProperty: annotation.getField('missingProperty')?.toStringValue(),
            beans: beansField.map((v) {
              final t = v.toTypeValue();
              return _TypeRef(
                name: t?.getDisplayString() ?? '',
                import: t?.element?.source?.uri.toString() ?? '',
              );
            }).where((r) => r.name.isNotEmpty).toList(),
            missingBeans: missingBeansField.map((v) {
              final t = v.toTypeValue();
              return _TypeRef(
                name: t?.getDisplayString() ?? '',
                import: t?.element?.source?.uri.toString() ?? '',
              );
            }).where((r) => r.name.isNotEmpty).toList(),
          ));
        }

        final replacesAnnotation = _replacesChecker.firstAnnotationOf(element);
        final replacesType = replacesAnnotation?.getField('value')?.toTypeValue()?.getDisplayString();
        final replacesNamed = replacesAnnotation?.getField('named')?.toStringValue();

        beanMeta.add(_BeanMeta(
          className: className,
          definitionClass: '\$${className}Definition',
          dependencies: deps,
          import: importUri,
          namedValue: namedValue,
          isPrimary: isPrimary,
          typedAs: typedList,
          interfaceImports: interfaceImports,
          conditions: conditions,
          replacesType: replacesType,
          replacesNamed: (replacesNamed?.isNotEmpty ?? false) ? replacesNamed : null,
          hasAopProxy: hasAopProxy,
        ));
      }

      if (hasRouteSource) {
        routeMeta.add(_RouteMeta(
          className: element.name,
          routesClass: '\$${element.name}Routes',
          import: importUri,
        ));
      }

      // @InterceptorBean
      final interceptorAnnotation = _interceptorBeanChecker.firstAnnotationOf(element);
      if (interceptorAnnotation != null) {
        final valueField = interceptorAnnotation.getField('value');
        final adviceTypeValue = valueField?.toTypeValue();
        final adviceType = adviceTypeValue?.element?.name ??
            valueField?.type?.element?.name;
        if (adviceType != null && adviceType != 'Null') {
          String? adviceTypeImport;
          if (adviceTypeValue?.element?.source != null) {
            adviceTypeImport = adviceTypeValue!.element!.source!.uri.toString();
          }
          interceptorMeta.add(_InterceptorMeta(
            className: element.name,
            adviceType: adviceType,
            import: importUri,
            adviceTypeImport: adviceTypeImport,
          ));
        }
      }

      // @Factory classes
      if (_factoryChecker.hasAnnotationOf(element)) {
        final factoryClass = element.name;
        beanMeta.add(_BeanMeta(
          className: factoryClass,
          definitionClass: '\$${factoryClass}Definition',
          dependencies: element.unnamedConstructor?.parameters
                  .map((p) => p.type.getDisplayString())
                  .toList() ?? [],
          import: importUri,
        ));

        for (final method in element.methods) {
          final isBeanMethod = _singletonChecker.hasAnnotationOf(method) ||
              _prototypeChecker.hasAnnotationOf(method);
          if (!isBeanMethod) continue;

          final returnType = method.returnType.getDisplayString();
          final isPrototype = _prototypeChecker.hasAnnotationOf(method);
          final namedAnnotation = _namedChecker.firstAnnotationOf(method);
          final namedValue = namedAnnotation != null
              ? (namedAnnotation.getField('value')?.toStringValue() ?? method.name)
              : null;
          final isPrimary = _primaryChecker.hasAnnotationOf(method);

          beanMeta.add(_BeanMeta(
            className: returnType,
            definitionClass: '\$${factoryClass}_${method.name}Definition',
            dependencies: [factoryClass],
            import: importUri,
            namedValue: namedValue,
            isPrimary: isPrimary,
            isPrototype: isPrototype,
          ));
        }
      }
    }
  }

  /// Generate the boot_context.g.dart output string.
  String _generateOutput(
    List<_BeanMeta> sorted,
    List<_RouteMeta> routeMeta,
    List<_InterceptorMeta> interceptorMeta, {
    List<_LibraryModule> libraryModules = const [],
  }) {
    final imports = <String>{};
    for (final bean in sorted) {
      imports.add(bean.import);
      imports.addAll(bean.interfaceImports);
      for (final c in bean.conditions) {
        for (final b in c.beans) if (b.import.isNotEmpty) imports.add(b.import);
        for (final b in c.missingBeans) if (b.import.isNotEmpty) imports.add(b.import);
      }
    }
    for (final route in routeMeta) imports.add(route.import);
    for (final i in interceptorMeta) {
      imports.add(i.import);
      if (i.adviceTypeImport != null) imports.add(i.adviceTypeImport!);
    }

    final importStatements = imports.map((i) => "import '$i';").join('\n');

    // Library module imports
    final moduleImports = libraryModules.map((m) => "import '${m.import}';").join('\n');

    final regs = _buildRegistrations(sorted);
    final registrations = regs.immediate;
    final deferredRegistrations = regs.deferred;

    final routeRegistrations = routeMeta.map((r) =>
      '  router.addAll(${r.routesClass}(container.get<${r.className}>()).routes);').join('\n');
    final interceptorRegistrations = interceptorMeta.map((i) =>
      '  container.registerInterceptor(${i.adviceType}, container.get<${i.className}>());').join('\n');

    // Library module calls
    final moduleCalls = libraryModules.map((m) =>
      '  ${m.functionName}(container, router, config, deferred);').join('\n');

    return '''
// GENERATED by boot_generator — do not edit.
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:boot/boot.dart';
$importStatements
$moduleImports

class _ContainerSelfDefinition extends BeanDefinition {
  final BeanContainer _container;
  _ContainerSelfDefinition(this._container);
  @override
  Type get beanType => BeanContainer;
  @override
  dynamic create(BeanContainer container) => _container;
}

void \$configure(BeanContainer container, BootRouter router) {
  // Self-register the container
  container.register<BeanContainer>(_ContainerSelfDefinition(container));

  final config = container.get<BootConfig>();
  final deferred = <void Function()>[];

  // Load library modules
$moduleCalls

  // Register beans in dependency order
$registrations

  // Evaluate deferred beans (beans/missingBeans conditions)
$deferredRegistrations
  for (final d in deferred.reversed) { d(); }

  // Register interceptors
$interceptorRegistrations

  // Register routes
$routeRegistrations
}
''';
  }

  /// Build config-only condition checks (env, property — no beans/missingBeans).
  String _configChecks(List<_RequiresCondition> conditions) {
    final checks = <String>[];
    for (final c in conditions) {
      if (c.env.isNotEmpty) {
        checks.add("${c.env.map((e) => "config.get('boot.env') == '$e'").join(' || ')}");
      }
      if (c.notEnv.isNotEmpty) {
        checks.add("${c.notEnv.map((e) => "config.get('boot.env') != '$e'").join(' && ')}");
      }
      if (c.property != null && c.property!.isNotEmpty) {
        if (c.value != null && c.value!.isNotEmpty) {
          final defaultPart = c.defaultValue != null && c.defaultValue!.isNotEmpty
              ? " ?? '${c.defaultValue}'" : '';
          checks.add("(config.get('${c.property}')$defaultPart) == '${c.value}'");
        } else if (c.notEquals != null && c.notEquals!.isNotEmpty) {
          checks.add("config.get('${c.property}') != '${c.notEquals}'");
        } else {
          checks.add("config.get('${c.property}') != null");
        }
      }
      if (c.missingProperty != null && c.missingProperty!.isNotEmpty) {
        checks.add("config.get('${c.missingProperty}') == null");
      }
      for (final b in c.beans) {
        checks.add("container.has<${b.name}>()");
      }
      for (final b in c.missingBeans) {
        checks.add("!container.has<${b.name}>()");
      }
    }
    return checks.join(' && ');
  }

  /// Generate two-phase registration code: immediate beans + deferred beans.
  ({String immediate, String deferred}) _buildRegistrations(List<_BeanMeta> sorted) {
    final immediateBuf = StringBuffer();
    final deferredBuf = StringBuffer();

    for (final b in sorted) {
      final regLine = _registrationLine(b);
      final hasDeferred = b.conditions.any((c) => c.isDeferred);

      if (b.conditions.isEmpty) {
        immediateBuf.writeln(regLine);
      } else {
        final checks = _configChecks(b.conditions);
        if (hasDeferred) {
          // Add to deferred list — evaluated after all modules + app beans are registered
          final body = checks.isEmpty ? regLine : 'if ($checks) {\n    $regLine\n    }';
          deferredBuf.writeln('  deferred.add(() { $body });');
        } else {
          final wrapped = checks.isEmpty ? regLine : '  if ($checks) {\n  $regLine\n  }';
          immediateBuf.writeln(wrapped);
        }
      }
    }

    return (immediate: immediateBuf.toString().trimRight(), deferred: deferredBuf.toString().trimRight());
  }

  String _registrationLine(_BeanMeta b) {
    final defClass = b.hasAopProxy
        ? '\$${b.className}\$ProxyDefinition'
        : b.definitionClass;

    if (b.replacesType != null && b.replacesType != 'void') {
      if (b.replacesNamed != null) {
        return "  container.replace<${b.replacesType}>($defClass());";
      }
      return '  container.replace<${b.replacesType}>($defClass());';
    }
    if (b.typedAs.isNotEmpty) {
      final concreteReg = '  container.register<${b.className}>($defClass());';
      if (b.namedValue != null) {
        // Named + typed: register concrete + named under interface
        final namedRegs = b.typedAs.map((t) =>
          "  container.registerNamed<$t>('${b.namedValue}', $defClass());").join('\n');
        return '$concreteReg\n$namedRegs';
      } else if (b.isPrimary) {
        // Primary + typed: register concrete + primary under interface
        final primaryRegs = b.typedAs.map((t) =>
          '  container.registerPrimary<$t>($defClass());').join('\n');
        return '$concreteReg\n$primaryRegs';
      }
      // Register under both interface AND concrete type
      final interfaceRegs = b.typedAs.map((t) => '  container.register<$t>($defClass());').join('\n');
      return '$concreteReg\n$interfaceRegs';
    }
    if (b.isPrototype) {
      return '  container.registerPrototype<${b.className}>($defClass());';
    } else if (b.isPrimary) {
      return '  container.registerPrimary<${b.className}>($defClass());';
    } else if (b.namedValue != null) {
      return "  container.registerNamed<${b.className}>('${b.namedValue}', $defClass());";
    }
    return '  container.register<${b.className}>($defClass());';
  }

  void _validateGraph(List<_BeanMeta> beans, {Set<String> libraryProvided = const {}}) {
    final registered = beans.map((b) => b.className).toSet();
    // Also register typed-as interfaces
    for (final bean in beans) {
      registered.addAll(bean.typedAs);
    }
    registered.addAll(const ['BeanContainer', 'BootConfig', 'EventBus',
        'TaskScheduler', 'HttpClient', 'HttpClientBuilder',
        'AuthenticationProvider', 'WebSocketServer', 'HealthIndicator',
        'MethodInterceptor']);
    registered.addAll(libraryProvided);

    const ignoredTypes = {'String', 'int', 'double', 'bool', 'num', 'dynamic', 'Object'};

    for (final bean in beans) {
      for (final dep in bean.dependencies) {
        if (ignoredTypes.contains(dep)) continue;
        if (!registered.contains(dep)) {
          log.severe(
            '\n╔══════════════════════════════════════════════════════════════\n'
            '║ MISSING BEAN\n'
            '║\n'
            '║ ${bean.className} requires "$dep" but no bean of that type exists.\n'
            '║\n'
            '║ Possible fixes:\n'
            '║  • Add @Singleton() to the $dep class\n'
            '║  • Produce it from a @Factory method\n'
            '║  • If $dep comes from a library, ensure the library:\n'
            '║    - Has @BootLibrary() on its barrel file\n'
            '║    - Exports boot_module.g.dart\n'
            '║    - Has been built (dart run build_runner build)\n'
            '╚══════════════════════════════════════════════════════════════',
          );
        }
      }
    }

    // ─── Compile-time ambiguity check ────────────────────────────────────────
    // Detect provable conflicts: same type, no @Named, no @Primary, no @Replaces
    final typeCounts = <String, List<_BeanMeta>>{};
    for (final bean in beans) {
      if (bean.namedValue != null) continue;  // Named beans don't conflict
      if (bean.replacesType != null) continue; // @Replaces resolves the conflict
      if (bean.conditions.isNotEmpty) continue; // Conditional beans might not load
      typeCounts.putIfAbsent(bean.className, () => []).add(bean);
    }

    for (final entry in typeCounts.entries) {
      final candidates = entry.value;
      if (candidates.length < 2) continue;
      // Deduplicate by definition class (same definition = same bean, not a conflict)
      final uniqueDefs = candidates.map((b) => b.definitionClass).toSet();
      if (uniqueDefs.length < 2) continue;
      // Check if any is @Primary — that resolves it
      if (candidates.any((b) => b.isPrimary)) continue;
      // Provable conflict
      log.severe(
        '\n╔══════════════════════════════════════════════════════════════\n'
        '║ AMBIGUOUS BEAN\n'
        '║\n'
        '║ Multiple beans of type "${entry.key}" with no qualifier:\n'
        '║   ${uniqueDefs.join(', ')}\n'
        '║\n'
        '║ Fix: Add @Primary to one, @Named to differentiate, or\n'
        '║ @Replaces to explicitly override.\n'
        '╚══════════════════════════════════════════════════════════════',
      );
    }

    // ─── Circular @Requires(beans: [...]) detection ──────────────────────────
    final beansDeps = <String, Set<String>>{};
    for (final bean in beans) {
      final deps = <String>{};
      for (final c in bean.conditions) {
        for (final b in c.beans) deps.add(b.name);
      }
      if (deps.isNotEmpty) beansDeps[bean.className] = deps;
    }
    // Also check typed-as names
    final typeToClass = <String, String>{};
    for (final bean in beans) {
      typeToClass[bean.className] = bean.className;
      for (final t in bean.typedAs) typeToClass[t] = bean.className;
    }
    // Detect cycles
    for (final entry in beansDeps.entries) {
      final visited = <String>{};
      final queue = [entry.key];
      while (queue.isNotEmpty) {
        final current = queue.removeLast();
        if (!visited.add(current)) continue;
        final currentDeps = beansDeps[current];
        if (currentDeps == null) continue;
        for (final dep in currentDeps) {
          final resolved = typeToClass[dep] ?? dep;
          if (resolved == entry.key) {
            throw InvalidGenerationSourceError(
              'Circular @Requires(beans: [...]) dependency detected: '
              '${entry.key} requires $dep, which requires ${entry.key}. '
              'Break the cycle by removing one of the beans conditions.',
            );
          }
          queue.add(resolved);
        }
      }
    }
  }

  List<_BeanMeta> _topologicalSort(List<_BeanMeta> beans) {
    final graph = <String, List<String>>{};
    final beanMap = <String, _BeanMeta>{};

    for (final bean in beans) {
      beanMap[bean.className] = bean;
      final deps = [...bean.dependencies];
      if (bean.replacesType != null && bean.replacesType != 'void') {
        deps.add(bean.replacesType!);
      }
      graph[bean.className] = deps;
    }

    final sorted = <_BeanMeta>[];
    final visited = <String>{};
    final visiting = <String>{};

    void visit(String name) {
      if (visited.contains(name)) return;
      if (visiting.contains(name)) {
        final cycle = [...visiting, name];
        throw StateError(
          '\n╔══════════════════════════════════════════════════════════════\n'
          '║ CIRCULAR DEPENDENCY\n'
          '║\n'
          '║ ${cycle.join(' → ')}\n'
          '║\n'
          '║ Fix: Break the cycle by introducing an interface, using a Provider,\n'
          '║ or restructuring the dependency graph.\n'
          '╚══════════════════════════════════════════════════════════════',
        );
      }

      visiting.add(name);
      for (final dep in graph[name] ?? []) {
        if (beanMap.containsKey(dep)) visit(dep);
      }
      visiting.remove(name);
      visited.add(name);
      if (beanMap.containsKey(name)) sorted.add(beanMap[name]!);
    }

    for (final bean in beans) {
      visit(bean.className);
    }
    return sorted;
  }

  /// Generate the boot_module.g.dart for a @BootLibrary package.
  String _generateModuleOutput(
    String packageName,
    List<_BeanMeta> sorted,
    List<_RouteMeta> routeMeta,
    List<_InterceptorMeta> interceptorMeta, {
    List<_LibraryModule> libraryDeps = const [],
  }) {
    final imports = <String>{};
    for (final bean in sorted) {
      imports.add(bean.import);
      imports.addAll(bean.interfaceImports);
      for (final c in bean.conditions) {
        for (final b in c.beans) if (b.import.isNotEmpty) imports.add(b.import);
        for (final b in c.missingBeans) if (b.import.isNotEmpty) imports.add(b.import);
      }
    }
    for (final route in routeMeta) imports.add(route.import);
    for (final i in interceptorMeta) {
      imports.add(i.import);
      if (i.adviceTypeImport != null) imports.add(i.adviceTypeImport!);
    }

    final importStatements = imports.map((i) => "import '$i';").join('\n');
    final functionName = '\$${_camelCase(packageName)}Module';

    final regs = _buildRegistrations(sorted);
    final registrations = regs.immediate;
    final deferredRegistrations = regs.deferred;

    final routeRegistrations = routeMeta.map((r) =>
      '  router.addAll(${r.routesClass}(container.get<${r.className}>()).routes);').join('\n');
    final interceptorRegistrations = interceptorMeta.map((i) =>
      '  container.registerInterceptor(${i.adviceType}, container.get<${i.className}>());').join('\n');

    final depImports = libraryDeps.map((d) => "import '${d.import}';").join('\n');
    final depCalls = libraryDeps.map((d) =>
      '  ${d.functionName}(container, router, config, deferred);').join('\n');

    return '''
// GENERATED by boot_generator — do not edit.
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:boot/boot.dart';
$importStatements
$depImports

/// Module function for the $packageName library.
/// Called by the consuming app's \$configure() to wire this library's beans.
void $functionName(BeanContainer container, BootRouter router, BootConfig config, List<void Function()> deferred) {
  if (container.hasModule('$packageName')) return;
  container.markModule('$packageName');

$depCalls

$registrations

$deferredRegistrations

$interceptorRegistrations

$routeRegistrations
}
''';
  }

  /// Checks if an element has an annotation that is itself meta-annotated with @BeanSource.
  bool _hasBeanSourceAnnotation(ClassElement element) {
    for (final annotation in element.metadata) {
      final annotationType = annotation.element;
      if (annotationType == null) continue;
      final enclosing = annotationType.enclosingElement3;
      if (enclosing == null) continue;
      if (enclosing is ClassElement) {
        if (_beanSourceChecker.hasAnnotationOf(enclosing)) return true;
        // Check transitively (e.g., @RouteSource has @BeanSource)
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

  /// Checks if an element has an annotation meta-annotated with @RouteSource.
  bool _hasRouteSourceAnnotation(ClassElement element) {
    final routeSourceChecker = TypeChecker.fromRuntime(RouteSource);
    for (final annotation in element.metadata) {
      final annotationType = annotation.element;
      if (annotationType == null) continue;
      final enclosing = annotationType.enclosingElement3;
      if (enclosing == null) continue;
      if (enclosing is ClassElement) {
        if (routeSourceChecker.hasAnnotationOf(enclosing)) return true;
      }
    }
    return false;
  }
}

/// Derives a qualifier name from a class name.
/// `ReadOnlyPool` → `readOnlyPool`, `DiskCache` → `diskCache`.
String _classNameToQualifier(String className) =>
    className[0].toLowerCase() + className.substring(1);

String _camelCase(String s) {
  return s.split(RegExp(r'[_\-]')).map((part) =>
    part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1)
  ).join();
}

class _LibraryModule {
  final String packageName;
  final String functionName;
  final String import;
  _LibraryModule({required this.packageName, required this.functionName, required this.import});
}

class _BeanMeta {
  final String className;
  final String definitionClass;
  final List<String> dependencies;
  final String import;
  final String? namedValue;
  final bool isPrimary;
  final bool isPrototype;
  final List<String> typedAs;
  final List<String> interfaceImports;
  final List<_RequiresCondition> conditions;
  final String? replacesType;
  final String? replacesNamed;
  final bool hasAopProxy;

  _BeanMeta({
    required this.className,
    required this.definitionClass,
    required this.dependencies,
    required this.import,
    this.namedValue,
    this.isPrimary = false,
    this.isPrototype = false,
    this.typedAs = const [],
    this.interfaceImports = const [],
    this.conditions = const [],
    this.replacesType,
    this.replacesNamed,
    this.hasAopProxy = false,
  });
}

class _RequiresCondition {
  final List<String> env;
  final List<String> notEnv;
  final String? property;
  final String? value;
  final String? notEquals;
  final String? defaultValue;
  final String? missingProperty;
  final List<_TypeRef> beans;
  final List<_TypeRef> missingBeans;

  _RequiresCondition({
    this.env = const [],
    this.notEnv = const [],
    this.property,
    this.value,
    this.notEquals,
    this.defaultValue,
    this.missingProperty,
    this.beans = const [],
    this.missingBeans = const [],
  });

  /// Whether this condition requires deferred evaluation (has beans/missingBeans).
  bool get isDeferred => beans.isNotEmpty || missingBeans.isNotEmpty;
}

class _TypeRef {
  final String name;
  final String import;
  _TypeRef({required this.name, required this.import});
}

class _RouteMeta {
  final String className;
  final String routesClass;
  final String import;
  _RouteMeta({required this.className, required this.routesClass, required this.import});
}

class _InterceptorMeta {
  final String className;
  final String adviceType;
  final String import;
  final String? adviceTypeImport;
  _InterceptorMeta({required this.className, required this.adviceType, required this.import, this.adviceTypeImport});
}

