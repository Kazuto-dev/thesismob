import 'package:flutter/material.dart';
import 'package:thesismob/frames/Mains/calculationHistory.dart';
import 'package:thesismob/frames/Mains/historyClass.dart';
import 'package:thesismob/frames/Mains/summaryClass.dart';
import 'package:thesismob/frames/Mains/summaryHistory.dart';

class marble extends StatefulWidget {
  const marble({super.key});
  @override
  marbleState createState() => marbleState();
}

class marbleState extends State<marble> {
  TextEditingController lengthController = TextEditingController();
  TextEditingController widthController = TextEditingController();
  TextEditingController costController = TextEditingController();
  String selectedWastage = 'Default';
  String selectedSize = 'Default';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Marble Calculator"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/arch');
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                'lib/assets/logos/Logo4.png',
                width: 300,
                height: 300,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: lengthController,
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
                        controller: widthController,
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
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedWastage, // Use windowSize here
                        onChanged: (String? newValue) {
                          // Handle the selection

                          setState(() {
                            selectedWastage = newValue!;
                          });
                        },
                        items: <String>[
                          'Default',
                          '5% Wastage',
                          '10% Wastage',
                          '15% Wastage',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "CHB Wastage",
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSize, // Use doorSize here
                        onChanged: (String? newValue) {
                          // Handle the selection
                          setState(() {
                            selectedSize = newValue!;
                            // Update doorSize here
                          });
                        },
                        items: <String>[
                          'Default',
                          '.40m x .20m',
                          '.30m x .20m',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Marble Size",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: costController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Price per Piece',
                          hintText: "Enter Price (₱)",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 50.0),
                child: ElevatedButton(
                  onPressed: () {
                    double calculate() {
                      double marbleSize = 0.0;
                      double length = double.parse(lengthController.text);
                      double width = double.parse(widthController.text);
                      double cost = double.parse(costController.text);
                      double wastagePercentage = 0.0;

                      if (selectedWastage == "Default") {
                        wastagePercentage = 0.0;
                      } else if (selectedWastage == '5% Wastage') {
                        wastagePercentage = 0.05;
                      } else if (selectedWastage == '10% Wastage') {
                        wastagePercentage = 0.1;
                      } else if (selectedWastage == '15% Wastage') {
                        wastagePercentage = 0.15;
                      }

                      if (selectedSize == '.40m x .20m') {
                        marbleSize = 0.08;
                      } else if (selectedSize == '.30m x .20m') {
                        marbleSize = 0.06;
                      }

                      double area = length * width;
                      print("Area: $area");

                      int marbleNeed = (area / marbleSize).ceil();
                      print("Marble Needed: $marbleNeed");

                      // Round up to the nearest whole number for the CHB needed
                      double totalcost = area * cost;
                      print("Area: $totalcost");

                      int wastage =
                          (wastagePercentage * marbleNeed).ceil().toInt();
                      print("Wastage: $wastage");

                      CalculationHistoryEntry entry = CalculationHistoryEntry(
                          date: DateTime.now(),
                          calculatorType: "MArble Estimator",
                          material: "Marble",
                          area: area.toString() + "m²",
                          quantity: marbleNeed.toString() + "pcs",
                          totalamount: totalcost.toString() + "₱");

                      CalculationSummaryEntry summary = CalculationSummaryEntry(
                        materialName: "Marble",
                        quantity: marbleNeed.toString() + "pcs",
                        totalamount: totalcost.toString() + "₱",
                      );

                      CalculationHistory.addEntry(entry);
                      CalculationSummary.addEntry(summary);

                      // Navigate to the output page with the calculated values
                      Navigator.pushNamed(
                        context,
                        '/marbleOutput',
                        arguments: {
                          'area': area,
                          'Marble Needed': marbleNeed,
                          'totalcost': totalcost
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
    );
  }
}
