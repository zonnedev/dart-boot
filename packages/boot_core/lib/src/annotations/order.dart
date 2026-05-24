/// Controls the ordering of beans, interceptors, or filters.
/// Lower values have higher priority (execute first).
/// Default is 0.
class Order {
  final int value;
  const Order(this.value);
}
