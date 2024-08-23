import 'package:flutter/material.dart';
import 'package:meter_reading/screens/home/home_screen.dart';
import 'package:meter_reading/screens/Login/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInFadeOut;
  bool newUser = false;

  Widget home = const SplashScreen();
  void checkUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    newUser = (prefs.getBool('newUser') ?? true);
  }

  @override
  void initState() {
    checkUser();
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _fadeInFadeOut = TweenSequence(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          weight: 1,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.0, end: 0.0),
          weight: 1, // Represents the weight of this tween in the sequence
        ),
      ],
    ).animate(_controller);

    _controller.repeat(); // Makes the animation loop with fading in and out

    Future.delayed(
      const Duration(seconds: 3),
      () {
        if (newUser == false) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const MyHomePage(),
            ),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const Login(),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeInFadeOut,
          child: Image.asset(
            'assets/images/logo.png',
            width: deviceSize.width * 0.4,
          ),
        ),
      ),
    );
  }
}
