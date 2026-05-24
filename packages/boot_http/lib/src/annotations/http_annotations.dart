// coverage:ignore-file
/// Overrides the default response status code for a controller method.
class Status {
  final int code;
  const Status(this.code);
}

/// Declares the content type(s) produced by a controller method.
/// Default is application/json.
class Produces {
  final List<String> value;
  const Produces(this.value);
}

/// Declares the content type(s) consumed by a controller method.
/// Default is application/json.
class Consumes {
  final List<String> value;
  const Consumes(this.value);
}
