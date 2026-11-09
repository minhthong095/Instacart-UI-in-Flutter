abstract interface class StoreDataSource {
  String get sourceName;
  Future<String> loadStoresText();
}

class InMemoryStoreDataSource implements StoreDataSource {
  const InMemoryStoreDataSource(
    this.text, {
    this.sourceName = 'in-memory.jsonl',
  });

  final String text;

  @override
  final String sourceName;

  @override
  Future<String> loadStoresText() async => text;
}
