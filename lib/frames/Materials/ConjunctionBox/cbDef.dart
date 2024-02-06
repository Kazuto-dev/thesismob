import 'package:flutter/material.dart';

class cBoxDef extends StatelessWidget {
  const cBoxDef({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Definition of Terms"),
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
              " 	A conjunction box is a container that houses electrical connections, such as wire splices, and is used to protect the connections from the elements. It is typically made of metal or plastic and is designed to be weatherproof. Conjunction boxes are used in a variety of applications, including outdoor lighting, irrigation systems, and electrical wiring for buildings. They are an essential component of any electrical system and are designed to provide a safe and secure environment for electrical connections.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "J-Box Quantity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Junction box quantity refers to the number of junction boxes installed in a particular electrical system or building. A junction box is an enclosure that houses electrical connections, protecting them from environmental factors, preventing accidental contact, and containing potential sparks or fires. The quantity of junction boxes is a critical consideration in electrical installations to ensure proper wiring organization, safety, and compliance with electrical codes.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "Price per piece",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Price per piece of junction box.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
