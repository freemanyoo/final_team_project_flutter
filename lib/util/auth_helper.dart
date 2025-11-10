// lib/util/auth_helper.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

/// 인증 관련 유틸리티 클래스
class AuthHelper {
  static const _storage = FlutterSecureStorage();

  /// JWT 토큰에서 사용자 ID 추출
  /// JWT 토큰의 payload를 디코딩하여 subject (사용자 ID)를 반환합니다.
  /// 
  /// 반환값:
  /// - 토큰이 있고 유효한 경우: 사용자 ID (String)
  /// - 토큰이 없거나 유효하지 않은 경우: null
  static Future<String?> getUserIdFromToken() async {
    try {
      final token = await _storage.read(key: 'accessToken');
      if (token == null || token.isEmpty) {
        print('⚠️ 토큰이 없습니다.');
        return null;
      }

      // JWT 토큰은 세 부분으로 나뉩니다: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        print('⚠️ 잘못된 JWT 토큰 형식입니다.');
        return null;
      }

      // payload 부분 디코딩 (base64url)
      final payload = parts[1];
      
      // base64url 디코딩을 위해 패딩 추가
      String normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      switch (normalized.length % 4) {
        case 1:
          normalized += '===';
          break;
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
      }

      final decodedBytes = base64Url.decode(normalized);
      final decodedString = utf8.decode(decodedBytes);
      final payloadMap = json.decode(decodedString) as Map<String, dynamic>;

      // subject (sub) 필드에서 사용자 ID 추출
      final userId = payloadMap['sub'] as String?;
      
      if (userId == null || userId.isEmpty) {
        print('⚠️ JWT 토큰에 사용자 ID가 없습니다.');
        return null;
      }

      print('✅ 사용자 ID 추출 성공: $userId');
      return userId;
    } catch (e) {
      print('❌ JWT 토큰 디코딩 오류: $e');
      return null;
    }
  }

  /// 현재 로그인한 사용자 ID를 정수로 반환
  /// 
  /// JWT 토큰에서 userId (String)를 추출한 후, 백엔드 API를 호출하여
  /// User.id (Long)를 가져옵니다.
  /// 
  /// 반환값:
  /// - 성공한 경우: 사용자 ID (int)
  /// - 실패한 경우: null
  static Future<int?> getUserIdAsInt() async {
    final userIdString = await getUserIdFromToken();
    if (userIdString == null) {
      return null;
    }

    // userId가 숫자 문자열인 경우 직접 변환 시도
    try {
      final userId = int.parse(userIdString);
      return userId;
    } catch (e) {
      // userId가 숫자가 아닌 경우 (예: "free1234")
      // 백엔드 API를 호출하여 User.id를 가져옵니다
      print('⚠️ 사용자 ID가 숫자가 아닙니다. 백엔드 API를 호출합니다: $userIdString');
      return await _getUserIdFromBackend(userIdString);
    }
  }

  /// 백엔드 API를 호출하여 userId (String)로 User.id (Long)를 가져옵니다.
  /// 
  /// 현재는 백엔드에 해당 API가 없으므로, 임시로 null을 반환합니다.
  /// 나중에 백엔드에 `/api/users/me` 또는 `/api/users/{userId}/id` 같은
  /// API를 추가하면 여기서 호출하도록 수정해야 합니다.
  static Future<int?> _getUserIdFromBackend(String userIdString) async {
    try {
      // TODO: 백엔드에 현재 사용자 정보를 가져오는 API가 추가되면 여기서 호출
      // 예: GET /api/users/me 또는 GET /api/users/{userId}/id
      
      // 현재는 백엔드의 getCurrentUserId() 메서드와 같은 로직을
      // Flutter에서 직접 구현할 수 없으므로, 임시로 null을 반환합니다.
      // 
      // 해결 방법:
      // 1. 백엔드에 GET /api/users/me API를 추가하여 현재 로그인한 사용자의 User.id를 반환
      // 2. 또는 백엔드의 analyzeImage 엔드포인트를 수정하여 JWT 토큰에서 자동으로 userId를 추출
      
      print('⚠️ 백엔드 API를 통한 사용자 ID 조회는 아직 구현되지 않았습니다.');
      print('   현재 userId (String): $userIdString');
      print('   백엔드의 analyzeImage 엔드포인트를 수정하여 JWT 토큰에서 자동으로 userId를 추출하도록 해야 합니다.');
      
      return null;
    } catch (e) {
      print('❌ 백엔드 API 호출 오류: $e');
      return null;
    }
  }

  /// 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'accessToken');
    return token != null && token.isNotEmpty;
  }
}

