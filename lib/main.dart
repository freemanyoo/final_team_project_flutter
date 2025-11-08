// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// [핵심] 로그인 페이지와 회원가입 페이지를 import 합니다.
// (이 파일들을 lib/screens/ 폴더로 옮기는 것을 추천합니다!)
import 'screens/login_page.dart';
import 'screens/signup_page.dart';


// import 'screens/signup_page.dart'; // 필요시

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
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
      // [핵심] 앱의 첫 화면을 MainScreen이 아닌 LoginPage로 변경합니다.
      home: LoginPage(),
      routes: {
        '/signup': (_) => const SignupPage(), // ✅ 회원가입 라우트
      },
    );
  }
}