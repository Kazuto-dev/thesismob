// ignore: file_names
// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors, duplicate_ignore, empty_statements, camel_case_types

import 'package:flutter/material.dart';

class instructions extends StatelessWidget {
  const instructions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set the background color here
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 229, 240, 255),
        title: Text("BuildQuantify Instructions"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushNamed(context, '/mainpage');
          },
        ),
      ),

      body: Container(
        color: Color.fromARGB(255, 229, 240, 255),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                "Instruction For Application:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              SelectableText(
                "This application is used to calculate the quantity and estimate the cost of different construction materials.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16.0),
              SelectableText(
                "You can use this application offline if you just want to calculate materials and online if you want to save your result on google sheet to have your record.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8.0),
              SelectableText(
                "Here are the steps in how you can save your result on Google Sheet:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              SelectableText(
                "Go to Google sheet on your mobile phone or devices.",
                style: TextStyle(fontSize: 16),
              ),
              Image.asset(
                'lib/assets/images/SHEET.jpg',
                width: 500,
                height: 600,
              ),
              SizedBox(height: 16.0),
              SelectableText(
                "Create a new sheet on your google sheet or use an existing one just remember the name of the sheet.",
                style: TextStyle(fontSize: 16),
              ),
              SelectableText(
                "• Click the three dot button on the upper right: ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SelectableText(
                "• Then look for “Share & export”: ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Image.asset(
                'lib/assets/inspic/first.png',
                width: 500,
                height: 600,
              ),
              SelectableText(
                "• Next look for “Share” then click it: ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Image.asset(
                'lib/assets/inspic/2.png',
                width: 500,
                height: 600,
              ),
              SelectableText(
                "• Here you will the add the API account: ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SelectableText(
                "  flutter-test@qualified-tea-408701.iam.gserviceaccount.com ",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
              Image.asset(
                'lib/assets/inspic/3.png',
                width: 500,
                height: 600,
              ),
              Image.asset(
                'lib/assets/inspic/4.png',
                width: 500,
                height: 600,
              ),
              SelectableText(
                "• After you add the link, click submit: ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Image.asset(
                'lib/assets/inspic/5.png',
                width: 500,
                height: 600,
              ),
              SelectableText(
                "• This is where you can see if the account is successfully added: ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Image.asset(
                'lib/assets/inspic/6.png',
                width: 500,
                height: 600,
              ),
              SelectableText(
                "• Get the link of the sheet that you created: ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Image.asset(
                'lib/assets/inspic/7.png',
                width: 500,
                height: 600,
              ),
              SelectableText(
                "• Get the ID in the link.: ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Image.asset(
                'lib/assets/inspic/8.png',
                width: 500,
                height: 600,
              ),
              SizedBox(height: 8.0),
              SelectableText(
                "Go to sheet form on the application: ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.0),
              SelectableText(
                "Make sure you have an internet connection so you can save your work or result on Google sheet.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16.0),
              SelectableText(
                "Now, Click the key icon on the bottom right.",
                style: TextStyle(fontSize: 16),
              ),
              Image.asset(
                'lib/assets/inspic/9.png',
                width: 500,
                height: 600,
              ),
              SizedBox(height: 16.0),
              SelectableText(
                "Enter the sheet id and the sheet name where you want to save your result.",
                style: TextStyle(fontSize: 16),
              ),
              Image.asset(
                'lib/assets/inspic/10.png',
                width: 500,
                height: 600,
              ),
              SizedBox(height: 16.0),
              SelectableText(
                "This where you can get your Sheet ID.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16.0),
              SelectableText(
                "And your Sheet Name.",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16.0),
              SelectableText(
                "Click Submit.",
                style: TextStyle(fontSize: 16),
              ),
              Image.asset(
                'lib/assets/inspic/11.png',
                width: 500,
                height: 600,
              ),
              SizedBox(height: 16.0),
              SelectableText(
                "Then look for the key icon on top right and see if your information is saved in the credentials.",
                style: TextStyle(fontSize: 16),
              ),
              Image.asset(
                'lib/assets/inspic/12.png',
                width: 500,
                height: 600,
              ),
              Image.asset(
                'lib/assets/inspic/13.png',
                width: 500,
                height: 600,
              ),
              SizedBox(height: 16.0),
              SelectableText(
                "Now you can use the application and save your result on Google sheet.",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
