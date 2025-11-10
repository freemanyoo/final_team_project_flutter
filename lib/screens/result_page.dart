// lib/screens/result_page.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'restaurant_map_screen.dart'; // 지도 화면 import
import 'main_screen.dart'; // MainScreen import
import '../services/analysis_service.dart'; // YouTube 검색 서비스
import '../util/auth_helper.dart';
import '../widgets/bottom_nav.dart'; // BottomNav 위젯 import

class ResultPage extends StatefulWidget {
  final Map<String, dynamic> food;
  final VoidCallback onBack;

  const ResultPage({
    super.key,
    required this.food,
    required this.onBack,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  final TextEditingController _searchController = TextEditingController();
  String _sortOrder = 'relevance'; // 기본 정렬: relevance, viewCount, date
  List<dynamic> _youtubeRecipes = []; // YouTube 검색 결과
  bool _isSearching = false; // 검색 중 상태

  @override
  void initState() {
    super.initState();
    // 초기 YouTube 레시피 설정
    if (widget.food['youtubeRecipes'] != null && widget.food['youtubeRecipes'] is List) {
      _youtubeRecipes = widget.food['youtubeRecipes'] as List<dynamic>;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 영양소 값 가져오기 헬퍼 함수
  static String? _getNutritionValue(Map<String, dynamic> food, String key) {
    if (food['nutrition'] == null) return null;
    final nutrition = food['nutrition'] as Map<String, dynamic>;
    final value = nutrition[key];
    if (value == null) return null;
    
    // double 또는 int를 문자열로 변환
    if (value is double) {
      return '${value.toStringAsFixed(1)}g';
    } else if (value is int) {
      return '${value}g';
    } else if (value is num) {
      return '${value.toStringAsFixed(1)}g';
    }
    return null;
  }

  void _handleSwipeBack() {
    // MainScreen으로 돌아가기
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false, // 모든 이전 라우트 제거
    );
  }

  /// YouTube 레시피 검색
  Future<void> _searchYouTubeRecipes() async {
    if (_isSearching) return; // 이미 검색 중이면 무시

    setState(() {
      _isSearching = true;
    });

    try {
      final foodName = widget.food['name'] as String? ?? '음식';
      final keyword = _searchController.text.trim();
      
      final results = await AnalysisService().searchYouTubeRecipes(
        foodName: foodName,
        keyword: keyword.isEmpty ? null : keyword,
        order: _sortOrder,
      );

      if (mounted) {
        setState(() {
          _youtubeRecipes = results;
          _isSearching = false;
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${results.length}개의 레시피를 찾았습니다.'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('검색 중 오류가 발생했습니다: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final food = widget.food;
    final imagePath = food['imagePath'] as String?;
    final youtubeRecipes = _youtubeRecipes;
    final defaultFoodName = food['name'] ?? '음식';

    return GestureDetector(
      // 좌우 스와이프 제스처 감지
      onHorizontalDragEnd: (details) {
        // 오른쪽으로 스와이프 (왼쪽에서 오른쪽으로 드래그)
        // 속도가 500 이상이면 스와이프로 인식
        if (details.primaryVelocity != null && details.primaryVelocity! > 500) {
          _handleSwipeBack();
        }
      },
      // 세로 스크롤과 충돌하지 않도록 behavior 설정
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNav(
        currentIndex: -1, // ResultPage는 별도 페이지이므로 활성 탭 없음
        onTap: (index) {
          // MainScreen으로 이동하면서 선택한 탭으로 전환
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => MainScreen(initialIndex: index),
            ),
            (route) => false,
          );
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  // 이미지 표시 (imagePath가 있으면 이미지, 없으면 기본 배경)
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: imagePath == null
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1a3344),
                                Color(0xFF0d1a22),
                              ],
                            )
                          : null,
                      color: imagePath != null ? Colors.black : null,
                    ),
                        child: imagePath != null && imagePath is String
                            ? Image.file(
                                File(imagePath as String),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Text(
                                      '🍝',
                                      style: TextStyle(fontSize: 80),
                                    ),
                                  );
                                },
                                cacheWidth: (MediaQuery.of(context).size.width * 2).toInt(),
                                filterQuality: FilterQuality.medium,
                              )
                        : const Center(
                            child: Text(
                              '🍝',
                              style: TextStyle(fontSize: 80),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.black),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              // MainScreen으로 돌아가기
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const MainScreen()),
                                (route) => false, // 모든 이전 라우트 제거
                              );
                            },
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          child: IconButton(
                            icon: const Icon(Icons.more_vert, color: Colors.black),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '📅 오늘, 3:09 오후',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 이미지 아래에 분석된 음식 이름 표시
                    Center(
                      child: Text(
                        '${food['name'] ?? '알 수 없음'} 아닌가요?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a3344),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 상위 3개 예측 결과 확률 표시
                    if (food['top3'] != null && food['top3'] is List && (food['top3'] as List).isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.analytics, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  '🎯 분석 결과',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // 상위 3개 결과 표시 (확률이 0.01% 이상인 항목만 표시)
                            Builder(
                              builder: (context) {
                                // 확률이 0.01% 이상인 항목만 필터링
                                final validResults = (food['top3'] as List)
                                    .where((item) {
                                      if (item is! Map) return false;
                                      final confidence = item['confidence'] is num 
                                          ? (item['confidence'] as num).toDouble() 
                                          : 0.0;
                                      return confidence >= 0.01;
                                    })
                                    .toList();
                                
                                if (validResults.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                
                                return Column(
                                  children: validResults.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final item = entry.value as Map;
                                    final medal = index == 0 ? '🥇' : index == 1 ? '🥈' : '🥉';
                                    final className = item['class'] ?? item['className'] ?? '알 수 없음';
                                    final confidence = item['confidence'] is num 
                                        ? (item['confidence'] as num).toDouble() 
                                        : 0.0;
                                    
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: index < validResults.length - 1 ? 12 : 0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '$medal $className',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1a3344),
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '${confidence.toStringAsFixed(2)}%',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          LinearProgressIndicator(
                                            value: confidence / 100.0,
                                            backgroundColor: Colors.green[100],
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              index == 0 
                                                  ? Colors.green[600]!
                                                  : index == 1 
                                                      ? Colors.green[400]!
                                                      : Colors.green[300]!,
                                            ),
                                            minHeight: 6,
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    // top3가 없으면 기존 정확도 표시
                    else if (food['accuracy'] != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.analytics, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  '🎯 분석 결과',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // 정확도를 퍼센트로 표시
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: (food['accuracy'] is num) 
                                        ? (food['accuracy'] as num).toDouble() / 100.0
                                        : 0.0,
                                    backgroundColor: Colors.green[100],
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${(food['accuracy'] is num) ? (food['accuracy'] as num).toStringAsFixed(1) : '0.0'}%',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '칼로리 & 매크로',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // 칼로리만 표시 (정확도 제거)
                          _MacroCard(
                            label: '칼로리',
                            value: food['calories'] != null && food['calories'] > 0
                                ? '${food['calories']} kcal'
                                : food['nutrition'] != null && food['nutrition']['calories'] != null
                                    ? '${food['nutrition']['calories'].toStringAsFixed(0)} kcal'
                                    : '-',
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _MacroCardSmall(
                                  label: '탄수화물',
                                  icon: '🌾',
                                  value: _getNutritionValue(food, 'carbohydrates'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _MacroCardSmall(
                                  label: '단백질',
                                  icon: '🥩',
                                  value: _getNutritionValue(food, 'protein'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _MacroCardSmall(
                                  label: '지방',
                                  icon: '🥑',
                                  value: _getNutritionValue(food, 'fat'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 💡 새로 추가된 "내 주변 찾기" 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // 지도 화면으로 이동하면서 음식 이름 전달
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RestaurantMapScreen(
                                foodName: food['name'], // 분석된 음식 이름 전달
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.location_on),
                        label: const Text(
                          '내 주변 찾기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1a3344),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 검색 입력창 (placeholder에 분석된 음식 이름 표시)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '검색어 + $defaultFoodName 검색',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                    });
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 검색하기 버튼과 정렬기준 버튼
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isSearching ? null : _searchYouTubeRecipes,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1a3344),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: Colors.grey[400],
                            ),
                            child: _isSearching
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    '검색하기',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // 정렬 기준 선택 다이얼로그
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('정렬 기준'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      RadioListTile<String>(
                                        title: const Text('관련도순'),
                                        value: 'relevance',
                                        groupValue: _sortOrder,
                                        onChanged: (value) {
                                          setState(() {
                                            _sortOrder = value!;
                                          });
                                          Navigator.pop(context);
                                        },
                                      ),
                                      RadioListTile<String>(
                                        title: const Text('조회수순'),
                                        value: 'viewCount',
                                        groupValue: _sortOrder,
                                        onChanged: (value) {
                                          setState(() {
                                            _sortOrder = value!;
                                          });
                                          Navigator.pop(context);
                                        },
                                      ),
                                      RadioListTile<String>(
                                        title: const Text('최신순'),
                                        value: 'date',
                                        groupValue: _sortOrder,
                                        onChanged: (value) {
                                          setState(() {
                                            _sortOrder = value!;
                                          });
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              '정렬기준',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 유튜브 링크 표시
                    if (youtubeRecipes is List && youtubeRecipes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.play_circle_outline, color: Colors.red, size: 24),
                                const SizedBox(width: 8),
                                const Text(
                                  'YouTube 레시피',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...youtubeRecipes.map((recipe) {
                              // recipe가 Map인지 확인
                              if (recipe is! Map<String, dynamic>) {
                                return const SizedBox.shrink();
                              }
                              final recipeMap = recipe as Map<String, dynamic>;
                              final title = recipeMap['title']?.toString() ?? '레시피';
                              final videoId = recipeMap['videoId']?.toString();
                              final url = recipeMap['url']?.toString() ?? 
                                  (videoId != null ? 'https://www.youtube.com/watch?v=$videoId' : '');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: InkWell(
                                  onTap: () async {
                                    // YouTube 링크 열기
                                    if (url.isNotEmpty) {
                                      try {
                                        final uri = Uri.parse(url);
                                        await launchUrl(
                                          uri, 
                                          mode: LaunchMode.externalApplication,
                                        );
                                        
                                        // 링크 클릭 시 DB에 저장 (historyId가 있는 경우만)
                                        final historyId = widget.food['historyId'] as String?;
                                        if (historyId != null && historyId.isNotEmpty) {
                                          try {
                                            // 백엔드가 JWT에서 자동으로 userId를 추출하므로 userId를 전달하지 않음
                                            await AnalysisService().saveClickedYouTubeRecipe(
                                              userId: null, // 백엔드가 JWT에서 자동 추출
                                              historyId: historyId,
                                              title: title,
                                              url: url,
                                            );
                                          } catch (e) {
                                            // 저장 실패해도 링크는 열림 (에러 무시)
                                            print('YouTube 레시피 저장 실패: $e');
                                          }
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('링크를 열 수 없습니다.'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black87,
                                            decoration: TextDecoration.underline,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final String value;

  const _MacroCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroCardSmall extends StatelessWidget {
  final String label;
  final String icon;
  final String? value;

  const _MacroCardSmall({
    required this.label,
    required this.icon,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          value != null
              ? Text(
                  value!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 4),
              Text(
                '🔒',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}