/// 🔹 API 요청의 base URL 설정
/// 
/// ⚠️ 중요: 
/// - 인증 API (로그인, 회원가입, OAuth2): NGROK 사용 (외부 접근 필요)
/// - 일반 API (지도, 분석 등): 로컬 서버 사용
/// - NGROK이 없어도 로컬 서버로 폴백하여 작동
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // ============================================
  // 🔧 NGROK 설정 (OAuth2 로그인용)
  // ============================================
  // OAuth2 로그인만 NGROK 사용 (소셜 로그인 리다이렉트 필요)
  // NGROK 미사용 시: 빈 문자열로 두세요 (로컬 서버로 폴백)
  static const String _ngrokUrl = 'https://sterling-jay-well.ngrok-free.app';
  
  // ============================================
  // 🔧 로컬 개발 설정 (일반 API용)
  // ============================================
  // ⚠️ 실제 기기 테스트 시 여기를 변경하세요!
  // Mac IP 확인: ifconfig | grep "inet " | grep -v 127.0.0.1
  // Windows IP 확인: ipconfig
  // Linux IP 확인: hostname -I
  // 현재 확인된 IP: 10.100.201.26 (Android 실제 기기용)
  static const String _serverIp = '10.100.201.26'; // 본인의 서버 IP 주소로 변경!
  static const int _serverPort = 8080;
  
  /// 플랫폼별 로컬 서버 URL 반환 (일반 API용)
  static String _getLocalServerUrl() {
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
  
  /// 인증 API용 base URL (OAuth2 로그인용 - NGROK 우선, 없으면 로컬)
  /// 로그인, 회원가입, OAuth2 소셜 로그인에 사용
  static String get authBaseUrl {
    // NGROK URL이 설정되어 있으면 NGROK 사용
    if (_ngrokUrl.isNotEmpty) {
      return _ngrokUrl;
    }
    // NGROK이 없으면 로컬 서버로 폴백
    return _getLocalServerUrl();
  }
  
  /// 일반 API용 base URL (로컬 서버만 사용)
  /// 지도, 분석, 마이페이지 등 일반 기능에 사용
  static String get apiBaseUrl {
    return _getLocalServerUrl();
  }
  
  /// 하위 호환성을 위한 baseUrl (일반 API용으로 사용)
  /// @deprecated: apiBaseUrl 사용 권장
  static String get baseUrl => apiBaseUrl;
  
  /// NGROK 사용 여부 확인
  static bool get isUsingNgrok => _ngrokUrl.isNotEmpty;
  
  /// NGROK 헤더 (무료 버전 브라우저 경고 페이지 우회)
  static Map<String, String>? get ngrokHeaders {
    if (isUsingNgrok) {
      return {'ngrok-skip-browser-warning': 'true'};
    }
    return null;
  }
  
  /// 인증 API 엔드포인트 전체 URL 생성
  static String getAuthApiUrl(String endpoint) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$authBaseUrl$path';
  }
  
  /// 일반 API 엔드포인트 전체 URL 생성
  static String getApiUrl(String endpoint) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return '$apiBaseUrl$path';
  }
  
  /// 디버그용: 현재 사용 중인 URL 출력
  static void printCurrentUrl() {
    print('🔐 인증 API URL (authBaseUrl): $authBaseUrl');
    print('🌐 일반 API URL (apiBaseUrl): $apiBaseUrl');
    print('📱 Platform: ${kIsWeb ? 'Web' : Platform.isIOS ? 'iOS' : Platform.isAndroid ? 'Android' : 'Other'}');
    print('🔗 NGROK 사용: ${isUsingNgrok ? "예" : "아니오 (로컬 서버 사용)"}');
  }
}
