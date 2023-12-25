// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, unnecessary_nullable_for_final_variable_declarations, unused_import

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

// ignore: camel_case_types
class sign extends StatelessWidget {
  const sign({super.key});

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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Already Logged In'),
          content: Text(
            'You are already logged in as ${displayName ?? "Unknown user"}.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign In"),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => signInWithGoogle(context),
          icon: Image.asset(
            'lib/assets/logos/googleIcon.png',
            height: 30.0,
          ),
          label: Text(
            'Sign In with Google',
            style: TextStyle(
              fontSize: 20.0,
            ),
          ),
        ),
      ),
    );
  }
}
