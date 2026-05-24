/// Extracts a path parameter from the request URL.
class PathParam {
  final String? name;
  const PathParam([this.name]);
}

/// Extracts a query parameter from the request URL.
class QueryParam {
  final String? name;
  const QueryParam([this.name]);
}

/// Deserializes the request body into the annotated parameter type.
class Body {
  const Body();
}

/// Extracts an HTTP header value into the annotated parameter.
class Header {
  final String? name;
  const Header([this.name]);
}

/// Extracts a cookie value into the annotated parameter.
class CookieValue {
  final String? name;
  const CookieValue([this.name]);
}
