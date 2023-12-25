import 'package:flutter/material.dart';

class roof extends StatefulWidget {
  const roof({Key? key}) : super(key: key);

  @override
  State<roof> createState() => RoofState();
}

class RoofState extends State<roof> {
  TextEditingController _lengthController = TextEditingController();
  TextEditingController _widthController = TextEditingController();
  String selectedWoodWidth = 'Default';
  String selectedWoodLength = 'Default';
  String selectedCorrugation = 'Default';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Roof Estimator"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/struc');
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                'lib/assets/images/Roof(noBG).png',
                width: 300,
                height: 300,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: EdgeInsets.all(5.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _lengthController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Length (m)',
                          hintText: "Enter Length (m)",
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _widthController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Width (m)",
                          hintText: "Enter Width (m)",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(5.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sheet Width:',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 1),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedWoodWidth,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedWoodWidth = newValue!;
                                    });
                                  },
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: 'Default',
                                      child: Text('Default'),
                                    ),
                                    ...['0.8m', '0.9m', '1.0m', '1.2mm']
                                        .map<DropdownMenuItem<String>>(
                                          (String value) =>
                                              DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          ),
                                        )
                                        .toList(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sheet Length: ',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 1),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedWoodLength,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedWoodLength = newValue!;
                                    });
                                  },
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: 'Default',
                                      child: Text('Default'),
                                    ),
                                    ...[
                                      '5FT',
                                      '6FT',
                                      '7FT',
                                      '8FT',
                                      '9FT',
                                      '10FT',
                                      '12FT'
                                    ]
                                        .map<DropdownMenuItem<String>>(
                                          (String value) =>
                                              DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          ),
                                        )
                                        .toList(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                        height: 1), // Add some spacing between the dropdowns
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Corrugation:',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 1),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black),
                                borderRadius: BorderRadius.circular(5.0),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedCorrugation,
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedCorrugation = newValue!;
                                    });
                                  },
                                  items: [
                                    DropdownMenuItem<String>(
                                      value: 'Default',
                                      child: Text('Default'),
                                    ),
                                    ...['1.5 Corrugation', '2.5 Corrugation']
                                        .map<DropdownMenuItem<String>>(
                                          (String value) =>
                                              DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          ),
                                        )
                                        .toList(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 5.0),
                child: ElevatedButton(
                  onPressed: () {
                    double calculate() {
                      double roofSizeW = 0.0;
                      double roofSizeL = 0.0;
                      double corrugation = 0.0;
                      double length = double.parse(_lengthController.text);
                      double width = double.parse(_widthController.text);

                      if (selectedWoodWidth == "Default") {
                        roofSizeW = 0.0;
                      } else if (selectedWoodWidth == '0.8m') {
                        roofSizeW = 0.8;
                      } else if (selectedWoodWidth == '0.9m') {
                        roofSizeW = 0.9;
                      } else if (selectedWoodWidth == '1.0m') {
                        roofSizeW = 1.0;
                      } else if (selectedWoodWidth == '1.2m') {
                        roofSizeW = 1.2;
                      }

                      if (selectedWoodLength == 'Default') {
                        roofSizeL = 0.0;
                      } else if (selectedWoodLength == '5FT') {
                        roofSizeL = 1.524;
                      } else if (selectedWoodLength == '6FT') {
                        roofSizeL = 1.829;
                      } else if (selectedWoodLength == '7FT') {
                        roofSizeL = 2.134;
                      } else if (selectedWoodLength == '8FT') {
                        roofSizeL = 2.438;
                      } else if (selectedWoodLength == '9FT') {
                        roofSizeL = 2.743;
                      } else if (selectedWoodLength == '10FT') {
                        roofSizeL = 3.048;
                      } else if (selectedWoodLength == '12FT') {
                        roofSizeL = 3.657;
                      }

                      if (selectedCorrugation == 'Default') {
                        corrugation = 0.0;
                      } else if (selectedCorrugation == '1.5 Corrugation') {
                        corrugation = 1.524;
                      } else if (selectedCorrugation == '2.5 Corrugation') {
                        corrugation = 1.829;
                      }

                      double area = length * width;
                      print("Area: $area");

                      double effectW = roofSizeW / corrugation;
                      double sheetArea = effectW * roofSizeL;
                      double sheetsNeeded = area / sheetArea;
                      int sheetsNeededRounded = sheetsNeeded.ceil();
                      print("Sheets Needed: $sheetsNeededRounded");

                      Navigator.pushNamed(
                        context,
                        '/roofOutput',
                        arguments: {
                          'area': area,
                          'sheetsNeeded': sheetsNeededRounded,
                        },
                      );

                      return area;
                    }

                    // Call the calculate function
                    calculate();
                  },
                  child: Container(
                    width: double.infinity,
                    child: Center(
                      child: Text(
                        'Calculate',
                        style: TextStyle(
                          fontSize: 18.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          //home
          BottomNavigationBarItem(
            icon: Icon(Icons.numbers),
            label: "Calculator",
            backgroundColor: Colors.blue,
          ),
          //profile
          BottomNavigationBarItem(
            icon: Icon(Icons.question_mark),
            label: "Solution",
            backgroundColor: Colors.blue,
          ),
          //settings
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Definition of Terms",
            backgroundColor: Colors.blue,
          ),
        ],
        onTap: (index) {
          // Handle the tap for each item
          if (index == 1) {
            Navigator.pushNamed(context, '/solutiontiles');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/definitiontiles');
          }
        },
      ),
    );
  }
}
