// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, unnecessary_nullable_for_final_variable_declarations

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class login extends StatefulWidget {
  const login({Key? key}) : super(key: key);

  @override
  State<login> createState() => _loginState();
}

class _loginState extends State<login> {
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? user = await GoogleSignIn().signIn();

      if (user == null) {
        print("Google sign-in canceled");
        return;
      }

      final GoogleSignInAuthentication? googleAuth = await user.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final UserCredential gUser =
          await FirebaseAuth.instance.signInWithCredential(credential);

      print("User ${gUser.user?.displayName} logged in");

      // Check if the user is already authenticated
      if (gUser.user != null) {
        // User is already signed in, navigate to the appropriate page
        Navigator.pushReplacementNamed(context, '/menu');
        _showLoggedInAlert(context, gUser.user!.displayName!);
      }
    } catch (e) {
      print("Error during Google sign-in: $e");
    }
  }

  void _showLoggedInAlert(BuildContext context, String? displayName) {
    void _showLoggedInSnackBar(BuildContext context, String? displayName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'You are already logged in as ${displayName ?? "Unknown user"}.'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              // Do something when the user clicks on the action
            },
          ),
        ),
      );
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
                onPressed: () => signInWithGoogle(context),
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
