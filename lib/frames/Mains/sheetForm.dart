// ignore_for_file: file_names, prefer_const_constructors, library_private_types_in_public_api, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thesismob/frames/Mains/sheetProvider.dart';

class SheetInfoInput extends StatefulWidget {
  @override
  _SheetInfoInputState createState() => _SheetInfoInputState();
}

class _SheetInfoInputState extends State<SheetInfoInput> {
  final TextEditingController sheetIdController = TextEditingController();
  final TextEditingController sheetNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Sheet Form')),
        actions: [
          // Any existing action buttons go here, if applicable
          IconButton(
            icon: Icon(Icons.key_sharp),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => displayCreds()),
              );
            },
          ),
        ],
      ),
      // The rest of your Scaffold body goes here

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/logos/icons8-google-sheets-300.png',
              width: 250,
              height: 250,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: sheetIdController,
                    decoration: InputDecoration(labelText: 'Enter Sheet ID'),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: sheetNameController,
                    decoration: InputDecoration(labelText: 'Enter Sheet Name'),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      final String sheetId = sheetIdController.text;
                      final String sheetName = sheetNameController.text;

                      if (sheetId.isNotEmpty && sheetName.isNotEmpty) {
                        // Use the provider to set the sheet info
                        Provider.of<SheetInfoProvider>(context, listen: false)
                            .setSheetInfo(sheetId, sheetName);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Credentials added successfully!'),
                            duration: Duration(seconds: 5),
                          ),
                        );
                      } else {
                        print('Please enter both Sheet ID and Sheet Name');
                      }
                    },
                    child: Text('Submit'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class displayCreds extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Access the sheet info from the provider
    final sheetInfo = Provider.of<SheetInfoProvider>(context).sheetInfo;

    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Credentials')),
      ),
      body: Center(
        child: Text(
          'Sheet ID: ${sheetInfo?.sheetId}\nSheet Name: ${sheetInfo?.sheetName}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
