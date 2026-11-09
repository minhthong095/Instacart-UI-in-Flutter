import 'dart:convert';
import 'dart:math';

import '../mock_config.dart';

/// Stable 31-bit polynomial hash of a structured seed/identity tuple. Unlike
/// String.hashCode, its definition does not depend on a Dart runtime hash salt.
Random identityRandom(int seed, List<String> identity) {
  var hash = 0;
  for (final unit in jsonEncode([seed, ...identity]).codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return Random(hash);
}

class ProductFakeFields {
  ProductFakeFields(Random random)
    : purchaseHistory = random.nextInt(MockConfig.nullableOneIn) == 0
          ? null
          : MockConfig.minPurchaseHistory +
                random.nextInt(
                  MockConfig.maxPurchaseHistory -
                      MockConfig.minPurchaseHistory +
                      1,
                ),
      isManyInStock = random.nextBool(),
      freeText = random.nextInt(MockConfig.nullableOneIn) == 0
          ? null
          : MockConfig.foodLabels[random.nextInt(MockConfig.foodLabels.length)];
  final int? purchaseHistory;
  final bool isManyInStock;
  final String? freeText;
}
