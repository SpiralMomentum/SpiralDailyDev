import 'package:flutter/material.dart';

import 'package:knowlly/features/counter/presentation/counter_page.dart';

class KnowllyApp extends StatelessWidget {
  const KnowllyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Knowlly',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const CounterPage(),
    );
  }
}
