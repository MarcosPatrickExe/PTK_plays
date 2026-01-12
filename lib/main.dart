import 'package:flutter/material.dart';
import 'view/home.dart';
import 'view/splash_screen.dart';

void main () {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PTK plays',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Roboto', // Default, but explicit is fine
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
