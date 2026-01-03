import 'package:flutter/material.dart';

import 'package:right_way/features/counter/presentation/counter_page.dart';

class RightWayApp extends StatelessWidget {
  const RightWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Right Way',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const CounterPage(),
    );
  }
}
