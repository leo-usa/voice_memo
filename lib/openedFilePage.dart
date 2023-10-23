import 'package:flutter/material.dart';

class OpenedFilePage extends StatelessWidget {
  final String title;

  OpenedFilePage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text('Tässä avataan tiedosto: $title'),
      ),
    );
  }
}
