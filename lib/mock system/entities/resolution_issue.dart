import '../data_sources/json_support.dart';

/// Inspectable response diagnostics. [source] is the request/membership location;
/// [matches] contains all detail rows when duplicate records were encountered.
class ResolutionIssue {
  ResolutionIssue(
    this.code,
    this.source, {
    this.productId,
    List<SourceLocation> matches = const [],
  }) : matches = List.unmodifiable(matches);
  final String code;
  final SourceLocation source;
  final String? productId;
  final List<SourceLocation> matches;
  Map<String, Object?> toJson() => {
    'code': code,
    'shopId': source.shopId,
    'productId': productId,
    'asset': source.asset,
    'line': source.line,
    'path': source.path,
    'matches': [
      for (final s in matches)
        {'asset': s.asset, 'line': s.line, 'path': s.path},
    ],
  };
}

typedef DiagnosticSink = void Function(ResolutionIssue issue);
