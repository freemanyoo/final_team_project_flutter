import 'package:flutter/material.dart';

import 'main_screen.dart';
import 'home_page.dart';
import 'capture_page.dart';
import 'result_page.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginPage> {
  // 텍스트 필드 컨트롤러 (예시)
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('로그인 (임시)')), // AppBar가 있다면
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. "반가워요" 텍스트를 "음바페"로 변경
              const Text(
                '음밥해', // <-- 이 부분을 수정했습니다.
                style: TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent, // 음바페 유니폼 색상에 맞춰봤습니다.
                ),
              ),
              const SizedBox(height: 10),

              // 2. 고양이 발바닥 이미지를 um.png 파일로 변경
              // 예전 코드: Image.asset('assets/images/cat_paw.png', width: 100, height: 100),
              Image.asset(
                'assets/images/um2.png', // <-- 이미지 파일 경로를 수정했습니다.
                width: 240, // 이미지 크기는 필요에 따라 조절하세요
                height: 180,
                fit: BoxFit.cover, // 이미지 비율 유지
              ),
              const SizedBox(height: 40),

              // 이메일 입력 필드
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: '이메일',
                  hintText: '이메일을 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // 비밀번호 입력 필드
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: '비밀번호',
                  hintText: '비밀번호를 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true, // 비밀번호 가리기
              ),
              const SizedBox(height: 30),

              // 로그인 버튼
              ElevatedButton(
                onPressed: () {
                  // 💡 (참고) 실제 로그인 성공 시 MainScreen으로 이동
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // 버튼 너비를 최대로
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.blueAccent, // 버튼 색상
                  foregroundColor: Colors.white, // 텍스트 색상
                ),
                child: const Text(
                  '로그인',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),


              // 회원가입 텍스트 버튼
              TextButton(
                onPressed: () {
                  // 회원가입 화면으로 이동
                  print('회원가입');
                },
                // 💡 1. TextButton의 child는 Text 위젯 하나만 가져야 합니다.
                child: const Text(
                  '아직 계정이 없으신가요? 회원가입',
                  style: TextStyle(color: Colors.blueGrey),
                ),
              ), // 💡 2. TextButton이 여기서 닫혀야 합니다.

              // ---------------------------------------------
              // 💡 3. 임시 버튼들은 TextButton *밖* (Column의 자식)으로 이동
              // ---------------------------------------------
              const SizedBox(height: 10), // 구분선
              const Text('--- (개발용 임시 버튼) ---'),
              const SizedBox(height: 10),

              // 1. MainScreen (하단 네비게이션 포함)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                  );
                },
                child: const Text('메인 화면 (MainScreen) 가기'),
              ),
              const SizedBox(height: 10),

              // 2. HomePage (펭귄)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[300]),
                onPressed: () {
                  // HomePage는 onCapture 콜백이 필요하므로 임시 함수를 전달
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage(onCapture: () {
                      print("HomePage에서 카메라 버튼 눌림 (임시)");
                    })),
                  );
                },
                child: const Text('홈 (HomePage) 가기'),
              ),
              const SizedBox(height: 10),

              // 3. CapturePage (사진 촬영)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[300]),
                onPressed: () {
                  // CapturePage는 onFoodDetected 콜백이 필요
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CapturePage(onFoodDetected: (food) {
                      print("CapturePage에서 음식 인식됨 (임시): $food");
                      Navigator.pop(context); // 캡처 페이지 닫기
                    })),
                  );
                },
                child: const Text('사진 촬영 (CapturePage) 가기'),
              ),
              const SizedBox(height: 10),

              // 4. ResultPage (결과)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[300]),
                onPressed: () {
                  // ResultPage는 food 데이터와 onBack 콜백이 필요
                  final dummyFood = {
                    'name': '임시 음식',
                    'calories': 500,
                    'weight': 200,
                    'rating': 5,
                  };
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ResultPage(
                      food: dummyFood,
                      onBack: () {
                        Navigator.pop(context); // 결과 페이지 닫기
                      },
                    )),
                  );
                },
                child: const Text('결과 (ResultPage) 가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}