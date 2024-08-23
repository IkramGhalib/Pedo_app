import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:meter_reading/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF243A92),
  ));
  runApp(const MyApp());
  configLoading();
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 45.0
    ..radius = 8.0
    ..progressColor = const Color(0xFF243A92)
    ..backgroundColor = const Color.fromARGB(255, 212, 219, 245)
    ..indicatorColor = const Color(0xFF243A92)
    ..textColor = const Color(0xFF243A92)
    ..maskColor = const Color(0xFF243A92)
    ..userInteractions = true
    ..dismissOnTap = false;
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

const MaterialColor appColor = MaterialColor(0xFF243A92, <int, Color>{
  50: Color(0xFFE8EDF8),
  100: Color(0xFFC5D0EB),
  200: Color(0xFFA2B3DE),
  300: Color(0xFF7F96D1),
  400: Color(0xFF5C79C4),
  500: Color(0xFF243A92), // Primary color
  600: Color(0xFF405DA7),
  700: Color(0xFF2A3185),
  800: Color(0xFF192063),
  900: Color(0xFF0D144C),
});

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    //  Color.fromARGB(255, 216, 217, 247),

    return MaterialApp(
      title: 'Metrocure',
      theme: ThemeData(
        useMaterial3: false,
        textTheme: const TextTheme(
          bodySmall: TextStyle(
            fontSize: 11,
            color: Colors.red,
          ),
        ),
        primarySwatch: appColor,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      builder: EasyLoading.init(),
    );
  }
}
