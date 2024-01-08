// ignore: file_names
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, duplicate_ignore, empty_statements, camel_case_types

import 'package:flutter/material.dart';

class instructions extends StatelessWidget {
  const instructions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ignore: prefer_const_constructors
      appBar:
          AppBar(title: Text("BuildQuantify Instructions"), centerTitle: true),
    );
  }
}
