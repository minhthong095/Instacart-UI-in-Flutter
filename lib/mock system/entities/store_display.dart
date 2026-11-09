// Required API field name marks mock presentation content.
// ignore_for_file: non_constant_identifier_names

import 'store.dart';

class StoreDisplay {
  StoreDisplay({required this.f_label, required List<Store> store})
    : store = List.unmodifiable(store);

  final String f_label;
  final List<Store> store;

  Map<String, Object?> toJson() => {
    'f_label': f_label,
    'store': store.map((value) => value.toJson()).toList(),
  };
}
