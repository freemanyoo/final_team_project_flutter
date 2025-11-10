// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import './home_page.dart';
import './my_page.dart' show MyPage, MyPageState; // 마이페이지 import
import './nutrition_page.dart'; // 영양소 페이지 import
import './restaurant_search_page.dart'; // 맛집 검색 페이지 import
import '../widgets/bottom_nav.dart'; // '../'는 상위 폴더(lib)로 나간다는 의미

class MainScreen extends StatefulWidget {
  final int? initialIndex;
  
  const MainScreen({super.key, this.initialIndex});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  final GlobalKey<MyPageState> _myPageKey = GlobalKey<MyPageState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    // MainScreen이 생성될 때 MyPage가 이미 생성되어 있다면 새로고침
    // 하지만 IndexedStack을 사용하므로 initState에서는 아직 생성되지 않았을 수 있음
    // 따라서 첫 프레임 후에 체크
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentIndex == 3 && _myPageKey.currentState != null) {
        _myPageKey.currentState!.loadUserInfoAndHistory();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 첫 번째 탭(인덱스 0)이 HomePage로 변경됨
    // 다른 페이지들의 상태는 IndexedStack으로 유지됨
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // 인덱스 0: HomePage (캡처 페이지가 홈 페이지로 변경됨)
          HomePage(
            onFoodDetected: (food) {
              // HomePage에서 ResultPage로 직접 이동하므로, 여기서는 아무것도 하지 않음
              print('✅ MainScreen: 분석 완료 (네비게이션은 HomePage에서 수행)');
            },
            onBack: null, // IndexedStack 내부에서는 뒤로가기 불필요 (탭 전환으로 처리)
          ),
          const NutritionPage(), // 영양소 페이지 (인덱스 1)
          const RestaurantSearchPage(), // 맛집 검색 페이지 (인덱스 2 - maps 탭)
          MyPage(key: _myPageKey), // 마이페이지 (인덱스 3) - GlobalKey로 새로고침 가능
        ],
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            // MyPage 탭이 선택되면 사용자 정보 새로고침
            if (index == 3 && _myPageKey.currentState != null) {
              _myPageKey.currentState!.loadUserInfoAndHistory();
            }
          });
        },
      ),
    );
  }
}
