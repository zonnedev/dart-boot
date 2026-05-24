import 'request.dart';
import 'response.dart';

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
