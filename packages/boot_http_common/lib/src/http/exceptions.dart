/// Base class for HTTP exceptions with a status code.
class HttpException implements Exception {
  final int statusCode;
  final String message;
  const HttpException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class BadRequestException extends HttpException {
  const BadRequestException([String message = 'Bad Request']) : super(400, message);
}

class UnauthorizedException extends HttpException {
  const UnauthorizedException([String message = 'Unauthorized']) : super(401, message);
}

class ForbiddenException extends HttpException {
  const ForbiddenException([String message = 'Forbidden']) : super(403, message);
}

class NotFoundException extends HttpException {
  const NotFoundException([String message = 'Not Found']) : super(404, message);
}

class ConflictException extends HttpException {
  const ConflictException([String message = 'Conflict']) : super(409, message);
}

class UnprocessableException extends HttpException {
  const UnprocessableException([String message = 'Unprocessable Entity']) : super(422, message);
}

class RateLimitException extends HttpException {
  const RateLimitException([String message = 'Too Many Requests']) : super(429, message);
}

class InternalServerException extends HttpException {
  const InternalServerException([String message = 'Internal Server Error']) : super(500, message);
}

class ServiceUnavailableException extends HttpException {
  const ServiceUnavailableException([String message = 'Service Unavailable']) : super(503, message);
}
