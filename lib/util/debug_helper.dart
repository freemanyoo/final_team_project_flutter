// lib/utils/debug_helper.dart
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// 디버깅용 로그 헬퍼
class DebugHelper {
  static const String _tag = "🍽️ FoodApp";

  /// API 요청 로그
  static void logApiRequest(String url, Map<String, String>? params) {
    final fullUrl = params != null
        ? '$url?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}'
        : url;

    _log('🔍 API 요청', fullUrl);

    if (params != null) {
      params.forEach((key, value) {
        _log('  📝 $key', value);
      });
    }
  }

  /// API 응답 로그
  static void logApiResponse(int statusCode, String? body) {
    if (statusCode == 200) {
      _log('✅ API 성공', 'Status: $statusCode');
      if (body != null && body.isNotEmpty) {
        // 길면 잘라서 표시
        final preview = body.length > 200 ? '${body.substring(0, 200)}...' : body;
        _log('📦 응답 데이터', preview);
      }
    } else {
      _log('❌ API 실패', 'Status: $statusCode, Body: $body');
    }
  }

  /// 에러 로그
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    _log('❌ 에러 [$context]', error.toString());
    if (stackTrace != null && kDebugMode) {
      developer.log(
        'StackTrace: $stackTrace',
        name: _tag,
        error: error,
      );
    }
  }

  /// 일반 정보 로그
  static void logInfo(String title, String message) {
    _log('ℹ️ $title', message);
  }

  /// 성공 로그
  static void logSuccess(String message) {
    _log('✅ 성공', message);
  }

  /// 경고 로그
  static void logWarning(String message) {
    _log('⚠️ 경고', message);
  }

  /// 위치 정보 로그
  static void logLocation(double latitude, double longitude) {
    _log('📍 현재 위치', 'Lat: $latitude, Lng: $longitude');
  }

  /// 마커 정보 로그
  static void logMarker(String name, double lat, double lng) {
    _log('📌 마커 추가', '$name ($lat, $lng)');
  }

  /// 내부 로그 함수
  static void _log(String prefix, String message) {
    if (kDebugMode) {
      developer.log(
        '$prefix: $message',
        name: _tag,
      );
      // 콘솔에도 출력
      debugPrint('$_tag $prefix: $message');
    }
  }

  /// 구분선 출력
  static void logDivider([String? label]) {
    if (kDebugMode) {
      final divider = '=' * 50;
      if (label != null) {
        debugPrint('$_tag $divider $label $divider');
      } else {
        debugPrint('$_tag $divider');
      }
    }
  }

  /// 네트워크 연결 테스트
  static void logNetworkTest(String host, int port) {
    _log('🌐 네트워크 테스트', '$host:$port');
  }
}