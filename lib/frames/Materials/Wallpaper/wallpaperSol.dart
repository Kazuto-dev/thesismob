import 'package:flutter/material.dart';

class wallpaperSol extends StatelessWidget {
  const wallpaperSol({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Solutions"),
        centerTitle: true,
      ),
    );
  }
}
