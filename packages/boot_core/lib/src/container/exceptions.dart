/// Thrown when a requested bean type is not registered.
class BeanNotFoundException implements Exception {
  final Type type;
  final String? name;
  BeanNotFoundException(this.type, {this.name});

  @override
  String toString() => name != null
      ? 'BeanNotFoundException: No bean registered for type $type with name "$name"'
      : 'BeanNotFoundException: No bean registered for type $type';
}

/// Thrown when a circular dependency is detected at runtime.
class CircularDependencyException implements Exception {
  final List<Type> chain;
  CircularDependencyException(this.chain);

  @override
  String toString() =>
      'CircularDependencyException: ${chain.map((t) => t.toString()).join(' -> ')}';
}

/// Thrown when multiple beans match an injection point with no qualifier or @Primary.
class NonUniqueBeanException implements Exception {
  final Type type;
  final List<String> candidates;
  NonUniqueBeanException(this.type, this.candidates);

  @override
  String toString() =>
      'NonUniqueBeanException: Multiple beans of type $type found: '
      '${candidates.join(', ')}. Use @Named, @Primary, or inject List<$type>.';
}
