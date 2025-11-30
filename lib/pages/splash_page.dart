import 'package:flutter/material.dart';
import 'package:chat_buddy/constants/color_constants.dart';
import 'package:chat_buddy/pages/pages.dart';
import 'package:chat_buddy/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  SplashPage({super.key});

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 1), () {
      // just delay for showing this slash page clearer because it's too fast
      _checkSignedIn();
    });
  }

  void _checkSignedIn() async {
    try {
      final authProvider = context.read<AuthProvider>();
      bool isLoggedIn = await authProvider.isLoggedIn();
      if (isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } on Exception catch (e,s) {
      print(e);
      print(s);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                "images/app_icon.png",
                width: 100,
                height: 100,
              ),
              SizedBox(height: 20),
              Container(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: ColorConstants.themeColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
