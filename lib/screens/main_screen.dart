// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import 'simple_map_screen.dart'; // ⭐ 추가

/// MainScreen: 하단 네비게이션을 포함한 메인 화면
class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // 각 탭에 해당하는 화면들
  final List<Widget> _screens = [
    const HomeTab(),        // 0: 홈
    const HistoryTab(),     // 1: 이력
    const SimpleMapScreen(), // 2: maps (⭐ 수정됨)
    const ProfileTab(),     // 3: 내 정보
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
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

// 임시 탭 화면들
class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('홈')),
      body: const Center(child: Text('홈 화면')),
    );
  }
}

class HistoryTab extends StatelessWidget {
  const HistoryTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이력')),
      body: const Center(child: Text('이력 화면')),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 정보')),
      body: const Center(child: Text('내 정보 화면')),
    );
  }
}