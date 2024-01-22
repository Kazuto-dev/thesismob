// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, camel_case_types

import 'package:flutter/material.dart';

class pipe extends StatefulWidget {
  const pipe({Key? key}) : super(key: key);

  @override
  State<pipe> createState() => pipeState();
}

class pipeState extends State<pipe> {
  TextEditingController faucetHeight = TextEditingController();
  TextEditingController pvcLength = TextEditingController();

  String size = 'Default';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PVC Pipe Calculator'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/plumb');
          },
          tooltip: 'Back',
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                'lib/assets/images/Paint(noBG).png',
                width: 300,
                height: 250,
                fit: BoxFit.cover,
              ),
              Padding(
                padding: EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: faucetHeight,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'faucet Height (m)',
                          hintText: "Enter Height (m)",
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: pvcLength,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "PVC pipes from main source(m)",
                          hintText: "Enter Length (m)",
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
                        value: size, // Use windowSize here
                        onChanged: (String? newValue) {
                          // Handle the selection

                          setState(() {
                            size = newValue!;
                          });
                        },
                        items: <String>[
                          'Default',
                          '10(m)',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "Default Size (m)",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 5.0),
                child: ElevatedButton(
                  onPressed: () {
                    double calculate() {
                      double height = double.parse(faucetHeight.text);
                      double length = double.parse(pvcLength.text);
                      double size1 = 0.0;

                      if (size == 'Default') {
                        size1 = 0.0;
                      } else if (size == '10(m)') {
                        size1 = 10.0;
                      }

                      double metersNeeded = (height + length);
                      int piecesNeeded = (metersNeeded / size1).ceil();

                      print('metersNeeded: $metersNeeded(m)');
                      print('piecesNeeded: $piecesNeeded');

                      return metersNeeded;
                    }

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
