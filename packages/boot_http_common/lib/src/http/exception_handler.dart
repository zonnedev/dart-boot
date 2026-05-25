import 'package:boot_core/boot_core.dart';

import 'request.dart';
import 'response.dart';

/// AnnotationType constant for runtime metadata queries.
const exceptionHandlerAnnotationType = AnnotationType(
    'package:boot_http_common/src/http/exception_handler.dart#ExceptionHandler');

/// Implement this interface to handle a specific exception/error type.
/// Register as a @Singleton — Boot auto-discovers and routes exceptions to the matching handler.
///
/// Example:
/// ```dart
/// @Singleton()
/// class NotFoundHandler implements ExceptionHandler<NotFoundException> {
///   @override
///   Response handle(Request request, NotFoundException e) {
///     return Response.notFound(e.message);
///   }
/// }
/// ```
abstract class ExceptionHandler<E> {
  Response handle(Request request, E exception);
}
