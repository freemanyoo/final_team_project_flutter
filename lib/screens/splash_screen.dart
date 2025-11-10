// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final Widget child;
  
  const SplashScreen({
    super.key,
    required this.child,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 3~5초 후 다음 화면으로 이동
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => widget.child),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 이미지
            Image.asset(
              'assets/images/um2.png',
              width: 300,
              height: 300,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 50),
            // 텍스트: "음식 이미지 분석으로 밥 해먹기"
            Column(
              children: [
                // "음식 이미지 분석으로"
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      height: 1.4,
                      shadows: [
                        Shadow(
                          color: Colors.grey[300]!,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    children: [
                      TextSpan(
                        text: '음',
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontSize: 42,
                          shadows: [
                            Shadow(
                              color: Colors.orange[200]!,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      TextSpan(
                        text: '식 이미지 분석으로',
                        style: TextStyle(
                          color: const Color(0xFF1a3344),
                          shadows: [
                            Shadow(
                              color: Colors.grey[200]!,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // "밥" (큰 글씨, 중앙)
                Text(
                  '밥',
                  style: TextStyle(
                    fontSize: 90,
                    fontWeight: FontWeight.w800,
                    color: Colors.green[600],
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        color: Colors.green[300]!,
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                      Shadow(
                        color: Colors.green[200]!,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // "해먹기"
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      height: 1.4,
                      shadows: [
                        Shadow(
                          color: Colors.grey[300]!,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    children: [
                      TextSpan(
                        text: '해',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 42,
                          shadows: [
                            Shadow(
                              color: Colors.blue[200]!,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      TextSpan(
                        text: '먹기',
                        style: TextStyle(
                          color: const Color(0xFF1a3344),
                          shadows: [
                            Shadow(
                              color: Colors.grey[200]!,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

