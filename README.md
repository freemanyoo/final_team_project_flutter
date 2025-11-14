# 음밥해 (Eumbabae) - Flutter 클라이언트

AI 기반 음식 이미지 분석 및 통합 레시피/영양소 제공 시스템의 모바일 앱

## 개발환경

Java 17, Spring Boot 3.5.4, Flutter SDK 3.9.2, MariaDB, MongoDB, QueryDSL 5.0.0, JWT, Flask 2.3.0, PyTorch 2.0.0, Google Maps API, YouTube API v3, OAuth2 (Google, Naver)

## 프로젝트 개요

음식 이미지를 촬영하여 AI로 분석하고, 영양소 정보와 레시피를 제공하는 크로스 플랫폼 모바일 애플리케이션입니다.

## 주요 기능

### 📸 음식 이미지 분석
- 카메라 촬영 또는 갤러리에서 이미지 선택
- EfficientNet AI 모델을 통한 음식 인식
- Top-3 예측 결과 및 정확도 표시

### 🍳 레시피 추천
- YouTube 레시피 영상 자동 검색
- 분석된 음식과 관련된 요리 영상 추천
- 영상 바로 시청 기능

### 🗺️ 맛집 검색
- Google Maps API를 활용한 주변 맛집 검색
- 실시간 지도 표시 및 마커 기능
- 음식 이름 기반 맛집 자동 검색

### 📊 영양소 정보
- 분석된 음식의 상세 영양 정보 제공
- 칼로리, 탄수화물, 단백질, 지방 정보

### 👤 마이페이지
- 사용자 프로필 관리
- 음식 분석 히스토리 조회
- 이전 분석 결과 및 레시피 확인

## 프로젝트 구조

```
lib/
├── controllers/          # 컨트롤러
│   └── login_controller.dart
├── core/                 # 핵심 설정
│   └── config/
│       ├── api_config.dart
│       └── login_config.dart
├── screens/              # 화면
│   ├── home_page.dart           # 홈 (이미지 캡처)
│   ├── login_page.dart          # 로그인
│   ├── signup_page.dart         # 회원가입
│   ├── main_screen.dart         # 메인 화면 (탭 네비게이션)
│   ├── result_page.dart         # 분석 결과
│   ├── nutrition_page.dart      # 영양소 정보
│   ├── restaurant_search_page.dart  # 맛집 검색
│   ├── restaurant_map_screen.dart   # 맛집 지도
│   ├── my_page.dart              # 마이페이지
│   └── splash_screen.dart       # 스플래시 화면
├── services/             # 서비스
│   └── analysis_service.dart
├── util/                 # 유틸리티
│   ├── auth_helper.dart
│   └── debug_helper.dart
└── widgets/              # 위젯
    └── bottom_nav.dart
```

## 주요 의존성

- **HTTP 통신**: `dio: ^5.7.0`, `http: ^1.1.0`
- **인증**: `flutter_secure_storage: ^9.2.2`, `app_links: ^6.4.1`
- **이미지/카메라**: `image_picker: ^1.2.0`, `camera: ^0.11.0`
- **지도**: `google_maps_flutter: ^2.5.0`, `geolocator: ^13.0.0`
- **AI**: `tflite_flutter: ^0.12.0`
- **UI**: `lottie: ^3.1.2`, `video_player: ^2.8.0`

## 시작하기

### 필수 요구사항
- Flutter SDK 3.9.2 이상
- Dart 3.9.2 이상
- Android Studio / Xcode (각 플랫폼 개발용)

### 설치 및 실행

```bash
# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

### 환경 설정

`lib/core/config/api_config.dart`에서 서버 주소를 설정하세요:
- 로컬 개발: `http://localhost:8080`
- 실제 기기: 서버 IP 주소로 변경

## 백엔드 연동

이 앱은 다음 백엔드 서버와 연동됩니다:
- **Spring Boot API 서버**: 사용자 인증, 데이터 관리
- **Flask AI 서버**: 음식 이미지 분석

## 라이선스

이 프로젝트는 팀 프로젝트입니다.
