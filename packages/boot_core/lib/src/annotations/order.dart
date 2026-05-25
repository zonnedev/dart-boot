// coverage:ignore-file
import 'package:boot_core/src/container/annotation_metadata.dart';

/// AnnotationType constant for runtime metadata queries.
const orderAnnotationType = AnnotationType(
    'package:boot_core/src/annotations/order.dart#Order');

/// Controls the ordering of beans, interceptors, or filters.
/// Lower values have higher priority (execute first).
/// Default is 0.
class Order {
  final int value;
  const Order(this.value);
}
