// lib/controllers/login_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
// import 'package:uni_links/uni_links.dart'; // <--- uni_links 제거
import 'package:app_links/app_links.dart'; // <--- app_links 추가

/// 하나의 컨트롤러로 로그인/회원가입/소셜로그인을 모두 처리
/// - 페이지들(login_page.dart, signup_page.dart)은 이 컨트롤러만 사용하면 됨
class LoginController {
  LoginController();

  /// 플랫폼별 서버 URL 자동 설정
  /// ⚠️ Google OAuth2 정책: IP 주소는 리다이렉트 URI로 허용되지 않음
  /// 
  /// 실제 기기 테스트: ngrok 사용
  /// 고정 도메인: sterling-jay-well.ngrok-free.app
  /// 실행: ngrok http 8080 --domain=sterling-jay-well.ngrok-free.app
  static const String _ngrokUrl = 'https://sterling-jay-well.ngrok-free.app';
  
  static String get _baseUrl {
    // ngrok URL이 설정되어 있으면 모든 플랫폼에서 ngrok 사용 (실제 기기 테스트용)
    if (_ngrokUrl.isNotEmpty) {
      return _ngrokUrl;
    }
    
    // ngrok 미사용 시: 로컬 개발용 (에뮬레이터/시뮬레이터)
    if (kIsWeb) {
      return 'http://localhost:8080';
    } else if (Platform.isAndroid) {
      // Android 에뮬레이터: 10.0.2.2는 localhost를 가리킴
      return 'http://10.0.2.2:8080';
    } else if (Platform.isIOS) {
      // iOS 시뮬레이터: localhost 사용 가능
      return 'http://localhost:8080';
    } else {
      return 'http://localhost:8080';
    }
  }

  Dio? _dioInstance;
  Dio get _dio {
    _dioInstance ??= Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      validateStatus: (_) => true, // 백엔드 에러 바디 읽기 위함
      // ngrok 무료 버전 브라우저 경고 페이지 우회
      headers: _ngrokUrl.isNotEmpty
          ? {'ngrok-skip-browser-warning': 'true'}
          : null,
    ));
    return _dioInstance!;
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ====== Deep Link (소셜 로그인용) ======
  // app_links 인스턴스 추가
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub; // app_links는 널러블이 아닌 Uri 사용

  /// 앱으로 돌아오는 커스텀 스킴(예: myapp://oauth2/callback?access=...&refresh=...)을 구독
  /// [onSuccess]는 토큰 저장이 끝나면 호출됨
  void startLinkListener({required VoidCallback onSuccess}) async {
    // 웹에서는 deep link 스트림이 없음
    if (kIsWeb) return;

    debugPrint('🔗 Deep Link 리스너 시작');
    _linkSub?.cancel();

    // 1. 앱이 완전히 종료되었다가 링크로 시작한 경우 처리
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 초기 링크 수신: $initialUri');
        await _handleOAuthRedirect(initialUri, onSuccess);
      } else {
        debugPrint('🔗 초기 링크 없음');
      }
    } catch (e) {
      debugPrint('❌ 초기 링크 처리 오류: $e');
    }

    // 2. 실행 중에 들어오는 링크 스트림 구독
    _linkSub = _appLinks.uriLinkStream.listen((uri) async {
      debugPrint('🔗 실행 중 링크 수신: $uri');
      await _handleOAuthRedirect(uri, onSuccess);
    }, onError: (err) {
      debugPrint('❌ app_links error: $err');
    });
    
    debugPrint('✅ Deep Link 리스너 등록 완료');
  }

  Future<void> dispose() async {
    await _linkSub?.cancel();
    _linkSub = null;
  }

  // ====== ID/PW 로그인 ======
  Future<void> loginWithPassword({
    required String userId,
    required String password,
    required VoidCallback onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      final res = await _dio.post('/api/users/login', data: {
        'userId': userId.trim(),
        'password': password,
      }, options: Options(contentType: Headers.jsonContentType));

      if (res.statusCode == 200 && res.data != null) {
        // 백엔드가 {accessToken, refreshToken} 형태로 내려준다고 가정
        final data = res.data is Map ? res.data as Map : jsonDecode(res.data);
        final access = data['accessToken'];
        final refresh = data['refreshToken'];
        if (access == null || (access is String && access.isEmpty)) {
          onError('토큰이 비어있습니다.');
          return;
        }
        await _storage.write(key: 'accessToken', value: access.toString());
        if (refresh != null) {
          await _storage.write(key: 'refreshToken', value: refresh.toString());
        }
        onSuccess();
      } else {
        final msg = _extractError(res);
        onError(msg);
      }
    } catch (e) {
      onError('로그인 중 오류: $e');
    }
  }

  // ====== 회원가입(프로필 이미지 포함/없음 모두 지원) ======
  Future<void> signup({
    required String userId,
    required String email,
    required String password,
    required String passwordConfirm, // ✅ 추가
    XFile? profileImage,
    required VoidCallback onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      // 1) signupData JSON 만들기
      final signupData = jsonEncode({
        'userId': userId.trim(),
        'email': email.trim(),
        'password': password,
        'passwordConfirm': passwordConfirm, // ✅ 백엔드 검증 통과용
      });

      // 2) 멀티파트 생성 (이미지 없어도 signupData만 담아서 멀티파트로 보냄)
      final map = <String, dynamic>{
        'signupData': signupData, // ✅ 백엔드 @RequestParam("signupData")에 매칭
      };
      if (profileImage != null) {
        map['profileImage'] = await MultipartFile.fromFile(
          profileImage.path,
          filename: p.basename(profileImage.path),
        );
      }
      final form = FormData.fromMap(map);

      // 3) 백엔드 실제 경로로 전송 (/api/users/signup)
      final res = await _dio.post(
        '/api/users/signup',
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        onSuccess();
      } else {
        onError(_extractError(res));
      }
    } catch (e) {
      onError('회원가입 중 오류: $e');
    }
  }

  // ====== 소셜 로그인 ======
  Future<void> loginWithSocial({
    required String provider, // 'google' | 'naver'
    required void Function(String message) onError,
  }) async {
    final url = Uri.parse('$_baseUrl/oauth2/authorization/$provider');
    debugPrint('🔗 소셜 로그인 URL: $url (provider: $provider)');
    
    if (kIsWeb) {
      // 웹: 새 탭으로 엶(동일 오리진에서 리다이렉트 처리 권장)
      if (!await launchUrl(url, webOnlyWindowName: '_self')) {
        onError('소셜 로그인 페이지를 열 수 없습니다.');
      }
      return;
    }
    // 앱/에뮬레이터: 기본 브라우저에서 열기
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok) onError('소셜 로그인 페이지를 열 수 없습니다.');
  }

  // ====== 내부 유틸 ======
  String _extractError(Response res) {
    try {
      if (res.data is Map && (res.data as Map).containsKey('message')) {
        return (res.data as Map)['message']?.toString() ?? '오류(${res.statusCode})';
      }
      if (res.data is String) return res.data as String;
      if (res.data != null) return jsonEncode(res.data);
      return '오류(${res.statusCode})';
    } catch (_) {
      return '오류(${res.statusCode})';
    }
  }

  Future<void> _handleOAuthRedirect(Uri uri, VoidCallback onSuccess) async {
    debugPrint('🔗 OAuth2 리다이렉트 수신: $uri');
    debugPrint('   스킴: ${uri.scheme}');
    debugPrint('   호스트: ${uri.host}');
    debugPrint('   경로: ${uri.path}');
    debugPrint('   쿼리 파라미터: ${uri.queryParameters}');
    
    // 예: myapp://oauth2/callback?access=...&refresh=...
    final access = uri.queryParameters['access'];
    final refresh = uri.queryParameters['refresh'];

    if (access == null || access.isEmpty) {
      debugPrint('❌ Access Token이 없습니다.');
      return;
    }
    
    debugPrint('✅ Access Token 수신 (길이: ${access.length})');
    await _storage.write(key: 'accessToken', value: access);
    if (refresh != null && refresh.isNotEmpty) {
      debugPrint('✅ Refresh Token 수신 (길이: ${refresh.length})');
      await _storage.write(key: 'refreshToken', value: refresh);
    }
    debugPrint('✅ 토큰 저장 완료');
    onSuccess();
  }
}