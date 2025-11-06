/// 🔹 OAuth2 로그인 관련 전용 설정
class LoginConfig {
  // 앱 리다이렉트 스킴
  static const callbackScheme = 'myapp';
  static const callbackHost = 'oauth2';
  static const callbackPath = '/callback';

  static String get callbackUri => '$callbackScheme://$callbackHost$callbackPath';
}
