import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:tangerine/page/store_filter_by_service/store_filter_by_service_screen.dart';

import 'mock system/mock_demo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) unawaited(_demonstrateMockServices());
  runApp(const MyApp());
}

Future<void> _demonstrateMockServices() async {
  await demonstrateMockServices();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => CupertinoApp(
    title: 'Tangerine',
    debugShowCheckedModeBanner: false,
    theme: const CupertinoThemeData(brightness: Brightness.light),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: child!,
    ),
    home: const StoreFilterByServiceScreen(),
  );
}
