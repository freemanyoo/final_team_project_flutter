// lib/screens/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/login_controller.dart';
import 'main_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _id = TextEditingController();
  final _pw = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _c = LoginController();

  @override
  void initState() {
    super.initState();
    // 소셜 로그인 리다이렉트 리스너 시작
    _c.startLinkListener(onSuccess: _onLoginSuccess);
  }

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    _c.dispose();
    super.dispose();
  }

  void _onLoginSuccess() {
    if (!mounted) return;
    
    // 다음 프레임에서 네비게이션 (context 안정화 대기)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 성공!')),
      );
      
      // 스택을 정리하고 MainScreen으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false, // 모든 이전 라우트 제거
      );
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _c.loginWithPassword(
      userId: _id.text,
      password: _pw.text,
      onSuccess: _onLoginSuccess,
      onError: _showError,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _id,
                decoration: const InputDecoration(labelText: '아이디'),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? '아이디를 입력하세요' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pw,
                decoration: const InputDecoration(labelText: '비밀번호'),
                obscureText: true,
                onFieldSubmitted: (_) => _submit(), // 엔터로 로그인
                validator: (v) => (v == null || v.isEmpty) ? '비밀번호를 입력하세요' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit, // 클릭으로 로그인
                child: const Text('아이디로 로그인'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _c.loginWithSocial(
                        provider: 'google',
                        onError: _showError,
                      ),
                      child: const Text('Google로 로그인'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _c.loginWithSocial(
                        provider: 'naver',
                        onError: _showError,
                      ),
                      child: const Text('Naver로 로그인'),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/signup'),
                child: const Text('회원가입'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
