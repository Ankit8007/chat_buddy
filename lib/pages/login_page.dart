import 'package:flutter/material.dart';
import 'package:chat_buddy/pages/pages.dart';
import 'package:chat_buddy/providers/auth_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    final authProvider = Provider.of<AuthProvider>(context);
    switch (authProvider.status) {
      case Status.authenticateError:
        Fluttertoast.showToast(msg: "Sign in fail");
        break;
      case Status.authenticateCanceled:
        Fluttertoast.showToast(msg: "Sign in canceled");
        break;
      case Status.authenticated:
        Fluttertoast.showToast(msg: "Sign in success");
        break;
      default:
        break;
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xffc5bbfb),
              Color(0xFFd5daf6)
            ],
            stops: [0.1,2],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      image: const DecorationImage(
                        image: AssetImage('images/app_icon.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Chat Buddy',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E345C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to start chatting',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Google sign‑in button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0A66C3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        backgroundColor: Color(0xFF437CF4),
                      ),
                      onPressed: () async{

                        authProvider.handleSignIn().then((isSuccess) {
                          if (isSuccess) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomePage(),
                              ),
                            );
                          }
                        }).catchError((error, stackTrace) {
                          Fluttertoast.showToast(msg: error.toString());
                          authProvider.handleException();
                        });

                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'images/google.png',
                            height: 24,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Sign in with Google',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'By continuing you agree to our Terms & Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
