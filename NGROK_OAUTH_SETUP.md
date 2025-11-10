# 🚀 ngrok을 사용한 Google & Naver OAuth2 통합 설정 가이드

## 개요

Google과 Naver OAuth2 정책으로 인해 IP 주소는 리다이렉트 URI로 허용되지 않습니다. 실제 기기에서 테스트하려면 공개 도메인이 필요하며, ngrok을 사용하여 이를 해결할 수 있습니다.

**고정 도메인**: `sterling-jay-well.ngrok-free.app`

---

## 1. ngrok 설치 및 설정

### 1.1 ngrok 설치

#### Mac
```bash
# Homebrew로 설치
brew install ngrok

# 또는 공식 사이트에서 다운로드
# https://ngrok.com/download
```

#### Windows
1. [ngrok 공식 다운로드 페이지](https://ngrok.com/download) 접속
2. **Windows** 버전 다운로드
3. 다운로드한 ZIP 파일 압축 해제
4. 압축 해제한 폴더의 경로를 시스템 PATH 환경 변수에 추가
   - 예: `C:\ngrok` 또는 `C:\Users\YourName\ngrok`
5. 명령 프롬프트(CMD) 또는 PowerShell에서 확인:
   ```cmd
   ngrok version
   ```

**또는 Chocolatey 사용**:
```cmd
choco install ngrok
```

### 1.2 ngrok 계정 생성 및 인증

1. [ngrok Dashboard](https://dashboard.ngrok.com/)에서 계정 생성
2. **Your Authtoken** 복사
3. 터미널에서 인증:

```bash
ngrok config add-authtoken YOUR_AUTH_TOKEN
```

⚠️ **중요**: Authtoken은 계정 ID가 아닌 별도의 인증 토큰입니다. Dashboard에서 확인할 수 있습니다.

### 1.3 고정 도메인 설정 (무료 계정 1개 제공)

1. [ngrok Dashboard](https://dashboard.ngrok.com/) > **Cloud Edge** > **Domains**
2. 고정 도메인 생성 또는 기존 도메인 확인
3. 현재 사용 중인 도메인: `sterling-jay-well.ngrok-free.app`

### 1.4 ngrok 실행

```bash
# 고정 도메인으로 백엔드 서버 터널링
ngrok http 8080 --domain=sterling-jay-well.ngrok-free.app
```

**출력 예시**:
```
Forwarding: https://sterling-jay-well.ngrok-free.app -> http://localhost:8080
```

⚠️ **중요**: 백엔드 서버가 실행 중이어야 합니다 (`./gradlew bootRun`)

---

## 2. Google Cloud Console 설정

### 2.1 OAuth 2.0 Client ID 확인

1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. 프로젝트 선택: `teamproject` (또는 해당 프로젝트)
3. **APIs & Services** > **Credentials** 이동
4. **OAuth 2.0 Client IDs** 섹션에서 Client ID 선택

### 2.2 Authorized redirect URIs 등록

**Client ID**를 선택한 후, **Authorized redirect URIs**에 다음을 **정확히** 추가:

```
https://sterling-jay-well.ngrok-free.app/login/oauth2/code/google
```

⚠️ **주의사항**:
- `https` 사용 (http 아님)
- 포트 번호 없음 (`:8080` 없음)
- 슬래시(`/`) 정확히 일치
- 도메인 끝에 슬래시 없음
- IP 주소는 제거 (예: `http://192.168.50.80:8080/...` 삭제)

### 2.3 OAuth 동의 화면 - 테스트 사용자 추가

1. **APIs & Services** > **OAuth consent screen** 이동
2. **Test users** 섹션 확인
3. **ADD USERS** 클릭하여 테스트할 Google 계정 이메일 추가
   - 예: `freemanyoo@gmail.com`
4. 저장

⚠️ **중요**: External 앱인 경우 테스트 사용자가 추가되어 있어야 로그인이 가능합니다.

---

## 3. 네이버 개발자 센터 설정

### 3.1 애플리케이션 등록

1. [네이버 개발자 센터](https://developers.naver.com/) 접속
2. 네이버 계정으로 로그인
3. **Application** > **애플리케이션 등록** 클릭
4. 다음 정보 입력:
   - **애플리케이션 이름**: `음밥해` (또는 원하는 이름)
   - **사용 API**: **네이버 로그인** 체크
   - **로그인 오픈 API 서비스 환경**: **PC 웹** 체크
   - **서비스 URL**: `https://sterling-jay-well.ngrok-free.app`
   - **Callback URL**: `https://sterling-jay-well.ngrok-free.app/login/oauth2/code/naver`

### 3.2 제공 정보 선택

**제공 정보** 섹션에서 다음 항목 체크:
- ✅ 이름 (name)
- ✅ 이메일 (email)
- ✅ 프로필 이미지 (profile_image)

### 3.3 Client ID와 Client Secret 확인

1. 등록한 애플리케이션 선택
2. **Client ID** 복사
3. **Client Secret** 복사

⚠️ **중요**: Callback URL이 정확히 다음과 같이 설정되어 있어야 합니다:
```
https://sterling-jay-well.ngrok-free.app/login/oauth2/code/naver
```

---

## 4. 백엔드 설정

### 4.1 application.yml 설정

**파일**: `Final-team-project-back/src/main/resources/application.yml`

```yaml
spring:
  security:
    oauth2:
      client:
        registration:
          google:
            client-id: "144067559854-m9n39elm2unsrbuhs8nnuvjs7mqka3pq.apps.googleusercontent.com"
            client-secret: "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"
            scope: profile, email
            # ⚠️ ngrok 사용 시: ngrok URL을 직접 지정
            redirect-uri: 'https://sterling-jay-well.ngrok-free.app/login/oauth2/code/google'
            client-authentication-method: client_secret_post
          naver:
            client-id: RWlkraxniAGcuJga5z1g
            client-secret: cLTIIpGA2c
            client-name: Naver
            authorization-grant-type: authorization_code
            # ⚠️ ngrok 사용 시: ngrok URL을 직접 지정
            redirect-uri: 'https://sterling-jay-well.ngrok-free.app/login/oauth2/code/naver'
            scope: name, email, profile_image
        provider:
          naver:
            authorization-uri: https://nid.naver.com/oauth2.0/authorize
            token-uri: https://nid.naver.com/oauth2.0/token
            user-info-uri: https://openapi.naver.com/v1/nid/me
            user-name-attribute: response
```

### 4.2 application.properties 프록시 헤더 설정

**파일**: `Final-team-project-back/src/main/resources/application.properties`

```properties
# ngrok 프록시 헤더 신뢰 설정 (X-Forwarded-Host, X-Forwarded-Proto 등)
server.forward-headers-strategy=native
```

이 설정은 ngrok 프록시를 통해 들어오는 요청의 헤더를 신뢰하도록 합니다.

### 4.3 백엔드 서버 재시작

설정 변경 후 반드시 서버를 재시작해야 합니다:

```bash
./gradlew bootRun
```

---

## 5. Flutter 앱 설정

### 5.1 login_controller.dart 설정

**파일**: `final_team_project_flutter/lib/controllers/login_controller.dart`

```dart
class LoginController {
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
  
  // 소셜 로그인
  Future<void> loginWithSocial({
    required String provider, // 'google' | 'naver'
    required void Function(String message) onError,
  }) async {
    final url = Uri.parse('$_baseUrl/oauth2/authorization/$provider');
    debugPrint('🔗 소셜 로그인 URL: $url (provider: $provider)');
    
    if (kIsWeb) {
      if (!await launchUrl(url, webOnlyWindowName: '_self')) {
        onError('소셜 로그인 페이지를 열 수 없습니다.');
      }
      return;
    }
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok) onError('소셜 로그인 페이지를 열 수 없습니다.');
  }
}
```

### 5.2 Flutter 앱 재빌드

설정 변경 후 Flutter 앱을 재빌드해야 합니다:

```bash
flutter clean
flutter pub get
flutter run
```

---

## 6. 테스트 방법

### 6.1 ngrok 연결 확인

```bash
# ngrok이 실행 중인지 확인
# 터미널에서 다음 메시지가 보여야 함:
# Forwarding: https://sterling-jay-well.ngrok-free.app -> http://localhost:8080
```

### 6.2 백엔드 서버 접근 테스트

브라우저에서 접속:
```
https://sterling-jay-well.ngrok-free.app
```

⚠️ **ngrok 무료 버전 브라우저 경고 페이지**:
- 첫 방문 시 경고 페이지가 나타날 수 있습니다
- "Visit Site" 버튼을 클릭하면 이후에는 나타나지 않습니다
- Flutter 앱에서는 `ngrok-skip-browser-warning` 헤더로 자동 우회됩니다

### 6.3 Google OAuth2 로그인 테스트

1. Flutter 앱 실행
2. Google 로그인 버튼 클릭
3. Google 로그인 화면이 나타나는지 확인
4. 로그인 후 리다이렉트 확인

### 6.4 Naver OAuth2 로그인 테스트

1. Flutter 앱 실행
2. Naver 로그인 버튼 클릭
3. 네이버 로그인 화면이 나타나는지 확인
4. 로그인 후 리다이렉트 확인

---

## 7. 문제 해결

### 7.1 redirect_uri_mismatch 오류 (Google)

**증상**: `400 오류: redirect_uri_mismatch`

**원인**: Google Cloud Console에 등록된 리다이렉트 URI와 실제 요청 URI가 일치하지 않음

**해결**:
1. Google Cloud Console의 **Authorized redirect URIs** 확인
2. 다음이 정확히 등록되어 있는지 확인:
   ```
   https://sterling-jay-well.ngrok-free.app/login/oauth2/code/google
   ```
3. `application.yml`의 `redirect-uri`가 동일한지 확인
4. 백엔드 서버 재시작

### 7.2 redirect_uri_mismatch 오류 (Naver)

**증상**: "페이지를 찾을 수 없습니다"

**원인**: 네이버 개발자 센터에 등록된 Callback URL과 실제 요청 URI가 일치하지 않음

**해결**:
1. 네이버 개발자 센터의 **Callback URL** 확인
2. 다음이 정확히 등록되어 있는지 확인:
   ```
   https://sterling-jay-well.ngrok-free.app/login/oauth2/code/naver
   ```
3. `application.yml`의 `redirect-uri`가 동일한지 확인
4. 백엔드 서버 재시작

### 7.3 액세스 차단 오류 (Google)

**증상**: "액세스 차단됨: 음밥해의 요청이 잘못되었습니다"

**원인**: 
- OAuth 동의 화면에 테스트 사용자가 등록되지 않음
- 리다이렉트 URI가 일치하지 않음

**해결**:
1. Google Cloud Console > **OAuth consent screen** > **Test users** 확인
2. 테스트할 Google 계정 이메일이 추가되어 있는지 확인
3. 없으면 **ADD USERS**로 추가

### 7.4 ngrok 인증 오류

**증상**: `ERROR: authentication failed: Usage of ngrok requires a verified account and authtoken.`

**해결**:
```bash
ngrok config add-authtoken YOUR_AUTH_TOKEN
```

Authtoken은 [ngrok Dashboard](https://dashboard.ngrok.com/get-started/your-authtoken)에서 확인할 수 있습니다.

### 7.5 백엔드 서버 연결 실패

**증상**: Flutter 앱에서 백엔드 서버에 연결할 수 없음

**해결**:
1. 백엔드 서버가 실행 중인지 확인 (`./gradlew bootRun`)
2. ngrok이 실행 중인지 확인 (`ngrok http 8080 --domain=sterling-jay-well.ngrok-free.app`)
3. ngrok URL이 올바른지 확인 (`https://sterling-jay-well.ngrok-free.app`)

---

## 8. ngrok 사용 환경

### 8.1 지원 환경

ngrok은 다음 환경에서 모두 사용 가능합니다:
- ✅ **시뮬레이터/에뮬레이터**: Android 에뮬레이터, iOS 시뮬레이터
- ✅ **실제 기기**: Android 기기, iOS 기기
- ✅ **웹**: 브라우저

### 8.2 통합 설정

모든 환경에서 동일한 ngrok 설정을 사용합니다:
- **고정 도메인**: `sterling-jay-well.ngrok-free.app`
- **Google Cloud Console**: `https://sterling-jay-well.ngrok-free.app/login/oauth2/code/google` 등록
- **네이버 개발자 센터**: `https://sterling-jay-well.ngrok-free.app/login/oauth2/code/naver` 등록
- **Flutter 앱**: `_ngrokUrl`에 ngrok URL 설정
- **백엔드**: `application.yml`에 ngrok URL 설정

---

## 9. 주의사항

### ngrok 무료 버전 제한

- **고정 도메인**: 계정당 1개만 제공
- **브라우저 경고 페이지**: 첫 방문 시 경고 페이지 표시 (헤더로 우회 가능)
- **세션 제한**: 무료 버전은 세션 수 제한이 있을 수 있음

### 보안

- **개발/테스트용**: ngrok은 개발 및 테스트 목적으로 사용
- **프로덕션**: 실제 배포 시에는 Tailscale 또는 실제 도메인 사용 권장
- **API 키**: Client Secret은 절대 공개하지 마세요

### 백엔드 서버 재시작

- `application.yml` 또는 `application.properties` 변경 시 반드시 서버 재시작 필요
- ngrok은 서버가 실행 중일 때만 작동합니다

---

## 10. 요약 체크리스트

### ngrok 설정 (모든 환경 공통)

#### Google OAuth2
- [ ] ngrok 설치 및 인증 완료
- [ ] 고정 도메인 확인: `sterling-jay-well.ngrok-free.app`
- [ ] Google Cloud Console에 리다이렉트 URI 등록: `https://sterling-jay-well.ngrok-free.app/login/oauth2/code/google`
- [ ] OAuth 동의 화면에 테스트 사용자 추가
- [ ] `application.yml`에 Google ngrok URL 설정
- [ ] 백엔드 서버 재시작
- [ ] Flutter 앱의 `_ngrokUrl`에 ngrok URL 설정
- [ ] Flutter 앱 재빌드
- [ ] ngrok 실행 중 (`ngrok http 8080 --domain=sterling-jay-well.ngrok-free.app`)
- [ ] Google 로그인 테스트 완료 (시뮬레이터/실제 기기 모두)

#### Naver OAuth2
- [ ] 네이버 개발자 센터에 애플리케이션 등록
- [ ] 서비스 URL: `https://sterling-jay-well.ngrok-free.app` 등록
- [ ] Callback URL: `https://sterling-jay-well.ngrok-free.app/login/oauth2/code/naver` 등록
- [ ] 제공 정보 선택 (이름, 이메일, 프로필 이미지)
- [ ] Client ID와 Client Secret 확인
- [ ] `application.yml`에 Naver ngrok URL 설정
- [ ] 백엔드 서버 재시작
- [ ] Flutter 앱의 `_ngrokUrl`에 ngrok URL 설정
- [ ] Flutter 앱 재빌드
- [ ] ngrok 실행 중 (`ngrok http 8080 --domain=sterling-jay-well.ngrok-free.app`)
- [ ] Naver 로그인 테스트 완료 (시뮬레이터/실제 기기 모두)

---

## 11. 참고 자료

- [ngrok 공식 문서](https://ngrok.com/docs)
- [Google OAuth2 설정 가이드](./GOOGLE_OAUTH_SETUP.md)
- [Google OAuth2 IP 주소 문제 해결](./GOOGLE_OAUTH_IP_FIX.md)
- [Tailscale OAuth2 설정](./TAILSCALE_OAUTH_SETUP.md)

---

**최종 업데이트**: 2025년 1월
