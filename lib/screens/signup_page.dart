// lib/screens/signup_page.dart
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool _isPasswordObscure = true;
  bool _isConfirmPasswordObscure = true;

  @override
  Widget build(BuildContext context) {
    // [참고] main.dart의 테마가 자동으로 적용됩니다.
    return Scaffold(
      resizeToAvoidBottomInset: true,
      // AppBar가 있으면 자동으로 '뒤로가기' 버튼이 생깁니다.
      appBar: AppBar(
        title: Text('회원가입'),
        backgroundColor: Colors.transparent, // 배경 투명
        elevation: 0, // 그림자 제거
        // AppBar의 아이콘/글자 색상은 테마에 따라 자동 설정됩니다.
        // 만약 색상이 어색하다면 아래 주석을 풀어서 직접 지정하세요.
        // foregroundColor: Colors.pink[400],
        // iconTheme: IconThemeData(color: Colors.pink[400]),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '환영합니다!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  // 테마의 primary 색상(주황색)을 따르도록 설정
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: 48),

              // [참고] 텍스트 필드 스타일은 main.dart의 테마가 적용됩니다.
              // 만약 핑크 테마를 원하시면 main.dart의 inputDecorationTheme을 수정해야 합니다.
              TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: '이메일',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                obscureText: _isPasswordObscure,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline),
                  hintText: '비밀번호',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordObscure = !_isPasswordObscure;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                obscureText: _isConfirmPasswordObscure,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.check_circle_outline),
                  hintText: '비밀번호 확인',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordObscure = !_isConfirmPasswordObscure;
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 32),

              // [참고] 버튼 스타일도 main.dart의 테마가 적용됩니다.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: 실제 회원가입 로직 구현
                    print('회원가입 버튼 클릭됨');

                    // 회원가입 성공 후 로그인 페이지로 돌아가기
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  child: Text('회원가입 완료!', style: TextStyle(fontSize: 18)),
                ),
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // [핵심] 현재 페이지를 닫고 이전 페이지(로그인)로 돌아갑니다.
                  Navigator.pop(context);
                },
                child: Text(
                  '이미 계정이 있으신가요? 로그인',
                  // 글자색도 테마에 맞게 설정
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}