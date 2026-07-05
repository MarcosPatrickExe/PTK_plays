import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ptk_plays/view/Home.dart';
import 'package:ptk_plays/view/Login.dart';
import 'package:ptk_plays/viewmodels/AuthViewModel.dart';
import 'package:ptk_plays/viewmodels/YoutubeVideoModel.dart';


class SplashScreen extends StatefulWidget {
  final YoutubeViewModel viewmodelYTtemp;
  final String apiKEYtemp;
  final AuthViewModel authViewModelTemp;

  const SplashScreen({ required this.viewmodelYTtemp, required this.apiKEYtemp, required this.authViewModelTemp });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}


class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Navigate to Home (se logado) ou Login (se nao) after 2 seconds
    Future.delayed( const Duration(seconds: 2), () {
      if (mounted) {
        final bool usuarioLogado = FirebaseAuth.instance.currentUser != null;

        Navigator.of( context ).pushReplacement(
          MaterialPageRoute( builder: (BuildContext context) => usuarioLogado
            ? HomePage( viewmodelYT: super.widget.viewmodelYTtemp, apiKEY: super.widget.apiKEYtemp )
            : Login( viewmodelYT: super.widget.viewmodelYTtemp, apiKey: super.widget.apiKEYtemp, authViewModel: super.widget.authViewModelTemp )
          )
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build( BuildContext context ) {
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark background
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/original_icon_app.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                const CircularProgressIndicator(
                  color: Color.fromARGB(255, 171, 54, 244),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
}
