// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

// ignore: camel_case_types
class paintDef extends StatelessWidget {
  const paintDef({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Definition of Terms"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Paint",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "   Beyond its role in providing a protective layer to surfaces, such as walls and ceilings, paint contributes significantly to the overall design and ambiance of a space. It allows for personalization, creativity, and the expression of architectural style. The process of selecting paint involves considerations such as color, finish, and durability, ensuring that it aligns with both the practical requirements and the desired aesthetic of a construction project. Whether used to refresh the appearance of existing structures or to finalize the finishing touches on newly built spaces, paint stands as a versatile and essential component in the construction industry.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
