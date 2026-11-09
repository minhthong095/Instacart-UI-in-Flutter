// ignore_for_file: non_constant_identifier_names
import 'proudct.dart';

class ProductDisplay {
  ProductDisplay({required this.f_label, required List<Proudct> proudcts})
    : proudcts = List.unmodifiable(proudcts);
  final String f_label;
  final List<Proudct> proudcts;
  Map<String, Object?> toJson() => {
    'f_label': f_label,
    'proudcts': proudcts.map((p) => p.toJson()).toList(),
  };
}
