# Flutter 주요 기술 4가지

## 1. Google Maps Flutter를 이용한 지도 기능 구현

- Google Maps API 키 설정 (Android/iOS 플랫폼별 설정)
  - Android: AndroidManifest.xml에 API 키 설정
  - iOS: AppDelegate.swift에 API 키 설정
- GoogleMap 위젯을 이용한 지도 표시
- Marker를 이용한 위치 표시 (내 위치, 식당 위치)
- CameraUpdate를 이용한 지도 카메라 제어 (줌, 이동)
- InfoWindow를 이용한 마커 정보 표시
- myLocationEnabled를 이용한 현재 위치 표시
- 프로젝트에서 주변 식당 검색 결과를 지도에 마커로 표시

## 2. Geolocator를 이용한 위치 정보 수집

- 위치 권한 요청 및 관리 (LocationPermission)
  - checkPermission()을 이용한 권한 상태 확인
  - requestPermission()을 이용한 권한 요청
  - deniedForever 상태 처리
- getCurrentPosition()을 이용한 현재 위치 좌표 획득
- LocationAccuracy 설정을 통한 위치 정확도 제어
- 프로젝트에서 사용자 현재 위치를 기반으로 주변 식당 검색

## 3. HTTP 통신을 이용한 RESTful API 연동

- http 패키지를 이용한 Spring Boot 서버와 통신
- Uri.http()를 이용한 URL 및 쿼리 파라미터 구성
- 플랫폼별 서버 주소 설정 (Android 에뮬레이터/실제 기기, iOS 시뮬레이터/실제 기기)
- timeout 설정을 통한 네트워크 타임아웃 처리
- JSON 파싱 (jsonDecode)을 이용한 응답 데이터 처리
- utf8.decode()를 이용한 한글 인코딩 처리
- 프로젝트에서 백엔드 API를 호출하여 주변 식당 정보 수신

## 4. StatefulWidget의 상태 관리 및 메모리 안전성

- StatefulWidget과 setState()를 이용한 상태 관리
- mounted 체크를 통한 메모리 안전성 확보
  - 위젯이 dispose된 후 setState() 호출 방지
  - 비동기 작업 완료 후 mounted 상태 확인
- 비동기 작업 (async/await) 처리
- Future.delayed()를 이용한 지도 로드 후 카메라 이동
- 프로젝트에서 지도 화면의 로딩 상태, 에러 상태, 마커 데이터를 상태로 관리


