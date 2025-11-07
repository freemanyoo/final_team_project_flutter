// lib/screens/signup_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/login_controller.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _c = LoginController();

  final _userId = TextEditingController();
  final _email = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  XFile? _picked;

  @override
  void dispose() {
    _userId.dispose();
    _email.dispose();
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (x != null) setState(() => _picked = x);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _c.signup(
      userId: _userId.text,
      email: _email.text,
      password: _pw.text,
      profileImage: _picked,
      onSuccess: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공! 로그인 해주세요.')),
        );
        Navigator.of(context).pop();
      },
      onError: _showError,
      passwordConfirm: _pw.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _picked == null ? null : Image.file(File(_picked!.path), height: 80);

    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _userId,
                decoration: const InputDecoration(labelText: '아이디'),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? '아이디를 입력하세요' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: '이메일'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '이메일을 입력하세요';
                  if (!v.contains('@')) return '올바른 이메일을 입력하세요';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pw,
                decoration: const InputDecoration(labelText: '비밀번호'),
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.isEmpty) ? '비밀번호를 입력하세요' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pw2,
                decoration: const InputDecoration(labelText: '비밀번호 확인'),
                obscureText: true,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) {
                  if (v == null || v.isEmpty) return '비밀번호 확인을 입력하세요';
                  if (v != _pw.text) return '비밀번호가 일치하지 않습니다';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('프로필 이미지 선택(선택)'),
                  ),
                  const SizedBox(width: 12),
                  if (preview != null) preview,
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('회원가입 완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
