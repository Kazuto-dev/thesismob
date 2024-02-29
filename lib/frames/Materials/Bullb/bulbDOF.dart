// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

// ignore: camel_case_types
class bulbDef extends StatelessWidget {
  const bulbDef({super.key});

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
              "Bulb",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              " 	In construction, the term 'bulb' typically refers to a light bulb, an essential element in both residential and commercial buildings. Modern construction incorporates a variety of bulb types, including incandescent, fluorescent, LED, and others, each with distinct characteristics such as color temperature, brightness, and energy consumption. Properly planned lighting design not only enhances visibility and safety within a construction but also contributes to the mood and functionality of different areas. The selection of bulbs in construction is, therefore, a thoughtful consideration, aligning with the architectural and functional requirements of the space while also addressing energy efficiency and sustainability concerns.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "Bulb Quantity",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              " Light bulb quantity refers to the number of light bulbs, included in a set, package, or specific lighting fixture. It is a measure of how many individual light sources are provided. When purchasing lighting products, the bulb quantity specification is essential for knowing how much illumination the product will provide and for determining if it meets the lighting requirements for a particular space or application.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "Bulb Type",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Light bulb type refers to the specific design and technology of a light bulb. Common types include incandescent, CFL (Compact Fluorescent Lamp), LED (Light Emitting Diode), halogen, fluorescent tubes, candelabra, and smart bulbs. Each type has unique features, energy efficiency, and applications. Consider factors like brightness, color temperature, and specific lighting needs when choosing a light bulb type for a particular space or task.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "Wattage",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Light wattage refers to the amount of electrical power consumed by a light bulb and is measured in watts (W). It indicates the bulb's energy consumption and provides a general indication of its brightness. In traditional incandescent bulbs, higher wattages typically correspond to brighter light output. When selecting light bulbs, consider the wattage to ensure it meets the desired brightness and energy efficiency for the intended application.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "Price per piece",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Price input of light per bulb.",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              "Reference:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "https://www.felcostore.ph/products/firefly-basic-led-a-bulb?_pos=1&_sid=4210c26e4&_ss=r",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
