import 'package:flutter/material.dart';

// ignore: camel_case_types
class toiletsol extends StatelessWidget {
  const toiletsol({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text("Solutions")),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/plumb');
          },
        ),
      ),
    );
  }
}
