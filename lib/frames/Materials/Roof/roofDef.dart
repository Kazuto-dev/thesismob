// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

// ignore: camel_case_types
class roofDef extends StatelessWidget {
  const roofDef({super.key});

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
              "Roof",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              " A roof is the uppermost covering of a building or structure, providing protection from weather elements such as rain, snow, sunlight, and wind. Roofs serve the essential function of sheltering the interior space beneath them and play a crucial role in the overall structure and design of a building. Roofs can be constructed using various materials, including shingles, tiles, metal, or concrete, and they come in different shapes and styles.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20.0),
            Text(
              "Rib Roof",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              " A rib roof typically refers to a type of roofing structure characterized by the use of ribs or raised ridges along the surface of the roof. These ribs can add strength and support to the roof structure while also creating a distinctive architectural appearance. Rib roofs are often associated with certain types of metal roofing systems or architectural designs that incorporate ribbed patterns for both functional and aesthetic purposes. The ribs can enhance the structural integrity of the roof and may also contribute to efficient water drainage.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20.0),
            Text(
              "Roof Area Length",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Roof area length refers to the measurement of the longest dimension of a roof surface. It is typically measured from one end to the other, providing the linear distance along the roof.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20.0),
            Text(
              "Roof Area Width",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "Roof area length refers to the measurement of the shortest dimension of a roof surface. It is typically measured from one end to the other, providing the linear distance along the roof.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20.0),
            Text(
              "Roof Sheet Dimension",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              " Roof sheet dimensions encompass the specific length and width measurements of the individual sheets utilized in roofing applications. The dimensions are contingent upon the type of roofing material selected for a particular project. Prior to initiating a roofing project, it is advisable to refer to the product documentation and specifications provided by the manufacturer to ensure accurate measurements and adherence to installation guidelines.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20.0),
            Text(
              "Corrugation",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              " Roof corrugation refers to the wavy pattern on roofing materials, commonly seen in metal sheets. This design enhances structural strength, rigidity, and facilitates efficient water drainage, making it suitable for areas with heavy rainfall. Corrugated roofing is known for its durability, affordability, and widespread use in construction.",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20.0),
            Text(
              "Price per piece",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              " Price input of roof sheet per piece.",
              style: TextStyle(fontSize: 16),
            ),
            Text(
              "Reference:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              "https://www.alphasteel.ph/rib-type-roof/",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "https://steelcaretrading.com/product/corrugated-roof-panel/",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16.0),
            Text(
              "https://www.metalinkretail.com/products/corrugated-roof-prepainted",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
