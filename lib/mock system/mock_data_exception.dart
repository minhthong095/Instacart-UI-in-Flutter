class MockDataException implements Exception {
  const MockDataException({
    required this.sourceName,
    required this.message,
    this.lineNumber,
    this.field,
  });

  final String sourceName;
  final String message;
  final int? lineNumber;
  final String? field;

  @override
  String toString() {
    final line = lineNumber == null ? '' : ', line $lineNumber';
    final fieldName = field == null ? '' : ', field $field';
    return 'MockDataException: $sourceName$line$fieldName: $message';
  }
}
