// ignore_for_file: file_names, prefer_const_constructors

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
        title: Text('Sheet Credentials Form'),
      ),
      body: Padding(
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

                  // Navigate to the next page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NextPage(),
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
    );
  }
}

class NextPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Access the sheet info from the provider
    final sheetInfo = Provider.of<SheetInfoProvider>(context).sheetInfo;

    return Scaffold(
      appBar: AppBar(
        title: Text('Next Page'),
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
