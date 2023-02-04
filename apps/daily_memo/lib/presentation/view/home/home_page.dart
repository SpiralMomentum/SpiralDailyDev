import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView.builder(
            itemCount:10,
            itemBuilder: (BuildContext context, int index) {
          return Container(
            child: Text(""),
          );
        }),
      ),
    );
  }
}
