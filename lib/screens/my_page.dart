// lib/screens/my_page.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'login_page.dart';
import '../services/analysis_service.dart';
import '../util/auth_helper.dart';
import '../core/config/api_config.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => MyPageState();
}

class MyPageState extends State<MyPage> {
  List<dynamic> _historyList = [];
  bool _isLoading = true;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // 사용자 정보
  String? _displayUserId;
  String? _displayEmail;
  List<String> _oauthProviders = [];
  bool _isOAuthUser = false;
  String? _profileImageId; // 프로필 이미지 ID

  @override
  void initState() {
    super.initState();
    loadUserInfoAndHistory();
  }

  /// 사용자 정보를 로드한 후 히스토리 로드
  /// MainScreen에서 탭이 변경될 때 호출할 수 있도록 public으로 유지
  Future<void> loadUserInfoAndHistory() async {
    // 1. 사용자 정보 API 호출
    await _loadUserInfo();
    
    // 2. 히스토리 로드 (백엔드가 JWT에서 자동으로 userId를 추출)
    // 로그인 상태 확인
    final isLoggedIn = await AuthHelper.isLoggedIn();
    if (mounted) {
      if (isLoggedIn) {
        _loadHistory();
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인이 필요합니다.')),
          );
        }
      }
    }
  }

  /// 백엔드 API를 호출하여 사용자 정보 가져오기
  Future<void> _loadUserInfo() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'accessToken');
      if (token == null || token.isEmpty) {
        return;
      }

      final baseUrl = ApiConfig.apiBaseUrl;
      final url = Uri.parse('$baseUrl/api/users/me');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('사용자 정보 조회 시간 초과');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('🔍 사용자 정보 응답:');
        print('   userId: ${data['userId']}');
        print('   email: ${data['email']}');
        print('   oauthProviders: ${data['oauthProviders']}');
        print('   isOAuthUser: ${data['isOAuthUser']}');
        print('   profileImageId: ${data['profileImageId']}');
        
        final oauthProvidersList = (data['oauthProviders'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ?? [];
        // 백엔드의 isOAuthUser를 사용하되, null이면 oauthProviders 리스트로 판단
        final isOAuthUserValue = data['isOAuthUser'] as bool? ?? (oauthProvidersList.isNotEmpty);
        
        print('🔍 파싱된 값:');
        print('   oauthProviders: $oauthProvidersList');
        print('   isOAuthUser (원본): ${data['isOAuthUser']}');
        print('   isOAuthUser (최종): $isOAuthUserValue (oauthProviders.isEmpty: ${oauthProvidersList.isEmpty})');
        
        if (mounted) {
          setState(() {
            _displayUserId = data['userId'] as String?;
            _displayEmail = data['email'] as String?;
            _oauthProviders = oauthProvidersList;
            // oauthProviders가 비어있지 않으면 OAuth 사용자로 판단
            _isOAuthUser = oauthProvidersList.isNotEmpty;
            _profileImageId = data['profileImageId'] as String?;
          });
        }
        
        print('✅ 상태 업데이트 완료:');
        print('   _oauthProviders: $_oauthProviders');
        print('   _isOAuthUser: $_isOAuthUser');
      } else {
        print('⚠️ 사용자 정보 조회 실패: ${response.statusCode}');
        print('   응답 본문: ${response.body}');
      }
    } catch (e) {
      print('❌ 사용자 정보 조회 오류: $e');
      // 오류가 발생해도 계속 진행 (기본값 사용)
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    // userId가 null이어도 백엔드가 JWT에서 자동으로 추출하므로 호출 가능
    setState(() {
      _isLoading = true;
    });

    try {
      // 백엔드가 JWT에서 자동으로 userId를 추출하므로 userId를 전달하지 않음
      final history = await AnalysisService().getAnalysisHistory(
        userId: null, // 백엔드가 JWT에서 자동 추출
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
      backgroundColor: Colors.white,
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
                  _profileImageId != null && _profileImageId!.isNotEmpty
                      ? CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFF1a3344),
                          backgroundImage: NetworkImage(
                            '${ApiConfig.apiBaseUrl}/images/profile/${_profileImageId}',
                          ),
                          onBackgroundImageError: (exception, stackTrace) {
                            // 이미지 로드 실패 시 기본 아이콘 표시
                            print('⚠️ 프로필 이미지 로드 실패: $exception');
                          },
                        )
                      : CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFF1a3344),
                          child: const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                  const SizedBox(width: 12),
                  // 사용자 정보 (세로 배치)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 사용자 이름/ID (가로 배치: 아이콘 + 텍스트)
                        Row(
                          children: [
                            // 로그인 타입 아이콘
                            if (_isOAuthUser && _oauthProviders.isNotEmpty) ...[
                              // 구글 아이콘
                              if (_oauthProviders.contains('google'))
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.g_mobiledata,
                                    size: 16,
                                    color: Color(0xFF4285F4),
                                  ),
                                ),
                              // 네이버 아이콘
                              if (_oauthProviders.contains('naver'))
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF03C75A),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'N',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 6),
                            ] else ...[
                              // 일반 가입자 아이콘
                              const Icon(
                                Icons.person,
                                size: 18,
                                color: Color(0xFF1a3344),
                              ),
                              const SizedBox(width: 6),
                            ],
                            // 사용자 이름/ID 텍스트
                            Expanded(
                              child: Text(
                                _isOAuthUser && _oauthProviders.isNotEmpty
                                    ? _oauthProviders.map((p) {
                                        if (p == 'google') return '구글';
                                        if (p == 'naver') return '네이버';
                                        return p;
                                      }).join(', ')
                                    : (_displayUserId ?? '사용자'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1a3344),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // 로그인 타입 배지
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (_isOAuthUser && _oauthProviders.isNotEmpty) ...[
                              // OAuth2 배지
                              for (String provider in _oauthProviders)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: provider == 'google'
                                        ? const Color(0xFF4285F4).withOpacity(0.1)
                                        : provider == 'naver'
                                            ? const Color(0xFF03C75A).withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: provider == 'google'
                                          ? const Color(0xFF4285F4)
                                          : provider == 'naver'
                                              ? const Color(0xFF03C75A)
                                              : Colors.grey,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        provider == 'google'
                                            ? '구글'
                                            : provider == 'naver'
                                                ? '네이버'
                                                : provider,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: provider == 'google'
                                              ? const Color(0xFF4285F4)
                                              : provider == 'naver'
                                                  ? const Color(0xFF03C75A)
                                                  : Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ] else ...[
                              // 일반 가입자 배지
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  '일반 가입',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // 이메일 표시
                        Text(
                          _displayEmail ?? 'user@example.com',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                              onPressed: () async {
                                Navigator.pop(context);
                                // 토큰 삭제
                                const storage = FlutterSecureStorage();
                                await storage.delete(key: 'accessToken');
                                await storage.delete(key: 'refreshToken');
                                print('✅ 로그아웃 완료 - 토큰 삭제됨');
                                // 로그인 페이지로 리다이렉트
                                if (mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                    (route) => false,
                                  );
                                }
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
                          : Column(
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.5, // 높이 조정하여 페이징이 보이도록
                                  child: PageView.builder(
                                    controller: _pageController,
                                    itemCount: _historyList.length,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentPage = index;
                                      });
                                    },
                                    itemBuilder: (context, index) {
                                      // 현재 페이지만 이미지 로드 (ImageReader 경고 방지)
                                      final isCurrentPage = index == _currentPage;
                                      return _buildHistoryItem(_historyList[index], index, shouldLoadImage: isCurrentPage);
                                    },
                                  ),
                                ),
                                // 페이지 인디케이터를 PageView 바로 아래로 이동
                                if (!_isLoading && _historyList.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(dynamic history, int index, {bool shouldLoadImage = true}) {
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

    // MediaQuery 값을 미리 계산하여 불필요한 리빌드 방지
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.4;
    final cacheSize = (imageSize * 2).toInt();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지와 정보를 가로로 배치
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽: 이미지 (화면 너비의 중간 정도)
              // ImageReader 경고 방지를 위해 이미지 로딩을 완전히 비활성화하고 플레이스홀더만 사용
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: historyId.isNotEmpty && shouldLoadImage
                      ? FutureBuilder<ImageProvider?>(
                          future: _loadImageAsync(historyId, imageSize),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return Image(
                                image: snapshot.data!,
                                width: imageSize,
                                height: imageSize,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.low,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.image, color: Colors.grey, size: 48);
                                },
                              );
                            }
                            return _buildImagePlaceholder(imageSize);
                          },
                        )
                      : const Icon(Icons.image, color: Colors.grey, size: 48),
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
                          
                          // 링크 클릭 시 DB에 저장 (백엔드가 JWT에서 자동으로 userId 추출)
                          try {
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

  Widget _buildImagePlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  // 이미지를 비동기로 로드하여 ImageReader 경고 방지
  // ImageReader 경고를 완전히 방지하기 위해 이미지 로딩을 최소화
  Future<ImageProvider?> _loadImageAsync(String historyId, double imageSize) async {
    try {
      final url = AnalysisService.getThumbnailUrl(historyId);
      
      // NetworkImage를 생성
      final imageProvider = NetworkImage(
        url,
        headers: const {'Accept': 'image/*'},
      );
      
      // 이미지가 실제로 로드될 때까지 대기 (타임아웃 설정)
      final imageStream = imageProvider.resolve(ImageConfiguration(
        size: Size(imageSize, imageSize),
      ));
      
      // Completer를 사용하여 이미지 로딩 완료를 기다림
      final completer = Completer<ImageInfo>();
      late ImageStreamListener listener;
      
      listener = ImageStreamListener((ImageInfo imageInfo, bool synchronousCall) {
        if (!completer.isCompleted) {
          completer.complete(imageInfo);
          imageStream.removeListener(listener);
        }
      }, onError: (exception, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(exception, stackTrace);
          imageStream.removeListener(listener);
        }
      });
      
      imageStream.addListener(listener);
      
      try {
        await completer.future.timeout(
          const Duration(seconds: 5),
        );
        return imageProvider;
      } on TimeoutException {
        imageStream.removeListener(listener);
        print('이미지 로드 타임아웃: $url');
        return null;
      }
    } catch (e) {
      print('이미지 로드 오류: $e');
      return null;
    }
  }
}

