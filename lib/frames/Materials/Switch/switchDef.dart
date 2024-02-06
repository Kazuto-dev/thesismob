import 'package:flutter/material.dart';

// ignore: camel_case_types
class switchDef extends StatelessWidget {
  const switchDef({super.key});

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
              "Switch",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "A switch is an electrical component that can break an electrical circuit, interrupting the current or diverting it from one conductor to another. The mechanism of a switch removes or restores the conducting path in a circuit when it is operated. It may be operated manually, for example, a light switch or a keyboard button, may be operated by a moving object such as a door, or may be operated by some sensing element for pressure, temperature, or flow. A switch will have one or more sets of contacts, which may operate simultaneously, sequentially, or alternately. Switches in high-powered circuits must operate rapidly to prevent destructive arcing, and may include special features to assist in rapidly interrupting a heavy current. Multiple forms of actuators are used for operation by hand or to sense position, level, temperature or flow. Special types are used, for example, for control of machinery, to reverse electric motors, or to sense liquid level.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "Switch Quantity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Light switch quantity refers to the number of individual light switches in a given space or area. It indicates how many separate controls are available to operate the lighting fixtures. The quantity of light switches in a room or building depends on factors such as the room's layout, size, and the desired lighting configurations.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "Price per piece",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Price of switch per piece",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
