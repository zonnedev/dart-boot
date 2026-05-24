class TodoLimitException implements Exception {
  final int currentCount;
  final int maxAllowed;

  TodoLimitException({required this.currentCount, required this.maxAllowed});

  @override
  String toString() => 'Todo limit reached: $currentCount/$maxAllowed';
}
