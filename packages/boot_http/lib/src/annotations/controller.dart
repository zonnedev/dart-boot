// coverage:ignore-file
import 'package:boot_core/boot_core.dart';

/// Marks a class as an HTTP controller with a base path.
///
/// If [path] is omitted, it is derived from the class name:
/// `UserController` → `/user`, `OrderItemController` → `/order-item`.
@RouteSource()
class Controller {
  final String? path;

  const Controller([this.path]);
}
