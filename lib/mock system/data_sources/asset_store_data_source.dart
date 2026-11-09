import 'package:flutter/services.dart';

import '../mock_config.dart';
import '../mock_data_exception.dart';
import 'store_data_source.dart';

class AssetStoreDataSource implements StoreDataSource {
  AssetStoreDataSource({
    this.sourceName = MockConfig.storeAsset,
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  final String sourceName;

  @override
  Future<String> loadStoresText() async {
    try {
      return await _bundle.loadString(sourceName, cache: false);
    } catch (_) {
      throw MockDataException(
        sourceName: sourceName,
        message:
            'Unable to load store asset. Check its pubspec.yaml registration.',
      );
    }
  }
}
