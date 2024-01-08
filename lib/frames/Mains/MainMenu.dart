// ignore_for_file: file_names, use_super_parameters, unused_import, prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:thesismob/frames/Mains/history.dart';
import 'package:thesismob/frames/CHB/CHB.dart';

class FirstPage extends StatefulWidget {
  final String? displayName;

  const FirstPage({Key? key, this.displayName}) : super(key: key);

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  final List<String> imagePaths = [
    "lib/assets/images/Struc.png",
    "lib/assets/images/Arch.png",
    "lib/assets/images/Elec.png",
    "lib/assets/images/Plumbing.png",
  ];

  @override
  Widget build(BuildContext context) {
    List<DateTime> _getUniqueDates() {
      // Extract unique dates from the calculations
      return HistoryManager()
          .calculations
          .map((calculation) => calculation.date)
          .toSet()
          .toList();
    }

    String _formattedDate(DateTime date) {
      // Format the date to a readable string
      return "${date.month}/${date.day}/${date.year}";
    }

    void _showCalculationsByDate(BuildContext context, DateTime date) {
      // Retrieve calculations for the specified date
      List<Calculation> calculations =
          HistoryManager().getCalculationsByDate(date);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Calculations on ${_formattedDate(date)}"),
            content: Container(
              width: double.minPositive,
              child: DropdownButton<Calculation>(
                isExpanded: true,
                value: null, // Initially, no calculation is selected
                onChanged: (Calculation? selectedCalculation) {
                  // Handle the selected calculation
                  if (selectedCalculation != null) {
                    // Show a dialog with details of the selected calculation
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Details for the selected calculation"),
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                  "Material: ${selectedCalculation.calculatorType}"),
                              Text("Area: ${selectedCalculation.area}"),
                              Text(
                                  "Total CHB: ${selectedCalculation.totalCHB}"),
                              Text(
                                  "Date: ${_formattedDate(selectedCalculation.date)}"),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: Text('Close'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },

                items: calculations.map((calculation) {
                  return DropdownMenuItem<Calculation>(
                    value: calculation,
                    child: Text(
                      "Concrete Hollow Blocks",
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'lib/assets/logos/Logo3.png', // Replace with the path to your image asset
          height: 100,
          width: 500, // Adjust the height as needed
        ),
        leading: IconButton(
          icon: Icon(Icons.book),
          onPressed: () {
            Navigator.pushNamed(context, '/instructions');
          },
        ),
        centerTitle: true,
      ),
      // The rest of your widget tree
      // Inside your Drawer:
      endDrawer: Drawer(
        backgroundColor: Color.fromARGB(255, 3, 124, 9),
        child: ListView(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: DrawerHeader(
                child: Text(
                  "History",
                  style: TextStyle(
                    fontSize: 30,
                    color: Color.fromARGB(255, 226, 226, 226),
                  ),
                ),
              ),
            ),
            // Add ListTile for each date in the history
            ..._getUniqueDates().map((date) {
              return ListTile(
                title: Text(
                  "${_formattedDate(date)}",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  _showCalculationsByDate(context, date);
                },
              );
            }).toList(),
          ],
        ),
      ),

      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Add the text at the top
          Container(
            padding: EdgeInsets.only(bottom: 100.0),
            child: Text(
              "Building Precision, Calculation one at a Time",
              style: TextStyle(
                fontSize: 15,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: GridView.builder(
                itemCount: imagePaths.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                itemBuilder: (context, index) => InkWell(
                  onTap: () {
                    // Redirect to a page based on the chosen image
                    switch (index) {
                      case 0:
                        Navigator.pushNamed(context, '/struc');
                        break;
                      case 1:
                        Navigator.pushNamed(context, '/arch');
                        break;
                      case 2:
                        Navigator.pushNamed(context, '/elec');
                        break;
                      case 3:
                        Navigator.pushNamed(context, '/plumb');
                        break;
                    }
                  },
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.black,
                          width: 1.0,
                        ),
                        image: DecorationImage(
                          image: AssetImage(imagePaths[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                      margin: EdgeInsets.all(7.0),
                      height: 200.0,
                      width: 200.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
