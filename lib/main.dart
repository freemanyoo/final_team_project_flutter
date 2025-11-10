// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// [핵심] 로그인 페이지와 회원가입 페이지를 import 합니다.
// (이 파일들을 lib/screens/ 폴더로 옮기는 것을 추천합니다!)
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/main_screen.dart';
import 'screens/splash_screen.dart';
import 'util/auth_helper.dart';


// import 'screens/signup_page.dart'; // 필요시

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 화면 방향 설정 (비동기로 처리하여 블로킹 방지)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 에러 핸들링 추가
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('Flutter 에러: ${details.exception}');
  };

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '칼로리 트래커',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // [참고] 로그인/회원가입 테마와 앱 내부 테마를 여기서 함께 관리하거나,
        // 로그인 테마는 분홍색, 메인 앱 테마는 주황색으로 따로 관리할 수도 있습니다.
        // 여기서는 기존 주황색 테마를 유지하겠습니다.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
        // fontFamily: 'NotoSans', // 폰트가 없으면 주석 처리
        scaffoldBackgroundColor: Colors.white, // 기본 배경색 설정

        // (선택) 여기에 이전에 만들었던 '귀염뽀짝' 테마(버튼, 텍스트필드)를
        // 추가하면 로그인/회원가입 페이지에도 바로 적용됩니다!
      ),
      // [핵심] 앱 시작 시 스플래시 화면 표시 후 토큰 확인하여 자동 로그인
      home: const SplashScreen(
        child: AuthWrapper(),
      ),
      routes: {
        '/signup': (_) => const SignupPage(), // ✅ 회원가입 라우트
      },
    );
  }
}

/// 앱 시작 시 토큰을 확인하여 자동 로그인 처리
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await AuthHelper.isLoggedIn();
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // 로딩 중에는 스플래시 화면 표시
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 토큰이 있으면 MainScreen으로, 없으면 LoginPage로
    return _isLoggedIn ? const MainScreen() : const LoginPage();
  }
}