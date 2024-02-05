import 'package:flutter/material.dart';

class cBoxSol extends StatelessWidget {
  const cBoxSol({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Solution"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Junction Box",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "A junction box is a container that houses electrical connections, such as wire splices, and is used to protect the connections from the elements. It is typically made of metal or plastic and is designed to be weatherproof. Conjunction boxes are used in a variety of applications, including outdoor lighting, irrigation systems, and electrical wiring for buildings. They are an essential component of any electrical system and are designed to provide a safe and secure environment for electrical connections.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
