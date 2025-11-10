// lib/services/analysis_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config/api_config.dart'; // 공통 설정 사용

class AnalysisService {
  // FlutterSecureStorage 인스턴스
  static const _storage = FlutterSecureStorage();
  
  /// 인증 헤더 가져오기 (JWT 토큰 포함)
  /// 토큰이 있으면 Authorization 헤더를 포함하고, 없으면 빈 헤더 반환
  /// 주의: Multipart 요청에서는 Content-Type을 설정하지 않습니다 (자동으로 설정됨)
  Future<Map<String, String>> _getAuthHeaders() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token != null && token.isNotEmpty) {
        print('✅ JWT 토큰 발견 (길이: ${token.length})');
        return {
          'Authorization': 'Bearer $token',
          // Multipart 요청에서는 Content-Type을 설정하지 않음 (자동으로 multipart/form-data로 설정됨)
        };
      } else {
        print('⚠️ JWT 토큰이 없습니다.');
      }
    } catch (e) {
      print('⚠️ 토큰 읽기 오류: $e');
    }
    // 토큰이 없거나 오류가 발생한 경우 빈 헤더 반환
    return {};
  }
  /// 공통 설정에서 base URL 가져오기
  static String get baseUrl {
    final url = ApiConfig.getApiUrl('/api/analysis');
    // 디버그: 사용 중인 URL 출력
    ApiConfig.printCurrentUrl();
    print('🔗 AnalysisService baseUrl: $url');
    return url;
  }
  
  // 실제 기기에서 테스트 시 사용 (서버 IP 주소로 수동 변경)
  // 예: static String get baseUrl => 'http://192.168.0.100:8080/api/analysis';
  // 
  // 서버 IP 주소 확인 방법:
  // - macOS: ifconfig | grep "inet " | grep -v 127.0.0.1
  // - Windows: ipconfig
  // - Linux: hostname -I

  /// 이미지 분석 요청
  /// 
  /// [imageFile] 분석할 이미지 파일
  /// [userId] 사용자 ID (선택사항, JWT 토큰에서 자동으로 추출됨)
  /// [youtubeKeyword] YouTube 검색 키워드 (선택사항)
  /// [youtubeOrder] YouTube 정렬 옵션 (relevance, viewCount, date)
  Future<AnalysisResult> analyzeImage({
    required File imageFile,
    int? userId, // 선택적으로 변경 (백엔드가 JWT에서 자동 추출)
    String? youtubeKeyword,
    String youtubeOrder = 'relevance',
  }) async {
    final url = baseUrl; // URL 확인을 위해 변수에 저장 (catch 블록에서도 사용)
    try {
      print('📤 이미지 분석 요청 시작');
      print('   URL: $url');
      print('   파일: ${imageFile.path}');
      print('   사용자 ID: $userId');
      
      // Multipart 요청 생성
      var request = http.MultipartRequest('POST', Uri.parse(url));
      
      // 이미지 파일의 MIME 타입 확인
      String mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      
      // 파일 확장자로 MIME 타입 확인 (lookupMimeType이 null을 반환할 경우 대비)
      if (mimeType == 'application/octet-stream' || !mimeType.startsWith('image/')) {
        final extension = imageFile.path.toLowerCase().split('.').last;
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'png':
            mimeType = 'image/png';
            break;
          case 'gif':
            mimeType = 'image/gif';
            break;
          case 'webp':
            mimeType = 'image/webp';
            break;
          default:
            mimeType = 'image/jpeg'; // 기본값
        }
      }
      
      print('이미지 파일 MIME 타입: $mimeType');
      
      // 이미지 파일 추가 (MIME 타입 명시)
      // 파일을 읽어서 바이트로 변환
      print('📂 이미지 파일 읽기 시작...');
      print('   파일 경로: ${imageFile.path}');
      print('   파일 존재 여부: ${await imageFile.exists()}');
      final fileBytes = await imageFile.readAsBytes();
      print('✅ 이미지 파일 읽기 완료 (${fileBytes.length} bytes)');
      
      // MultipartFile.fromBytes 사용
      // filename에 확장자가 포함되어 있으면 Spring Boot가 파일 타입을 자동으로 감지합니다
      print('📦 MultipartFile 생성 중...');
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        fileBytes,
        filename: imageFile.path.split('/').last,
      );
      print('✅ MultipartFile 생성 완료');
      
      request.files.add(multipartFile);
      print('✅ 파일 추가 완료');
      
      // 파라미터 추가 (userId는 선택적, 백엔드가 JWT에서 자동 추출)
      if (userId != null) {
        request.fields['userId'] = userId.toString();
      }
      if (youtubeKeyword != null && youtubeKeyword.trim().isNotEmpty) {
        request.fields['youtubeKeyword'] = youtubeKeyword;
        request.fields['youtubeOrder'] = youtubeOrder;
      }
      
      // JWT 토큰을 헤더에 포함 (백엔드가 자동으로 userId 추출)
      final headers = await _getAuthHeaders();
      request.headers.addAll(headers);
      print('✅ 헤더 추가 완료');
      print('   헤더 개수: ${request.headers.length}');
      if (request.headers.containsKey('Authorization')) {
        final authHeader = request.headers['Authorization']!;
        print('   Authorization 헤더: ${authHeader.substring(0, authHeader.length > 50 ? 50 : authHeader.length)}...');
      } else {
        print('   ⚠️ Authorization 헤더가 없습니다!');
      }
      print('✅ 파라미터 추가 완료');

      // 요청 전송 전 서버 연결 테스트 (선택적)
      print('⏳ 서버 연결 테스트 중...');
      try {
        final testUrl = url.replaceAll('/api/analysis', '');
        final testResponse = await http.get(Uri.parse(testUrl)).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw AnalysisException('서버 연결 실패.\n\n확인 사항:\n1. 백엔드 서버가 실행 중인지 확인\n2. 서버 IP 주소가 올바른지 확인 (현재: $testUrl)\n3. 방화벽 설정 확인');
          },
        );
        print('✅ 서버 연결 확인 완료 (상태 코드: ${testResponse.statusCode})');
      } catch (e) {
        print('⚠️ 서버 연결 테스트 실패 (계속 진행): $e');
        // 연결 테스트 실패해도 실제 요청은 시도
      }

      // 요청 전송 (타임아웃 설정 - 이미지 분석은 시간이 오래 걸릴 수 있으므로 60초로 증가)
      print('⏳ 서버에 요청 전송 중...');
      print('   요청 URL: $url');
      print('   요청 필드 개수: ${request.fields.length}');
      print('   요청 파일 개수: ${request.files.length}');
      print('   요청 메서드: ${request.method}');
      
      http.Response response;
      try {
        print('📡 request.send() 호출 시작...');
        var streamedResponse = await request.send().timeout(
          const Duration(seconds: 60), // 30초에서 60초로 증가 (Flask AI 분석 시간 고려)
          onTimeout: () {
            print('❌ 타임아웃 발생! (60초)');
            throw AnalysisException('서버 응답 시간 초과 (60초).\n\n가능한 원인:\n1. 서버가 실행 중이지 않음\n2. Flask AI 서버 연결 문제\n3. 네트워크 연결 문제\n\n서버 IP 주소: ${url.replaceAll('/api/analysis', '')}');
          },
        );
        print('✅ 스트림 응답 수신 완료');
        print('📥 Response.fromStream() 호출 시작...');
        response = await http.Response.fromStream(streamedResponse).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw AnalysisException('응답 스트림 읽기 시간 초과');
          },
        );
        print('✅ HTTP 응답 객체 생성 완료');
      } catch (e) {
        print('❌❌❌ 요청 전송 중 에러 발생 ❌❌❌');
        print('에러 타입: ${e.runtimeType}');
        print('에러 메시지: $e');
        if (e is SocketException) {
          throw AnalysisException('서버에 연결할 수 없습니다.\n\n확인 사항:\n1. 백엔드 서버가 실행 중인지 확인\n2. 서버 IP 주소가 올바른지 확인 (현재: ${url.replaceAll('/api/analysis', '')})\n3. 방화벽 설정 확인\n4. 같은 네트워크에 연결되어 있는지 확인');
        }
        rethrow;
      }

      // 디버그 로그
      print('✅ API 응답 수신');
      print('   상태 코드: ${response.statusCode}');
      print('   응답 본문 길이: ${response.body.length} bytes');
      print('   응답 본문 내용: ${response.body}'); // 에러 메시지 확인

      // 응답 처리
      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw AnalysisException('서버에서 빈 응답을 받았습니다.');
        }
        
        try {
          final Map<String, dynamic> jsonResponse = json.decode(response.body);
          print('파싱된 JSON: $jsonResponse');
          return AnalysisResult.fromJson(jsonResponse);
        } catch (e) {
          print('JSON 파싱 오류: $e');
          throw AnalysisException('응답 파싱 오류: ${e.toString()}');
        }
      } else {
        // 에러 응답 파싱 시도
        try {
          final Map<String, dynamic> errorResponse = json.decode(response.body);
          throw AnalysisException(
            errorResponse['message'] ?? '분석 요청 실패',
            statusCode: response.statusCode,
          );
        } catch (_) {
          throw AnalysisException(
            '서버 오류: ${response.statusCode}',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      if (e is AnalysisException) {
        rethrow;
      }
      
      // Connection refused 오류에 대한 친절한 메시지
      String errorMessage = '네트워크 오류가 발생했습니다.';
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('errno = 61')) {
        errorMessage = '서버에 연결할 수 없습니다.\n\n'
            '확인 사항:\n'
            '1. 백엔드 서버가 실행 중인지 확인\n'
            '2. 서버가 0.0.0.0:8080에 바인딩되어 있는지 확인\n'
            '3. iOS 시뮬레이터의 경우 Mac의 실제 IP 주소 사용 필요\n'
            '   (현재 URL: $url)\n\n'
            '해결 방법:\n'
            '- Spring Boot 서버 재시작\n'
            '- application.properties에 server.address=0.0.0.0 설정 확인';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = '네트워크 연결 오류가 발생했습니다.\n'
            '인터넷 연결과 서버 상태를 확인해주세요.';
      } else {
        errorMessage = '네트워크 오류: ${e.toString()}';
      }
      
      throw AnalysisException(errorMessage);
    }
  }

  /// YouTube 레시피 검색 (검색어와 정렬 옵션 포함)
  Future<List<dynamic>> searchYouTubeRecipes({
    required String foodName,
    String? keyword,
    String order = 'relevance',
  }) async {
    // 공통 설정에서 base URL 사용
    final baseUrl = ApiConfig.baseUrl;
    final url = Uri.parse('$baseUrl/api/youtube/search').replace(
      queryParameters: {
        'foodName': foodName,
        if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
        'order': order,
      },
    );

    print('🔍 YouTube 검색 요청: $url');

    try {
      final response = await http.get(url).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw AnalysisException('YouTube 검색 요청 시간 초과');
        },
      );

      print('✅ YouTube 검색 응답 수신');
      print('   상태 코드: ${response.statusCode}');
      print('   응답 본문 길이: ${response.body.length} bytes');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        print('✅ YouTube 검색 결과: ${jsonData.length}개');
        return jsonData;
      } else {
        print('❌ YouTube 검색 실패: ${response.statusCode}');
        print('   응답 본문: ${response.body}');
        throw AnalysisException('YouTube 검색 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ YouTube 검색 오류: $e');
      if (e is AnalysisException) {
        rethrow;
      }
      throw AnalysisException('YouTube 검색 중 오류 발생: ${e.toString()}');
    }
  }

  /// 분석 히스토리 조회
  /// JWT 토큰에서 자동으로 사용자 ID를 추출합니다.
  Future<List<dynamic>> getAnalysisHistory({
    int? userId, // 선택적 파라미터로 변경 (백엔드가 JWT에서 자동 추출)
    int page = 0,
    int size = 10,
  }) async {
    // 일반 API용 base URL 사용 (로컬 서버)
    final baseUrl = ApiConfig.apiBaseUrl;
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    // userId는 선택적 (백엔드가 JWT에서 자동 추출하므로)
    // if (userId != null) {
    //   queryParams['userId'] = userId.toString();
    // }
    final url = Uri.parse('$baseUrl/api/analysis/history').replace(
      queryParameters: queryParams,
    );

    try {
      // JWT 토큰을 헤더에 포함
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw AnalysisException('분석 히스토리 조회 요청 시간 초과');
        },
      );

      if (response.statusCode == 200) {
        print('📦 분석 히스토리 응답 수신');
        print('   상태 코드: ${response.statusCode}');
        print('   응답 본문 길이: ${response.body.length} bytes');
        print('   응답 본문 (처음 500자): ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');
        
        final List<dynamic> jsonData = json.decode(response.body);
        
        // 각 히스토리 항목의 youtubeRecipes 확인
        for (var item in jsonData) {
          if (item is Map<String, dynamic>) {
            final historyId = item['historyId']?.toString() ?? 'unknown';
            final youtubeRecipes = item['youtubeRecipes'];
            print('📦 파싱된 데이터 - 히스토리 ID: $historyId');
            print('   youtubeRecipes 타입: ${youtubeRecipes.runtimeType}');
            print('   youtubeRecipes 값: $youtubeRecipes');
            if (youtubeRecipes is List) {
              print('   레시피 개수: ${youtubeRecipes.length}');
              for (var recipe in youtubeRecipes) {
                print('     - $recipe');
              }
            }
          }
        }
        
        return jsonData;
      } else {
        throw AnalysisException('분석 히스토리 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      if (e is AnalysisException) {
        rethrow;
      }
      throw AnalysisException('분석 히스토리 조회 중 오류 발생: ${e.toString()}');
    }
  }

  /// 썸네일 이미지 URL 생성
  static String getThumbnailUrl(String historyId) {
    return ApiConfig.getApiUrl('/api/analysis/thumbnail/$historyId');
  }

  /// YouTube 레시피 클릭 시 저장
  /// 백엔드가 JWT에서 자동으로 userId를 추출합니다.
  Future<void> saveClickedYouTubeRecipe({
    int? userId, // 선택적 파라미터 (백엔드가 JWT에서 자동 추출)
    required String historyId,
    required String title,
    required String url,
  }) async {
    // 일반 API용 base URL 사용 (로컬 서버)
    final baseUrl = ApiConfig.apiBaseUrl;
    final queryParams = <String, String>{
      'historyId': historyId,
      'title': title,
      'url': url,
    };
    // userId는 선택적 (백엔드가 JWT에서 자동 추출하므로)
    final uri = Uri.parse('$baseUrl/api/analysis/youtube-recipe/click').replace(
      queryParameters: queryParams,
    );

    try {
      // JWT 토큰을 헤더에 포함
      final headers = await _getAuthHeaders();
      print('🔍 YouTube 레시피 저장 요청:');
      print('   URL: $uri');
      print('   historyId: $historyId');
      print('   title: $title');
      print('   url: $url');
      print('   Authorization 헤더 존재: ${headers.containsKey('Authorization')}');
      
      final response = await http.post(uri, headers: headers).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw AnalysisException('YouTube 레시피 저장 요청 시간 초과');
        },
      );

      print('🔍 YouTube 레시피 저장 응답:');
      print('   상태 코드: ${response.statusCode}');
      print('   응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ YouTube 레시피 저장 성공');
        return;
      } else {
        print('❌ YouTube 레시피 저장 실패: ${response.statusCode}');
        throw AnalysisException('YouTube 레시피 저장 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ YouTube 레시피 저장 오류: $e');
      if (e is AnalysisException) {
        rethrow;
      }
      throw AnalysisException('YouTube 레시피 저장 중 오류 발생: ${e.toString()}');
    }
  }
}

/// 분석 결과 모델
class AnalysisResult {
  final String? foodName;
  final double? accuracy;
  final NutritionData? nutritionData;
  final List<YoutubeRecipe> youtubeRecipes;
  final String? message;
  final List<dynamic>? top3; // 상위 3개 예측 결과
  final String? historyId; // 분석 이력 ID (YouTube 레시피 클릭 시 저장에 사용)

  AnalysisResult({
    this.foodName,
    this.accuracy,
    this.nutritionData,
    required this.youtubeRecipes,
    this.message,
    this.top3,
    this.historyId,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      foodName: json['foodName'] as String?,
      accuracy: json['accuracy'] != null 
          ? (json['accuracy'] is int 
              ? (json['accuracy'] as int).toDouble() 
              : json['accuracy'] as double?)
          : null,
      nutritionData: json['nutritionData'] != null
          ? NutritionData.fromJson(json['nutritionData'] as Map<String, dynamic>)
          : null,
      youtubeRecipes: json['youtubeRecipes'] != null
          ? (json['youtubeRecipes'] as List)
              .map((item) => YoutubeRecipe.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
      message: json['message'] as String?,
      top3: json['top3'] != null
          ? (json['top3'] as List)
          : null,
      historyId: json['historyId'] as String?,
    );
  }

  /// ResultPage에서 사용할 수 있는 Map 형태로 변환
  Map<String, dynamic> toMap() {
    return {
      'name': foodName ?? '알 수 없음',
      'calories': nutritionData?.calories?.toInt() ?? 0,
      'weight': 0, // 백엔드에서 제공되지 않음
      'rating': accuracy != null ? (accuracy! * 10).toInt() : 0, // accuracy를 10점 만점으로 변환
      'accuracy': accuracy,
      'nutrition': nutritionData?.toMap() ?? {},
      'youtubeRecipes': youtubeRecipes.map((r) => r.toMap()).toList(),
      'top3': top3, // 상위 3개 예측 결과 추가
      'historyId': historyId, // 분석 이력 ID 추가
    };
  }
}

/// 영양 정보 모델
class NutritionData {
  final double? calories;
  final double? protein;
  final double? fat;
  final double? carbohydrates;

  NutritionData({
    this.calories,
    this.protein,
    this.fat,
    this.carbohydrates,
  });

  factory NutritionData.fromJson(Map<String, dynamic> json) {
    return NutritionData(
      calories: json['calories'] != null
          ? (json['calories'] is int
              ? (json['calories'] as int).toDouble()
              : json['calories'] as double?)
          : null,
      protein: json['protein'] != null
          ? (json['protein'] is int
              ? (json['protein'] as int).toDouble()
              : json['protein'] as double?)
          : null,
      fat: json['fat'] != null
          ? (json['fat'] is int
              ? (json['fat'] as int).toDouble()
              : json['fat'] as double?)
          : null,
      carbohydrates: json['carbohydrates'] != null
          ? (json['carbohydrates'] is int
              ? (json['carbohydrates'] as int).toDouble()
              : json['carbohydrates'] as double?)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbohydrates': carbohydrates,
    };
  }
}

/// YouTube 레시피 모델
class YoutubeRecipe {
  final String title;
  final String videoId;
  final String? url;

  YoutubeRecipe({
    required this.title,
    required this.videoId,
    this.url,
  });

  factory YoutubeRecipe.fromJson(Map<String, dynamic> json) {
    return YoutubeRecipe(
      title: json['title'] as String,
      videoId: json['videoId'] as String,
      url: json['url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'videoId': videoId,
      'url': url ?? 'https://www.youtube.com/watch?v=$videoId',
    };
  }
}

/// 분석 예외 클래스
class AnalysisException implements Exception {
  final String message;
  final int? statusCode;

  AnalysisException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

