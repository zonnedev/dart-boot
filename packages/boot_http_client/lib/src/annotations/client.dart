// coverage:ignore-file
/// Declares a compile-time generated HTTP client from an interface.
///
/// Use either a URL or a name (service ID), not both:
///   @Client('https://api.example.com')       → inline URL, global HttpClient
///   @Client(name: 'payments')                → URL + config from YAML
///
/// The generator produces an implementation that makes real HTTP calls
/// based on the route annotations (@Get, @Post, etc.) on the interface methods.
class Client {
  /// The base URL (mutually exclusive with [name]).
  final String? url;

  /// Service name — resolves URL and config from boot.http.services.<name>.
  /// If a @Named('<name>') HttpClient bean exists, uses that instead.
  final String? name;

  /// Optional base path appended to the URL.
  final String path;

  const Client({this.url, this.name, this.path = ''});
}
