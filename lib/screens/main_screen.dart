// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import './home_page.dart'; // './'는 같은 screens 폴더라는 의미
import './capture_page.dart';
import './my_page.dart'; // 마이페이지 import
import '../widgets/bottom_nav.dart'; // '../'는 상위 폴더(lib)로 나간다는 의미

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _navigateToCapture() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CapturePage(
          onFoodDetected: (food) {
            // CapturePage에서 ResultPage로 직접 이동하므로, 여기서는 아무것도 하지 않음
            // 이 콜백은 MainScreen에 분석 완료를 알리는 용도로만 사용됨
            print('✅ MainScreen: 분석 완료 (네비게이션은 CapturePage에서 수행)');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomePage(onCapture: _navigateToCapture),
          const Center(child: Text('단식', style: TextStyle(fontSize: 24))),
          const Center(child: Text('이력', style: TextStyle(fontSize: 24))),
          const MyPage(), // 마이페이지 (인덱스 3)
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
