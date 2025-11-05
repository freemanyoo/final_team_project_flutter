// ==================== lib/screens/home_page.dart ====================
import 'package:flutter/material.dart';
// 💡 1. Lottie 패키지를 import 합니다. (이 줄이 추가되었습니다)
import 'package:lottie/lottie.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onCapture;

  const HomePage({super.key, required this.onCapture});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        // [수정 안 함] 바깥쪽 Stack (FloatingActionButton을 위함)
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                // [수정 안 함] 모든 UI 요소가 들어있는 메인 Column
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // [수정 안 함] 움짤과 뱃지가 들어갈 안쪽 Stack
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // 💡 2. 펭귄 CustomPaint가 있던 Container 수정
                        Container(
                          width: 250,
                          height: 250,
                          // 💡 펭귄 CustomPaint() 대신 Lottie.asset()으로 교체
                          child: Lottie.asset(
                            'assets/images/3D Chef Dancing.json', // .json 파일 경로
                            width: 250,
                            height: 250,
                            fit: BoxFit.contain, // 비율에 맞게 조절
                          ),
                        ),
                        // [수정 안 함] 뱃지 (Positioned)
                        Positioned(
                          top: -10,
                          right: -10,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.orange[300],
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Center(
                              child: Text(
                                '0',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // [수정 안 함] 이하 모든 버튼과 텍스트 위젯들은 그대로 유지됩니다.
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '소모됨: 0 KCAL',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Column(
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              const TextSpan(
                                text: '0',
                                style: TextStyle(color: Colors.black),
                              ),
                              TextSpan(
                                text: ' / 1500',
                                style: TextStyle(color: Colors.grey[300]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '섭취한 칼로리',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF9A56),
                            Color(0xFFFF6B9D),
                            Color(0xFFFE5E8E),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          '💬 더 많은 세부정보 보기',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🍎', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 8),
                          Text(
                            '기록됨: 0',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // [수정 안 함] 카메라 버튼 (FloatingActionButton)
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: onCapture,
                backgroundColor: Colors.black,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 💡 3. 펭귄을 그리던 PenguinPainter 클래스는 삭제합니다. (이 부분을 지우세요)
// class PenguinPainter extends CustomPainter { ... }