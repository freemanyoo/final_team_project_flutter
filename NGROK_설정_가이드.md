# NGROK 설정 가이드

## 📋 개요

이 프로젝트는 **OAuth2 로그인만 NGROK을 사용**하고, 나머지 기능은 **로컬 서버**를 사용하도록 설정되어 있습니다.

## 🔧 설정 구조

### API URL 분리

- **인증 API (authBaseUrl)**: OAuth2 로그인용 - NGROK 우선, 없으면 로컬 폴백
  - 로그인 (`/api/users/login`)
  - 회원가입 (`/api/users/signup`)
  - OAuth2 소셜 로그인 (`/oauth2/authorization/*`)

- **일반 API (apiBaseUrl)**: 로컬 서버만 사용
  - 지도 검색 (`/api/map/search`)
  - 음식 분석 (`/api/analysis/*`)
  - YouTube 검색 (`/api/youtube/*`)
  - 마이페이지 등 기타 기능

## 📝 설정 파일

### `lib/core/config/api_config.dart`

```dart
// NGROK URL 설정 (OAuth2 로그인용)
static const String _ngrokUrl = 'https://sterling-jay-well.ngrok-free.app';

// 로컬 서버 IP 설정 (일반 API용)
static const String _serverIp = '10.100.201.26'; // 본인의 서버 IP 주소로 변경!
static const int _serverPort = 8080;
```

## 🎯 사용 방법

### 1. NGROK 사용 시 (OAuth2 로그인 필요)

**NGROK URL 설정:**
```dart
static const String _ngrokUrl = 'https://your-ngrok-url.ngrok-free.app';
```

**결과:**
- ✅ OAuth2 로그인: NGROK URL 사용
- ✅ 일반 기능: 로컬 서버 사용
- ✅ NGROK이 없어도 일반 기능은 정상 작동

### 2. NGROK 미사용 시 (로컬 개발)

**NGROK URL 비우기:**
```dart
static const String _ngrokUrl = ''; // 빈 문자열
```

**결과:**
- ✅ 모든 기능: 로컬 서버 사용
- ✅ OAuth2 로그인도 로컬 서버로 폴백
- ⚠️ OAuth2 리다이렉트는 로컬에서 제한적일 수 있음

## 📍 각 파일별 사용 URL

| 파일 | 사용 URL | 용도 |
|------|---------|------|
| `login_controller.dart` | `ApiConfig.authBaseUrl` | 로그인, 회원가입, OAuth2 |
| `analysis_service.dart` | `ApiConfig.apiBaseUrl` | 음식 분석, YouTube 검색 |
| `restaurant_map_screen.dart` | `ApiConfig.apiBaseUrl` | 지도 검색 |

## 🔄 동작 방식

### 인증 API (authBaseUrl)

1. NGROK URL이 설정되어 있으면 → NGROK 사용
2. NGROK URL이 없으면 → 로컬 서버로 폴백

```dart
static String get authBaseUrl {
  if (_ngrokUrl.isNotEmpty) {
    return _ngrokUrl;  // NGROK 사용
  }
  return _getLocalServerUrl();  // 로컬 서버로 폴백
}
```

### 일반 API (apiBaseUrl)

항상 로컬 서버 사용 (플랫폼별 자동 선택)

```dart
static String get apiBaseUrl {
  return _getLocalServerUrl();  // 항상 로컬 서버
}
```

## ⚙️ 플랫폼별 로컬 서버 URL

로컬 서버 URL은 플랫폼에 따라 자동으로 선택됩니다:

- **웹**: `http://localhost:8080`
- **Android 에뮬레이터**: `http://10.0.2.2:8080`
- **Android 실제 기기**: `http://10.100.201.26:8080` (서버 IP)
- **iOS 시뮬레이터/실제 기기**: `http://10.100.201.26:8080` (서버 IP)

## 🛠️ IP 주소 변경 방법

### Windows
```bash
ipconfig | findstr /i "IPv4"
```

### Mac/Linux
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

확인한 IP 주소를 `api_config.dart`의 `_serverIp`에 설정하세요.

## ✅ 장점

1. **NGROK 없이도 작동**: 일반 기능은 로컬 서버 사용
2. **OAuth2만 외부 접근**: 소셜 로그인 리다이렉트만 NGROK 필요
3. **개발 편의성**: NGROK을 켜지 않아도 대부분 기능 사용 가능
4. **자동 폴백**: NGROK이 없으면 자동으로 로컬 서버 사용

## 🔍 디버깅

현재 사용 중인 URL 확인:

```dart
ApiConfig.printCurrentUrl();
```

출력 예시:
```
🔐 인증 API URL (authBaseUrl): https://sterling-jay-well.ngrok-free.app
🌐 일반 API URL (apiBaseUrl): http://10.100.201.26:8080
📱 Platform: Android
🔗 NGROK 사용: 예
```

## 📌 주의사항

1. **NGROK URL 변경 시**: `api_config.dart`의 `_ngrokUrl`만 수정
2. **서버 IP 변경 시**: `api_config.dart`의 `_serverIp` 수정
3. **OAuth2 리다이렉트**: NGROK URL이 백엔드 OAuth2 설정에도 등록되어 있어야 함

---

**작성일**: 2025년 1월
**프로젝트**: Final Team Project Flutter

