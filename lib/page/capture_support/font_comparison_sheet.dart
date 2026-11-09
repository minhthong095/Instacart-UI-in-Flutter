import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A manifest-backed face. Only declared, readable assets are offered as choices.
class FontComparisonFace {
  const FontComparisonFace({
    required this.family,
    required this.weights,
    this.style = FontStyle.normal,
  });

  final String family;
  final List<FontWeight> weights;
  final FontStyle style;
}

class FontComparisonInventory {
  const FontComparisonInventory({
    required this.faces,
    this.unavailable = const [],
  });

  final List<FontComparisonFace> faces;
  final List<String> unavailable;

  /// Read the built app's manifest, not a guessed family list. Missing files and
  /// requested families are reported. No font downloads or synthetic weights.
  static Future<FontComparisonInventory> load({
    List<String>? families,
    AssetBundle? bundle,
  }) async {
    final assets = bundle ?? rootBundle;
    final manifest = jsonDecode(
      await assets.loadString('FontManifest.json'),
    ) as List<dynamic>;
    final requested = families?.toSet();
    final seen = <String>{};
    final weights = <(String, FontStyle), Set<FontWeight>>{};
    final unavailable = <String>[];
    for (final entry in manifest.cast<Map<String, dynamic>>()) {
      final family = entry['family'] as String;
      if (requested != null && !requested.contains(family)) continue;
      seen.add(family);
      for (final font
          in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
        final numericWeight = (font['weight'] as num?)?.toInt() ?? 400;
        final style = font['style'] == 'italic'
            ? FontStyle.italic
            : FontStyle.normal;
        if (numericWeight < 100 ||
            numericWeight > 900 ||
            numericWeight % 100 != 0) {
          unavailable.add(
            '$family: unsupported declared weight $numericWeight',
          );
          continue;
        }
        final asset = font['asset'] as String;
        try {
          final bytes = await assets.load(asset);
          if (bytes.lengthInBytes == 0) throw StateError('Empty font asset');
          weights
              .putIfAbsent((family, style), () => <FontWeight>{})
              .add(FontWeight.values[numericWeight ~/ 100 - 1]);
        } catch (_) {
          unavailable.add('$family / $numericWeight / ${style.name}: $asset');
        }
      }
    }
    if (requested != null) {
      unavailable.addAll(
        requested.difference(seen).map((name) => '$name: not in FontManifest'),
      );
    }
    return FontComparisonInventory(
      faces: [
        for (final entry in weights.entries)
          FontComparisonFace(
            family: entry.key.$1,
            style: entry.key.$2,
            weights: entry.value.toList()
              ..sort((a, b) => a.value.compareTo(b.value)),
          ),
      ],
      unavailable: unavailable,
    );
  }
}

class FontComparisonVariant {
  const FontComparisonVariant({
    required this.family,
    required this.size,
    required this.weight,
    this.style = FontStyle.normal,
    this.height,
    this.letterSpacing = 0,
  });

  final String family;
  final double size;
  final FontWeight weight;
  final FontStyle style;
  final double? height;
  final double letterSpacing;

  TextStyle get textStyle => TextStyle(
    inherit: false,
    color: const Color(0xFF222222),
    fontFamily: family,
    fontFamilyFallback: const [],
    fontSize: size,
    fontWeight: weight,
    fontStyle: style,
    height: height,
    letterSpacing: letterSpacing,
  );
}

class FontComparisonSample {
  const FontComparisonSample({
    required this.id,
    required this.text,
    this.width,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign = TextAlign.start,
  });

  final String id;
  final String text;
  final double? width;
  final int? maxLines;
  final TextOverflow overflow;
  final TextAlign textAlign;
}

/// Fully built content for CaptureHost.eager; this widget owns no scroll view,
/// app, navigator, theme, or capture backend. Keep candidate batches small.
class FontComparisonSheet extends StatelessWidget {
  const FontComparisonSheet({
    super.key,
    required this.inventory,
    required this.variants,
    required this.samples,
  });

  final FontComparisonInventory inventory;
  final List<FontComparisonVariant> variants;
  final List<FontComparisonSample> samples;

  void _validate() {
    if (variants.isEmpty || samples.isEmpty) {
      throw ArgumentError('Provide at least one variant and one text sample.');
    }
    for (final variant in variants) {
      if (!variant.size.isFinite ||
          variant.size <= 0 ||
          !variant.letterSpacing.isFinite ||
          (variant.height != null &&
              (!variant.height!.isFinite || variant.height! <= 0))) {
        throw ArgumentError('Invalid size, height, or letter spacing.');
      }
      if (!inventory.faces.any(
        (face) =>
            face.family == variant.family &&
            face.style == variant.style &&
            face.weights.contains(variant.weight),
      )) {
        throw ArgumentError(
          'Unavailable face: ${variant.family} '
          '${variant.weight.value} ${variant.style.name}.',
        );
      }
    }
    for (final sample in samples) {
      if ((sample.width != null &&
              (!sample.width!.isFinite || sample.width! <= 0)) ||
          (sample.maxLines != null && sample.maxLines! <= 0)) {
        throw ArgumentError('Invalid sample width or maxLines.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _validate();
    final metrics = MediaQuery.of(context);
    final locale = Localizations.maybeLocaleOf(context);
    final direction = Directionality.of(context);
    return ColoredBox(
      color: const Color(0xFFFFFFFF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Font comparison — actual Flutter text'),
            _label(
              'DPR ${metrics.devicePixelRatio} · '
              'scaled 16 = ${metrics.textScaler.scale(16)} · '
              '${locale ?? "platform locale"} · ${direction.name}',
            ),
            if (inventory.unavailable.isNotEmpty)
              _label('Unavailable: ${inventory.unavailable.join("; ")}'),
            for (var index = 0; index < variants.length; index++) ...[
              const SizedBox(height: 24),
              _label(
                '${index + 1}. ${variants[index].family} · '
                '${variants[index].size} · w${variants[index].weight.value} · '
                '${variants[index].style.name} · '
                'height ${variants[index].height ?? "font default"} · '
                'spacing ${variants[index].letterSpacing}',
              ),
              for (final sample in samples)
                _sample(context, variants[index], sample, locale, direction),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sample(
    BuildContext context,
    FontComparisonVariant variant,
    FontComparisonSample sample,
    Locale? locale,
    TextDirection direction,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final width = sample.width ?? constraints.maxWidth;
      if (!width.isFinite || width > constraints.maxWidth) {
        throw ArgumentError(
          'Sample ${sample.id} does not fit this viewport. '
          'Use a smaller batch/sample, not an automatic text scale change.',
        );
      }
      final painter = TextPainter(
        text: TextSpan(text: sample.text, style: variant.textStyle),
        textDirection: direction,
        textScaler: MediaQuery.textScalerOf(context),
        locale: locale,
      )..layout();
      final naturalWidth = painter.width;
      painter.dispose();
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(
              '${sample.id} · box ${width.toStringAsFixed(1)} · '
              'natural ${naturalWidth.toStringAsFixed(1)} · '
              'lines ${sample.maxLines ?? "unlimited"} · '
              '${sample.overflow.name}',
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: math.min(width, constraints.maxWidth),
              child: Text(
                sample.text,
                style: variant.textStyle,
                textScaler: MediaQuery.textScalerOf(context),
                locale: locale,
                textDirection: direction,
                textAlign: sample.textAlign,
                maxLines: sample.maxLines,
                overflow: sample.overflow,
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      inherit: false,
      color: Color(0xFF444444),
      fontSize: 12,
      height: 1.4,
    ),
  );
}
