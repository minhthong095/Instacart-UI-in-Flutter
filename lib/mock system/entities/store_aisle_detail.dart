import 'aisle_sub.dart';
import 'store_aisle.dart';

class StoreAisleDetail extends StoreAisle {
  StoreAisleDetail.fromRecord(
    super.record, {
    required super.shopId,
    required List<AisleSub> sub,
  }) : sub = List.unmodifiable(sub),
       super.fromRecord();
  final List<AisleSub> sub;
  @override
  Map<String, Object?> toJson() => {
    ...toSourceJson(),
    'sub': sub.map((s) => s.toJson()).toList(),
  };
}
