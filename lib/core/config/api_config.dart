/// 🔹 모든 API 요청의 공통 base URL
/// 
/// ⚠️ 중요: ngrok을 사용하면 모든 플랫폼에서 같은 URL을 사용합니다.
/// ngrok 미사용 시 플랫폼별로 자동으로 올바른 URL을 선택합니다.
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // ============================================
  // 🔧 ngrok 설정 (우선 사용)
  // ============================================
  // ngrok 사용 시: 아래 URL을 입력하세요
  // ngrok 미사용 시: 빈 문자열로 두세요
  static const String _ngrokUrl = 'https://sterling-jay-well.ngrok-free.app';
  
  // ============================================
  // 🔧 로컬 개발 설정 (ngrok 미사용 시)
  // ============================================
  // ⚠️ 실제 기기 테스트 시 여기를 변경하세요!
  // Mac IP 확인: ifconfig | grep "inet " | grep -v 127.0.0.1
  // Windows IP 확인: ipconfig
  // Linux IP 확인: hostname -I
  // 현재 확인된 IP: 10.100.201.131
  static const String _serverIp = '10.100.201.131'; // 본인의 서버 IP 주소로 변경!
  static const int _serverPort = 8080;
  
  /// 플랫폼별로 자동으로 올바른 base URL 반환
  static String get baseUrl {
    // ngrok URL이 설정되어 있으면 모든 플랫폼에서 ngrok 사용
    if (_ngrokUrl.isNotEmpty) {
      return _ngrokUrl;
    }
    
    // ngrok 미사용 시: 플랫폼별로 자동 선택
    // 웹 환경
    if (kIsWeb) {
      return 'http://localhost:$_serverPort';
    }
    // Android 에뮬레이터
    else if (Platform.isAndroid) {
      return 'http://10.0.2.2:$_serverPort'; // Android 에뮬레이터는 10.0.2.2가 localhost
    }
    // iOS 시뮬레이터 또는 실제 기기
    else if (Platform.isIOS) {
      // iOS 시뮬레이터는 localhost 사용 가능하지만, 실제 기기는 IP 주소 필요
      // 실제 기기에서 테스트할 때는 _serverIp 사용
      return 'http://$_serverIp:$_serverPort';
      
      // 시뮬레이터만 사용할 경우 아래 주석 해제
      // return 'http://localhost:$_serverPort';
    }
    // 기본값
    else {
      return 'http://localhost:$_serverPort';
    }
  }
  
  /// ngrok 사용 여부 확인
  static bool get isUsingNgrok => _ngrokUrl.isNotEmpty;
  
  /// ngrok 헤더 (무료 버전 브라우저 경고 페이지 우회)
  static Map<String, String>? get ngrokHeaders {
    if (isUsingNgrok) {
      return {'ngrok-skip-browser-warning': 'true'};
    }
    return null;
  }
  
  /// API 엔드포인트 전체 URL 생성
  static String getApiUrl(String endpoint) {
    // endpoint가 이미 /로 시작하면 그대로, 아니면 / 추가
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$baseUrl$path';
  }
  
  /// 디버그용: 현재 사용 중인 URL 출력
  static void printCurrentUrl() {
    print('🔗 ApiConfig baseUrl: $baseUrl');
    print('📱 Platform: ${kIsWeb ? 'Web' : Platform.isIOS ? 'iOS' : Platform.isAndroid ? 'Android' : 'Other'}');
  }
}
