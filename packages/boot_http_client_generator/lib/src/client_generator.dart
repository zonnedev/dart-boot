import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:boot_http_client/boot_http_client.dart';
import 'package:boot_http/boot_http.dart';

// TODO: resilience moved - import when boot_resilience package exists

final _pathParamChecker = TypeChecker.fromRuntime(PathParam);
final _queryParamChecker = TypeChecker.fromRuntime(QueryParam);
final _headerChecker = TypeChecker.fromRuntime(Header);
final _cookieChecker = TypeChecker.fromRuntime(CookieValue);
// final _retryChecker = TypeChecker.fromRuntime(Retry); // TODO: boot_resilience
// final _circuitBreakerChecker = TypeChecker.fromRuntime(CircuitBreaker); // TODO: boot_resilience
final _bodyChecker = TypeChecker.fromRuntime(Body);
final _getChecker = TypeChecker.fromRuntime(Get);
final _postChecker = TypeChecker.fromRuntime(Post);
final _putChecker = TypeChecker.fromRuntime(Put);
final _deleteChecker = TypeChecker.fromRuntime(Delete);
final _patchChecker = TypeChecker.fromRuntime(Patch);

final _routeCheckers = {
  'GET': _getChecker,
  'POST': _postChecker,
  'PUT': _putChecker,
  'DELETE': _deleteChecker,
  'PATCH': _patchChecker,
};

/// Generates HTTP client implementations from @Client annotated interfaces.
class ClientGenerator extends GeneratorForAnnotation<Client> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@Client can only be applied to abstract classes.',
        element: element,
      );
    }

    final className = element.name;
    final url = annotation.peek('url')?.stringValue;
    final name = annotation.peek('name')?.stringValue;
    final basePath = annotation.read('path').stringValue;

    // Build-time validation: url + name = error
    if (url != null && url.isNotEmpty && name != null && name.isNotEmpty) {
      throw InvalidGenerationSourceError(
        '@Client class "$className" specifies both url and name. '
        'Use one or the other:\n'
        "  @Client(name: '$name')        → URL from boot.http.services.$name.url\n"
        "  @Client(url: '$url')  → URL inline, uses global HttpClient",
        element: element,
      );
    }

    if ((url == null || url.isEmpty) && (name == null || name.isEmpty)) {
      throw InvalidGenerationSourceError(
        '@Client class "$className" must specify either url or name.',
        element: element,
      );
    }

    final methods = StringBuffer();

    // Collect all methods from the class and its interfaces
    final allMethods = <MethodElement>[
      ...element.methods,
      for (final iface in element.interfaces) ...iface.element.methods,
    ];

    for (final method in allMethods) {
      final routeInfo = _extractRoute(method);
      if (routeInfo == null) continue;

      final (httpMethod, routePath) = routeInfo;
      methods.writeln(_generateMethod(method, httpMethod, routePath));
    }

    // Generate different constructors based on name vs url
    if (name != null && name.isNotEmpty) {
      // Named client — resolve from container (named HttpClient bean or named builder)
      return '''
class \$${className}Impl implements $className {
  final HttpClient _client;
  final String _baseUrl;

  \$${className}Impl(BeanContainer container)
      : _client = container.hasNamed<HttpClient>('$name')
            ? container.getNamed<HttpClient>('$name')
            : container.getNamed<HttpClientBuilder>('$name').build(),
        _baseUrl = '${basePath}';

$methods}

class \$${className}Definition extends BeanDefinition {
  @override
  String get typeName => '$className';

  @override
  $className create(BeanContainer container) =>
      \$${className}Impl(container);
}
''';
    } else {
      // URL-based client — uses global HttpClient
      return '''
class \$${className}Impl implements $className {
  final HttpClient _client;
  final String _baseUrl;

  \$${className}Impl(this._client) : _baseUrl = '$url$basePath';

$methods}

class \$${className}Definition extends BeanDefinition {
  @override
  String get typeName => '$className';

  @override
  $className create(BeanContainer container) =>
      \$${className}Impl(container.get<HttpClient>());
}
''';
    }
  }

  String _generateMethod(MethodElement method, String httpMethod, String routePath) {
    final returnType = method.returnType;
    final params = method.parameters;

    // Build URL with path params interpolated
    var urlExpr = "'\$_baseUrl$routePath'";
    final queryParams = <String>[];
    final headerLines = <String>[];
    String? bodyExpr;

    for (final param in params) {
      if (_pathParamChecker.hasAnnotationOf(param)) {
        final annotation = _pathParamChecker.firstAnnotationOf(param)!;
        final name = annotation.getField('name')?.toStringValue() ?? param.name;
        urlExpr = urlExpr.replaceAll('<$name>', '\${${param.name}}');
      } else if (_queryParamChecker.hasAnnotationOf(param)) {
        final annotation = _queryParamChecker.firstAnnotationOf(param)!;
        final name = annotation.getField('name')?.toStringValue() ?? param.name;
        queryParams.add("'$name': ${param.name}.toString()");
      } else if (_headerChecker.hasAnnotationOf(param)) {
        final annotation = _headerChecker.firstAnnotationOf(param)!;
        final name = annotation.getField('name')?.toStringValue() ?? param.name;
        headerLines.add("      '$name': ${param.name},");
      } else if (_cookieChecker.hasAnnotationOf(param)) {
        final annotation = _cookieChecker.firstAnnotationOf(param)!;
        final name = annotation.getField('name')?.toStringValue() ?? param.name;
        headerLines.add("      'cookie': '$name=\${${param.name}}',");
      } else if (_bodyChecker.hasAnnotationOf(param)) {
        final paramType = param.type;
        if (paramType.isDartCoreString) {
          bodyExpr = param.name;
        } else if (paramType.isDartCoreMap) {
          bodyExpr = param.name;
        } else {
          // Validate @Body type has toJson (via @Serdeable or @Serializable)
          if (paramType is InterfaceType) {
            final hasToJson = paramType.element.methods.any((m) => m.name == 'toJson');
            final hasSerde = paramType.element.metadata.any((m) {
              final name = m.element?.enclosingElement3?.name;
              return name == 'Serdeable' || name == 'Serializable';
            });
            if (!hasToJson && !hasSerde) {
              throw InvalidGenerationSourceError(
                '@Body parameter "${param.name}" has type "${paramType.getDisplayString()}" '
                'which is not annotated with @Serdeable or @Serializable. '
                'Add @Serdeable() or @Serializable() to ${paramType.getDisplayString()}.',
                element: param,
              );
            }
          }
          bodyExpr = '${param.name}.toJson()';
        }
      }
    }

    // Build query string
    if (queryParams.isNotEmpty) {
      urlExpr = "$urlExpr?\${Uri(queryParameters: {${queryParams.join(', ')}}).query}";
    }

    // Build param list
    final paramList = params
        .map((p) => '${p.type.getDisplayString()} ${p.name}')
        .join(', ');

    // Build headers map
    final headersExpr = headerLines.isNotEmpty
        ? 'headers: {\n${headerLines.join('\n')}\n    },'
        : '';

    // Build body
    final bodyArgExpr = bodyExpr != null ? 'body: $bodyExpr,' : '';

    // Determine return type handling
    final innerType = _unwrapFuture(returnType);
    final returnTypeName = returnType.getDisplayString();

    String responseHandling;
    if (innerType is VoidType) {
      responseHandling = '';
    } else if (innerType.isDartCoreString) {
      responseHandling = '    return response.body;';
    } else if (innerType.isDartCoreMap) {
      responseHandling = '    return response.json;';
    } else if (innerType.isDartCoreList) {
      // Get the list's type argument for proper casting
      final listTypeArg = (innerType is InterfaceType && innerType.typeArguments.isNotEmpty)
          ? innerType.typeArguments.first.getDisplayString()
          : 'dynamic';
      if (listTypeArg == 'dynamic' || listTypeArg == 'Map<String, dynamic>') {
        responseHandling = '    return List<Map<String, dynamic>>.from(response.jsonList);';
      } else {
        responseHandling = '    return response.jsonList.map((e) => \$${listTypeArg}FromJson(e as Map<String, dynamic>)).toList();';
      }
    } else {
      // POJO — validate it has @Serdeable or @Deserializable
      final typeName = innerType.getDisplayString();
      if (innerType is InterfaceType) {
        final hasFromJson = innerType.element.constructors.any((c) => c.name == 'fromJson') ||
            innerType.element.methods.any((m) => m.name == 'fromJson');
        final hasSerde = innerType.element.metadata.any((m) {
          final name = m.element?.enclosingElement3?.name;
          return name == 'Serdeable' || name == 'Deserializable';
        });
        if (!hasFromJson && !hasSerde) {
          throw InvalidGenerationSourceError(
            'Client method "${method.name}" returns "$typeName" which is not '
            'annotated with @Serdeable or @Deserializable. '
            'Add @Serdeable() or @Deserializable() to $typeName.',
            element: method,
          );
        }
      }
      responseHandling = '    return \$${typeName}FromJson(response.json);';
    }

    // Detect @Retry and @CircuitBreaker
    // final null /*retryAnnotation*/ = _retryChecker.firstAnnotationOf(method); // TODO: boot_resilience
    // final null /*cbAnnotation*/ = _circuitBreakerChecker.firstAnnotationOf(method); // TODO: boot_resilience

    var callExpr = '''await _client.send(
      '$httpMethod',
      $urlExpr,
      $headersExpr
      $bodyArgExpr
    )''';

    final cbField = '';

    return '''
$cbField  @override
  $returnTypeName ${method.name}($paramList) async {
    final response = $callExpr;
$responseHandling
  }
''';
  }

  (String, String)? _extractRoute(MethodElement method) {
    for (final entry in _routeCheckers.entries) {
      final annotation = entry.value.firstAnnotationOf(method);
      if (annotation != null) {
        final path = annotation.getField('path')?.toStringValue() ?? '';
        return (entry.key, path);
      }
    }
    return null;
  }

  DartType _unwrapFuture(DartType type) {
    if (type is InterfaceType && type.isDartAsyncFuture) {
      return type.typeArguments.first;
    }
    return type;
  }
}
