// Required public spelling distinguishes presentation content from source data.
// ignore_for_file: non_constant_identifier_names
import 'proudct.dart';
import 'store.dart';

class StoreServiceDisplay {
  StoreServiceDisplay({
    required this.f_label,
    required this.store,
    required List<Proudct> proudcts,
  }) : proudcts = List.unmodifiable(proudcts);

  final String f_label;
  final Store store;
  final List<Proudct> proudcts;

  Map<String, Object?> toJson() => {
    'f_label': f_label,
    'store': store.toJson(),
    'proudcts': proudcts.map((product) => product.toJson()).toList(),
  };
}
