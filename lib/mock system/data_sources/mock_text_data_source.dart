import 'package:flutter/services.dart';

import '../mock_data_exception.dart';

/// Injectable runtime asset text loader, also suitable for in-memory fixtures.
abstract interface class MockTextDataSource {
  Future<String> loadText(String asset);
}

class AssetMockTextDataSource implements MockTextDataSource {
  AssetMockTextDataSource({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<String> loadText(String asset) async {
    try {
      return await _bundle.loadString(asset, cache: false);
    } catch (_) {
      throw MockDataException(
        sourceName: asset,
        message: 'Unable to load asset. Check its presence and pubspec.yaml registration.',
      );
    }
  }
}

/// Optional inventory capability: absence is distinct from a failed read.
abstract interface class MockAssetInventory {
  Set<String> get availableAssets;
}

class InMemoryMockTextDataSource
    implements MockTextDataSource, MockAssetInventory {
  InMemoryMockTextDataSource(Map<String, String> assets)
    : _assets = Map.unmodifiable(assets);

  final Map<String, String> _assets;

  @override
  Set<String> get availableAssets => Set.unmodifiable(_assets.keys);

  @override
  Future<String> loadText(String asset) async {
    if (!_assets.containsKey(asset)) {
      throw MockDataException(
        sourceName: asset,
        message: 'Missing fixture asset.',
      );
    }
    return _assets[asset]!;
  }
}
