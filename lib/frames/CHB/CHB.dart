// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, duplicate_ignore, no_logic_in_create_state, camel_case_types

import 'package:flutter/material.dart';

// ignore: camel_case_types
class chb extends StatefulWidget {
  const chb({Key? key}) : super(key: key);

  @override
  State<chb> createState() => _chbState();
}

class _chbState extends State<chb> {
  TextEditingController meController = TextEditingController();
  TextEditingController secondController = TextEditingController();
  String selectedOption = 'Default';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("CHB Estimator"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
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
                width: 250,
                height: 250,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: meController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Length in meters',
                          hintText: "length in Meters",
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: secondController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Width in meters',
                          hintText: "Enter width in Meters",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    Text(
                      'Select an option: ',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(width: 10),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedOption,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedOption = newValue!;
                            });
                          },
                          items: [
                            DropdownMenuItem<String>(
                              value: 'Default',
                              child: Text('Default'),
                            ),
                            ...[
                              ' 30 Option = 1',
                              '20 Option = 2.23',
                              '60 Option = 1.343',
                              'Option = 4'
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Implement your Calculate button functionality
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
              ElevatedButton(
                onPressed: () {
                  // Implement your Insert Sheet button functionality
                },
                child: Container(
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      'Insert Sheet',
                      style: TextStyle(
                        fontSize: 18.0,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.numbers),
            label: "Calculator",
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.question_mark),
            label: "Solution",
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: "Definition of Terms",
            backgroundColor: Colors.blue,
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/solution');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/definition');
          }
        },
      ),
    );
  }
}
