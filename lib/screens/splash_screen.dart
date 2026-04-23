import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideIn;
  late final Animation<double> _slideOut;
  late final Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Truck slides in from left (-1.0) to center (0.0)
    _slideIn = Tween<double>(begin: -1.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
      ),
    );

    // Text fades in smoothly
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.65, curve: Curves.easeIn),
      ),
    );

    // Truck accelerates off-screen to the right (1.2)
    _slideOut = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0, curve: Curves.easeInCubic),
      ),
    );

    _controller.forward().then((_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Deep dark background
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final screenWidth = MediaQuery.of(context).size.width;
            final double offsetX = (_slideIn.value + _slideOut.value) * screenWidth;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: Offset(offsetX, 0),
                  child: const Icon(
                    Icons.local_shipping,
                    size: 100,
                    color: Colors.tealAccent,
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _textFade,
                  child: const Text(
                    'Smart Logistics Platform',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
