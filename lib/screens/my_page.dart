// lib/screens/my_page.dart
import 'package:flutter/material.dart';
import 'login_page.dart';
import '../services/analysis_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  List<dynamic> _historyList = [];
  bool _isLoading = true;
  final int _userId = 1; // TODO: 실제 사용자 ID로 변경
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final history = await AnalysisService().getAnalysisHistory(
        userId: _userId,
        page: 0,
        size: 20,
      );
      if (mounted) {
        setState(() {
          _historyList = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ 히스토리 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '마이페이지',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1a3344),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 프로필 섹션 (축소)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // 24에서 16, 12로 축소
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 프로필 이미지 (축소)
                  CircleAvatar(
                    radius: 30, // 50에서 30으로 축소
                    backgroundColor: const Color(0xFF1a3344),
                    child: const Icon(
                      Icons.person,
                      size: 30, // 50에서 30으로 축소
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 사용자 정보 (세로 배치)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 사용자 이름 (임시)
                        const Text(
                          '사용자',
                          style: TextStyle(
                            fontSize: 18, // 24에서 18로 축소
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1a3344),
                          ),
                        ),
                        const SizedBox(height: 4), // 8에서 4로 축소
                        // 이메일 (임시)
                        Text(
                          'user@example.com',
                          style: TextStyle(
                            fontSize: 12, // 14에서 12로 축소
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 로그아웃 버튼 (작게)
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('로그아웃'),
                          content: const Text('정말 로그아웃하시겠습니까?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: const Text(
                                '로그아웃',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1a3344),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // 24, 8에서 16, 6으로 축소
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(0, 36), // 최소 높이 설정
                    ),
                    child: const Text(
                      '로그아웃',
                      style: TextStyle(
                        fontSize: 12, // 14에서 12로 축소
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16), // 24에서 16으로 축소
            // 분석 히스토리 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '분석 이력',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1a3344),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _historyList.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Center(
                                child: Text(
                                  '분석 이력이 없습니다.',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : SizedBox(
                              height: MediaQuery.of(context).size.height * 0.65, // 화면 높이의 65%로 증가
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: _historyList.length,
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentPage = index;
                                  });
                                },
                                itemBuilder: (context, index) {
                                  return _buildHistoryItem(_historyList[index], index);
                                },
                              ),
                            ),
                  // 페이지 인디케이터
                  if (!_isLoading && _historyList.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 0), // 16에서 8로 축소
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _historyList.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == _currentPage
                                  ? const Color(0xFF1a3344)
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(dynamic history, int index) {
    final historyId = history['historyId']?.toString() ?? '';
    final foodName = history['recognizedFoodName']?.toString() ?? '알 수 없음';
    final accuracy = history['accuracy'] != null
        ? (history['accuracy'] as num).toDouble() * 100
        : 0.0;
    final analysisDate = history['analysisDate']?.toString() ?? '';
    
    // YouTube 레시피 데이터 확인
    final youtubeRecipesRaw = history['youtubeRecipes'];
    print('📦 히스토리 $historyId - youtubeRecipes 타입: ${youtubeRecipesRaw.runtimeType}');
    print('📦 히스토리 $historyId - youtubeRecipes 값: $youtubeRecipesRaw');
    
    final youtubeRecipes = youtubeRecipesRaw is List 
        ? youtubeRecipesRaw 
        : (youtubeRecipesRaw != null ? [youtubeRecipesRaw] : <dynamic>[]);
    
    print('📦 히스토리 $historyId - 변환된 레시피 개수: ${youtubeRecipes.length}');

    // 날짜 포맷팅
    String formattedDate = '';
    try {
      if (analysisDate.isNotEmpty) {
        final dateTime = DateTime.parse(analysisDate);
        formattedDate = DateFormat('yyyy.MM.dd HH:mm').format(dateTime);
      }
    } catch (e) {
      formattedDate = analysisDate;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지와 정보를 가로로 배치
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽: 이미지 (고정 크기, 안 짤리게)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: historyId.isNotEmpty
                    ? Image.network(
                        AnalysisService.getThumbnailUrl(historyId),
                        width: 120, // 고정 너비
                        height: 120, // 고정 높이 (정사각형)
                        fit: BoxFit.cover, // 비율 유지하며 채우기
                        headers: const {
                          'Accept': 'image/*',
                        },
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.image, color: Colors.grey, size: 48),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.image, color: Colors.grey, size: 48),
                      ),
              ),
              const SizedBox(width: 16),
              // 오른쪽: 분석 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 음식 이름
                    Text(
                      foodName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1a3344),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // 정확도
                    Text(
                      '정확도: ${accuracy.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // 날짜
                    if (formattedDate.isNotEmpty)
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // YouTube 레시피 목록
          if (youtubeRecipes.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.play_circle_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'YouTube 레시피',
                  style: TextStyle(
                    fontSize: 16, // 18에서 16으로 축소
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...youtubeRecipes.map((recipe) {
              final recipeMap = recipe as Map<String, dynamic>? ?? {};
              final title = recipeMap['title']?.toString() ?? '레시피';
              final url = recipeMap['url']?.toString() ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8), // 12에서 8로 축소
                child: InkWell(
                  onTap: () async {
                    if (url.isNotEmpty) {
                      try {
                        // YouTube 링크 열기
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          
                          // 링크 클릭 시 DB에 저장
                          try {
                            await AnalysisService().saveClickedYouTubeRecipe(
                              userId: _userId,
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
                  child: Container(
                    padding: const EdgeInsets.all(10), // 12에서 10으로 축소
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13, // 14에서 13으로 축소
                              color: Colors.black87,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '레시피 정보가 없습니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

