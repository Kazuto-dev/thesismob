// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_import, duplicate_ignore

import 'package:flutter/material.dart';

// ignore: camel_case_types
class login extends StatelessWidget {
  const login({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Center(child: Text('OOPS!')),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'You need to login first,',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                'Before inserting in a sheet!',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.normal,
                ),
              ),
              SizedBox(
                  height:
                      20.0), // Add some space between the text and the button
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement Google login functionality
                },
                icon: Image.asset(
                  'lib/assets/logos/googleIcon.png',
                  height:
                      30.0, // Adjust the height of the Google icon as needed
                ),
                label: Text(
                  'Login with Google',
                  style: TextStyle(
                    fontSize: 20.0,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/chb');
                },
                child: Container(
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      'BACK',
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
    );
  }
}
