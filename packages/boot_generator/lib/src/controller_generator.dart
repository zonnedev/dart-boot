import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:boot_serialization/boot_serialization.dart';
import 'package:boot_http/boot_http.dart';
import 'package:boot_http/boot_http.dart';

import 'package:boot_http/boot_http.dart';



final _pathParamChecker = TypeChecker.fromRuntime(PathParam);
final _queryParamChecker = TypeChecker.fromRuntime(QueryParam);
final _bodyChecker = TypeChecker.fromRuntime(Body);
final _headerChecker = TypeChecker.fromRuntime(Header);
final _cookieChecker = TypeChecker.fromRuntime(CookieValue);
final _getChecker = TypeChecker.fromRuntime(Get);
final _postChecker = TypeChecker.fromRuntime(Post);
final _putChecker = TypeChecker.fromRuntime(Put);
final _deleteChecker = TypeChecker.fromRuntime(Delete);
final _patchChecker = TypeChecker.fromRuntime(Patch);
final _requestChecker = TypeChecker.fromRuntime(Request);
final _responseChecker = TypeChecker.fromRuntime(Response);
final _authenticationChecker = TypeChecker.fromRuntime(Authentication);

final _routeCheckers = {
  'GET': _getChecker,
  'POST': _postChecker,
  'PUT': _putChecker,
  'DELETE': _deleteChecker,
  'PATCH': _patchChecker,
};

/// Generates route registration code for @Controller annotated classes.
class ControllerGenerator extends GeneratorForAnnotation<Controller> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@Controller can only be applied to classes.',
        element: element,
      );
    }

    final className = element.name;
    final pathField = annotation.peek('path');
    final basePath = (pathField != null && !pathField.isNull)
        ? pathField.stringValue
        : '/${_classNameToPath(className)}';

    final routes = <String>[];

    for (final method in element.methods) {
      final routeInfo = _extractRoute(method);
      if (routeInfo == null) continue;

      final (httpMethod, path) = routeInfo;
      final fullPath = '$basePath$path';
      final handlerCode = _buildHandler(method, className);

      routes.add('''
    RouteEntry(
      method: '$httpMethod',
      path: '$fullPath',
      handler: $handlerCode,
    )''');
    }

    if (routes.isEmpty) {
      throw InvalidGenerationSourceError(
        '@Controller class "${element.name}" has no route methods. '
        'Add at least one method annotated with @Get, @Post, @Put, @Delete, or @Patch.',
        element: element,
      );
    }

    return '''
class \$${className}Routes implements RouteRegistration {
  final $className controller;
  \$${className}Routes(this.controller);

  @override
  List<RouteEntry> get routes => [
${routes.join(',\n')},
  ];
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

  String _buildHandler(MethodElement method, String className) {
    final returnType = method.returnType;
    final params = method.parameters;

    final paramExtraction = <String>[];
    final callArgs = <String>[];

    for (final param in params) {
      if (_pathParamChecker.hasAnnotationOf(param)) {
        final annotation = _pathParamChecker.firstAnnotationOf(param)!;
        final name = annotation.getField('name')?.toStringValue() ?? param.name;
        paramExtraction.add(
            "final ${param.name} = request.pathParams['$name']!;");
        callArgs.add(param.name);
      } else if (_queryParamChecker.hasAnnotationOf(param)) {
        final annotation = _queryParamChecker.firstAnnotationOf(param)!;
        final name = annotation.getField('name')?.toStringValue() ?? param.name;
        final isNullable = param.type.nullabilitySuffix != NullabilitySuffix.none;
        if (isNullable) {
          paramExtraction.add(
              "final ${param.name} = request.queryParams['$name'];");
        } else {
          paramExtraction.add(
              "final ${param.name} = request.queryParams['$name'];\n"
              "        if (${param.name} == null) return Response(400, headers: {'content-type': 'application/json'}, body: '{\"error\":\"Missing required query parameter: $name\"}');");
        }
        callArgs.add(param.name);
      } else if (_headerChecker.hasAnnotationOf(param)) {
        final annotation = _headerChecker.firstAnnotationOf(param)!;
        final name = annotation.getField('name')?.toStringValue() ??
            _toHeaderCase(param.name);
        final isNullable = param.type.nullabilitySuffix != NullabilitySuffix.none;
        if (isNullable) {
          paramExtraction.add(
              "final ${param.name} = request.headers['$name'];");
        } else {
          paramExtraction.add(
              "final ${param.name} = request.headers['$name'];\n"
              "        if (${param.name} == null) return Response(400, headers: {'content-type': 'application/json'}, body: '{\"error\":\"Missing required header: $name\"}');");
        }
        callArgs.add(param.name);
      } else if (_cookieChecker.hasAnnotationOf(param)) {
        final annotation = _cookieChecker.firstAnnotationOf(param)!;
        final name = annotation.getField('name')?.toStringValue() ?? param.name;
        final isNullable = param.type.nullabilitySuffix != NullabilitySuffix.none;
        if (isNullable) {
          paramExtraction.add(
              "final ${param.name} = request.headers['cookie']?.split('; ').where((c) => c.startsWith('$name=')).map((c) => c.substring(${name.length + 1})).firstOrNull;");
        } else {
          paramExtraction.add(
              "final ${param.name} = request.headers['cookie']?.split('; ').where((c) => c.startsWith('$name=')).map((c) => c.substring(${name.length + 1})).firstOrNull;\n"
              "        if (${param.name} == null) return Response(400, headers: {'content-type': 'application/json'}, body: '{\"error\":\"Missing required cookie: $name\"}');");
        }
        callArgs.add(param.name);
      } else if (_bodyChecker.hasAnnotationOf(param)) {
        final paramType = param.type;
        if (paramType.isDartCoreString) {
          paramExtraction.add('final ${param.name} = await request.body();');
        } else if (paramType.isDartCoreMap) {
          paramExtraction.add('final ${param.name} = await request.json();');
        } else {
          // Validate the type has fromJson (via @Serdeable or @Deserializable)
          final typeName = paramType.getDisplayString();
          if (paramType is InterfaceType) {
            final hasFromJson = paramType.element.constructors.any((c) => c.name == 'fromJson') ||
                paramType.element.methods.any((m) => m.name == 'fromJson');
            final hasSerde = paramType.element.metadata.any((m) {
              final name = m.element?.enclosingElement3?.name;
              return name == 'Serdeable' || name == 'Deserializable';
            });
            if (!hasFromJson && !hasSerde) {
              throw InvalidGenerationSourceError(
                '@Body parameter "${param.name}" has type "$typeName" which is not '
                'annotated with @Serdeable or @Deserializable. '
                'Add @Serdeable() or @Deserializable() to $typeName.',
                element: param,
              );
            }
          }
          paramExtraction.add(
              'final ${param.name} = \$${typeName}FromJson(await request.json());');
        }
        callArgs.add(param.name);
      } else if (_requestChecker.isExactlyType(param.type)) {
        callArgs.add('request');
      } else if (_authenticationChecker.isAssignableFromType(param.type)) {
        final isNullable = param.type.nullabilitySuffix != NullabilitySuffix.none;
        if (!isNullable) {
          paramExtraction.add(
              "final ${param.name} = request.authentication;\n"
              "        if (${param.name} == null) return Response(401, headers: {'content-type': 'application/json'}, body: '{\"error\":\"Unauthorized\"}');");
        } else {
          paramExtraction.add(
              'final ${param.name} = request.authentication;');
        }
        callArgs.add(param.name);
      }
    }

    final extraction = paramExtraction.isNotEmpty
        ? '${paramExtraction.join('\n        ')}\n        '
        : '';
    final args = callArgs.join(', ');

    if (_isResponse(returnType)) {
      return '(request) async {\n        ${extraction}return await controller.${method.name}($args);\n      }';
    }

    // Stream<SseEvent> → Server-Sent Events
    if (_isStream(returnType)) {
      final streamType = _unwrapStream(returnType);
      if (streamType != null && streamType.getDisplayString() == 'SseEvent') {
        return '(request) async {\n        ${extraction}final stream = controller.${method.name}($args);\n'
            '        final body = stream.map((e) => e.encode());\n'
            '        return Response(200, headers: {\'content-type\': \'text/event-stream\', \'cache-control\': \'no-cache\', \'connection\': \'keep-alive\'}, body: await body.join());\n      }';
      }
      // Stream<List<int>> → chunked binary response
      return '(request) async {\n        ${extraction}final stream = controller.${method.name}($args);\n'
          '        return Response(200, headers: {\'content-type\': \'application/octet-stream\'}, bodyStream: stream);\n      }';
    }

    // Auto-serialize: verify toJson() exists on the return type
    final innerType = _unwrapFuture(returnType);

    // void → 204 No Content
    if (innerType is VoidType) {
      if (_isFuture(returnType)) {
        return '(request) async {\n        ${extraction}await controller.${method.name}($args);\n        return Response.noContent();\n      }';
      }
      return '(request) async {\n        ${extraction}controller.${method.name}($args);\n        return Response.noContent();\n      }';
    }

    // String → 200 text/plain
    if (innerType.isDartCoreString) {
      if (_isFuture(returnType)) {
        return '(request) async {\n        ${extraction}final result = await controller.${method.name}($args);\n        return Response.text(result);\n      }';
      }
      return '(request) async {\n        ${extraction}final result = controller.${method.name}($args);\n        return Response.text(result);\n      }';
    }

    final hasToJson = _hasToJsonMethod(innerType);
    final hasSerializable = innerType is InterfaceType &&
        TypeChecker.fromRuntime(Serializable).hasAnnotationOf(innerType.element);

    if (!hasToJson && !hasSerializable && !_isPrimitive(innerType)) {
      throw InvalidGenerationSourceError(
        'Controller method "${method.name}" returns "${returnType.getDisplayString()}" '
        'which does not have a toJson() method. '
        'Either return Response, annotate the return type with @Serializable(), '
        'or add a toJson() method manually.',
        element: method,
      );
    }

    final serialize = (hasToJson || hasSerializable) ? 'result.toJson()' : 'result';

    if (_isFuture(returnType)) {
      return '(request) async {\n        ${extraction}final result = await controller.${method.name}($args);\n        return Response.json(result is Map || result is List ? result : $serialize);\n      }';
    }

    return '(request) async {\n        ${extraction}final result = controller.${method.name}($args);\n        return Response.json(result is Map || result is List ? result : $serialize);\n      }';
  }

  bool _isResponse(DartType type) {
    if (_responseChecker.isExactlyType(type)) return true;
    if (type.isDartAsyncFuture && type is InterfaceType) {
      return _responseChecker.isExactlyType(type.typeArguments.first);
    }
    return false;
  }

  bool _isFuture(DartType type) => type.isDartAsyncFuture;

  bool _isStream(DartType type) => type.isDartAsyncStream;

  DartType? _unwrapStream(DartType type) {
    if (type is InterfaceType && type.isDartAsyncStream) {
      return type.typeArguments.first;
    }
    return null;
  }

  DartType _unwrapFuture(DartType type) {
    if (type is InterfaceType && type.isDartAsyncFuture) {
      return type.typeArguments.first;
    }
    return type;
  }

  bool _hasToJsonMethod(DartType type) {
    if (type is InterfaceType) {
      return type.element.methods.any((m) => m.name == 'toJson') ||
          type.isDartCoreMap ||
          type.isDartCoreList;
    }
    return false;
  }

  bool _isPrimitive(DartType type) {
    return type is VoidType ||
        type.isDartCoreString ||
        type.isDartCoreInt ||
        type.isDartCoreDouble ||
        type.isDartCoreBool ||
        type is DynamicType ||
        type.isDartCoreMap ||
        type.isDartCoreList;
  }

  /// Convert camelCase param name to HTTP header case: contentType → content-type
  String _toHeaderCase(String name) {
    return name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '-${m.group(0)!.toLowerCase()}',
    );
  }
}

/// Derives a URL path from a controller class name.
/// `UserController` → `user`, `OrderItemController` → `order-item`.
String _classNameToPath(String className) {
  // Remove 'Controller' suffix
  var name = className.endsWith('Controller')
      ? className.substring(0, className.length - 10)
      : className;
  // Convert PascalCase to kebab-case
  return name
      .replaceAllMapped(RegExp(r'[A-Z]'), (m) => '-${m.group(0)!.toLowerCase()}')
      .substring(1); // remove leading hyphen
}
