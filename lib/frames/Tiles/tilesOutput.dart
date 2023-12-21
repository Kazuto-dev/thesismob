// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors, unused_import, camel_case_types, use_build_context_synchronously, await_only_futures
import 'package:flutter/material.dart';
import 'package:gsheets/gsheets.dart';

class tilesOutput extends StatefulWidget {
  @override
  State<tilesOutput> createState() => _tilesOutputState();
}

class _tilesOutputState extends State<tilesOutput> {
  @override
  Widget build(BuildContext context) {
    // Retrieve arguments passed by Navigator
    final Map<String, dynamic>? args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    // Check if args is not null before extracting values
    if (args != null) {
      // Extract values
      final double area = args['area'];
      final int totalTiles = args['total'];
      String material = "Tiles";

      void insertSheet() {}

      return Scaffold(
        appBar: AppBar(
          title: Text("Output Calculation"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/assets/images/Tiles(noBG).png',
                width: 250,
                height: 250,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 20),
              Container(
                margin: EdgeInsets.only(bottom: 10),
                child: Text(
                  "Area: $area",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 10),
                child: Text(
                  "Total Tiles: $totalTiles",
                  style: TextStyle(fontSize: 20),
                ),
              ),
              ElevatedButton(
                onPressed: () async {},
                child: Container(
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      'INSERT SHEET',
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
      );
    } else {
      // Handle the case where arguments is null
      return Scaffold(
        body: Center(
          child: Text(
            "Error: Missing arguments",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }
  }
}
