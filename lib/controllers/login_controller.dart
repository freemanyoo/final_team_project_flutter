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

  /// 에뮬레이터: 10.0.2.2 / 실기기: PC IP, 웹: 동일 오리진 권장
  /// 필요하면 한 곳만 바꿔 쓰면 됨
  // TODO: PC 내부 IP로 변경 필요 (예: 'http://192.168.0.XX:8080')
  static const String _baseUrl = 'http://10.0.2.2:8080';

  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
    validateStatus: (_) => true, // 백엔드 에러 바디 읽기 위함
  ));

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ====== Deep Link (소셜 로그인용) ======
  // app_links 인스턴스 추가
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub; // app_links는 널러블이 아닌 Uri 사용

  /// 앱으로 돌아오는 커스텀 스킴(예: myapp://oauth?access=...&refresh=...)을 구독
  /// [onSuccess]는 토큰 저장이 끝나면 호출됨
  void startLinkListener({required VoidCallback onSuccess}) async {
    // 웹에서는 deep link 스트림이 없음
    if (kIsWeb) return;

    _linkSub?.cancel();

    // 1. 앱이 완전히 종료되었다가 링크로 시작한 경우 처리
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      await _handleOAuthRedirect(initialUri, onSuccess);
    }

    // 2. 실행 중에 들어오는 링크 스트림 구독
    _linkSub = _appLinks.uriLinkStream.listen((uri) async {
      await _handleOAuthRedirect(uri, onSuccess);
    }, onError: (err) {
      debugPrint('🔗 app_links error: $err');
    });
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
      final res = await _dio.post('/api/auth/login', data: {
        'userId': userId.trim(),
        'password': password,
      });

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
    XFile? profileImage,
    required VoidCallback onSuccess,
    required void Function(String message) onError,
  }) async {
    try {
      if (profileImage == null) {
        // 이미지 없이 JSON
        final res = await _dio.post('/api/auth/signup', data: {
          'userId': userId.trim(),
          'email': email.trim(),
          'password': password,
        });
        if (res.statusCode == 201 || res.statusCode == 200) {
          onSuccess();
        } else {
          onError(_extractError(res));
        }
      } else {
        // 이미지 포함 Multipart
        final form = FormData.fromMap({
          // 서버에서 @RequestPart 또는 @RequestParam으로 받도록 구성
          'userId': userId.trim(),
          'email': email.trim(),
          'password': password,
          'profileImage': await MultipartFile.fromFile(
            profileImage.path,
            filename: p.basename(profileImage.path),
          ),
        });
        final res = await _dio.post('/api/auth/signup', data: form);
        if (res.statusCode == 201 || res.statusCode == 200) {
          onSuccess();
        } else {
          onError(_extractError(res));
        }
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
    // 예: myapp://oauth?access=...&refresh=...
    final access = uri.queryParameters['access'];
    final refresh = uri.queryParameters['refresh'];

    if (access == null || access.isEmpty) return;
    await _storage.write(key: 'accessToken', value: access);
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: 'refreshToken', value: refresh);
    }
    onSuccess();
  }
}