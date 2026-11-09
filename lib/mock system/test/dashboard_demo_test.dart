import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
// Tests stay under the requested directory; flutter_test is a dev dependency.
// ignore: depend_on_referenced_packages
import 'package:flutter_test/flutter_test.dart';
import 'package:tangerine/main.dart' as app;

import '../mock_config.dart';

void main() {
  testWidgets('debug startup calls all twelve methods once while UI starts', (
    tester,
  ) async {
    final messages = <String>[];
    final done = Completer<void>();
    final originalPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message == null) return;
      messages.add(message);
      if ((message.startsWith('Mock service demonstration complete') ||
              message.startsWith('Mock service demonstration failed')) &&
          !done.isCompleted) {
        done.complete();
      }
    };
    try {
      app.main();
      await pumpUntilComplete(tester, done, messages);
      expect(find.byType(app.MyApp), findsOneWidget);
      expect(
        messages.where(
          (m) => m.startsWith('Mock service demonstration failed'),
        ),
        isEmpty,
        reason: messages.join('\n'),
      );
      for (final expected in [
        'Dashboard header: 20 stores',
        'Dashboard displays: 7 groups',
        'Dashboard getAllStores: 100 stores',
        'Filter header: 11 carousels',
        'Filter getAllStores: 100 stores',
        'Filter displays: 5 stores',
        'Store page requested ID=1175: 13 full carousels',
        'Store page requested ID=1175: 38 full categories',
      ]) {
        expect(messages.where((m) => m.startsWith(expected)), hasLength(1));
      }
      expect(
        messages.where((m) => m.startsWith('Filter display label=')),
        hasLength(5),
      );
      expect(
        messages.where((m) => m.startsWith('Product shopId=')),
        hasLength(5),
      );
      for (final prefix in [
        'Product lookup:',
        'Recommendations:',
        'Aisles:',
        'Aisle detail:',
        'Null category association:',
        'Empty carousel association:',
        'Unresolved flat slot:',
        'Thrown argument error:',
      ]) {
        expect(
          messages.any((m) => m.startsWith(prefix)),
          isTrue,
          reason: prefix,
        );
      }
      expect(
        messages.any(
          (m) =>
              m.startsWith('Category shopId=1175:') &&
              m.contains('"categoryId":') &&
              m.contains('"title":') &&
              m.contains('"items":'),
        ),
        isTrue,
      );
      expect(messages.any((m) => m.contains('Instance of')), isFalse);
      final count = messages.length;
      await tester.pumpWidget(const app.MyApp());
      await tester.pump();
      expect(messages, hasLength(count));
      expect(tester.takeException(), isNull);
    } finally {
      debugPrint = originalPrint;
    }
  });

  testWidgets(
    'debug demonstration reports missing assets while preserving startup UI',
    (tester) async {
      final messages = <String>[];
      final done = Completer<void>();
      final originalPrint = debugPrint;
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      rootBundle.evict(MockConfig.storeAsset);
      messenger.setMockMessageHandler(
        'flutter/assets',
        (message) async => null,
      );
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message == null) return;
        messages.add(message);
        if (message.startsWith('Mock service demonstration failed') &&
            !done.isCompleted) {
          done.complete();
        }
      };
      try {
        app.main();
        await pumpUntilComplete(tester, done, messages);
        expect(find.byType(app.MyApp), findsOneWidget);
        expect(
          messages.where(
            (m) =>
                m.contains('MockDataException') &&
                m.contains(MockConfig.storeAsset),
          ),
          hasLength(1),
        );
        expect(tester.takeException(), isNull);
      } finally {
        debugPrint = originalPrint;
        messenger.setMockMessageHandler('flutter/assets', null);
        rootBundle.evict(MockConfig.storeAsset);
      }
    },
  );
}

Future<void> pumpUntilComplete(
  WidgetTester tester,
  Completer<void> done,
  List<String> messages,
) async {
  for (var attempt = 0; attempt < 200 && !done.isCompleted; attempt++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
  expect(done.isCompleted, isTrue, reason: messages.join('\n'));
}
