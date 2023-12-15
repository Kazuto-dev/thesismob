// ignore_for_file: prefer_const_constructors, unused_import, camel_case_types, use_super_parameters

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class login extends StatelessWidget {
  const login({Key? key}) : super(key: key);

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? user = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication? googleAuth = await user?.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final UserCredential gUser =
          await FirebaseAuth.instance.signInWithCredential(credential);

      print("User ${gUser.user?.displayName} logged in");
    } catch (e) {
      print("Error during Google sign-in: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    TextStyle normalTextStyle = TextStyle(
      fontSize: 18.0,
      fontWeight: FontWeight.normal,
    );

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
                style: normalTextStyle,
              ),
              Text(
                'Before inserting in a sheet!',
                style: normalTextStyle,
              ),
              SizedBox(
                height: 20.0,
              ),
              ElevatedButton.icon(
                onPressed: signInWithGoogle,
                icon: Image.asset(
                  'lib/assets/logos/googleIcon.png',
                  height: 30.0,
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
