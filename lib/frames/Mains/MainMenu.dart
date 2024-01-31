// ignore_for_file: file_names, use_super_parameters, unused_import, prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';

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

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startLoadingTimer();
  }

  void _startLoadingTimer() {
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: Image.asset(
                'lib/assets/logos/Logo3.png', // Replace with the path to your image asset
                height: 100,
                width: 500, // Adjust the height as needed
              ),
              leading: IconButton(
                icon: Icon(Icons.history, size: 40), // Increase the size to 30
                onPressed: () {
                  Navigator.pushNamed(context, '/history');
                },
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.summarize,
                      size: 40), // Increase the size to 30
                  onPressed: () {
                    Navigator.pushNamed(context, '/summary');
                  },
                ),
              ],
              centerTitle: true,
            ),
            // The rest of your widget tree
            // Inside your Drawer:

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
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: Colors.black,
                                width: 1.0,
                              ),
                              image: DecorationImage(
                                image: AssetImage(imagePaths[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                            margin: EdgeInsets.symmetric(
                                horizontal: 5.0,
                                vertical:
                                    5.0), // Set margin to 5.0 for each side
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
