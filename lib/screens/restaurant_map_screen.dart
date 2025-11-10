// lib/screens/restaurant_map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Platform 사용을 위해 추가
import 'dart:async'; // TimeoutException 사용
import '../util/debug_helper.dart';
import '../core/config/api_config.dart'; // 공통 설정 사용

class RestaurantMapScreen extends StatefulWidget {
  final String foodName;

  const RestaurantMapScreen({Key? key, required this.foodName}) : super(key: key);

  @override
  _RestaurantMapScreenState createState() => _RestaurantMapScreenState();
}

class _RestaurantMapScreenState extends State<RestaurantMapScreen> {
  bool _isLoading = true;
  String _errorMessage = '';

  Position? _currentPosition;
  List<dynamic> _restaurantList = [];
  final Set<Marker> _markers = {};

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    print('\n========================================');
    print('🍽️ RestaurantMapScreen 시작');
    print('🍽️ 음식 이름: ${widget.foodName}');
    print('========================================\n');
    _checkPermissionAndLoadMap();
  }

  Future<void> _checkPermissionAndLoadMap() async {
    print('🍽️ [1단계] 위치 권한 확인 시작');

    try {
      // iOS에서는 권한 확인을 건너뛰고 바로 위치 가져오기 시도
      // getCurrentPosition()이 자동으로 권한을 요청하고 처리함
      if (Platform.isIOS) {
        print('🍽️ [1-1] iOS 플랫폼 감지 - getCurrentPosition()이 자동으로 권한 처리');
        print('🍽️ [1-2] 바로 위치 가져오기 시도 (권한 요청 포함)');
        // iOS에서는 권한 확인 단계를 건너뛰고 바로 위치 가져오기 시도
        // getCurrentPosition()이 자동으로 권한을 요청하고 처리함
        await findRestaurantsAndSetMarkers();
        return;
      }

      // Android에서는 정상적인 권한 확인 프로세스 진행
      // 1. 위치 서비스 활성화 확인
      print('🍽️ [1-1] 위치 서비스 활성화 확인 중...');
      bool serviceEnabled = true;
      try {
        serviceEnabled = await Geolocator.isLocationServiceEnabled()
            .timeout(const Duration(seconds: 2), onTimeout: () {
          print('⚠️ 위치 서비스 확인 타임아웃 - 계속 진행');
          return true;
        });
        print('🍽️ 위치 서비스 활성화 상태: $serviceEnabled');
      } catch (e) {
        print('⚠️ 위치 서비스 확인 중 에러 (계속 진행): $e');
        serviceEnabled = true;
      }
      
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = '위치 서비스가 비활성화되어 있습니다.\n설정에서 위치 서비스를 켜주세요.';
          _isLoading = false;
        });
        print('❌ 위치 서비스 비활성화');
        return;
      }

      // 2. 위치 권한 확인 (타임아웃 매우 짧게)
      print('🍽️ [1-2] 위치 권한 확인 중...');
      LocationPermission permission = LocationPermission.denied;
      try {
        permission = await Geolocator.checkPermission()
            .timeout(const Duration(seconds: 2), onTimeout: () {
          print('⚠️ 권한 확인 타임아웃 - denied로 처리하고 계속 진행');
          return LocationPermission.denied;
        });
        print('🍽️ 현재 권한: $permission');
      } catch (e) {
        print('⚠️ 권한 확인 중 에러: $e - denied로 처리하고 계속 진행');
        permission = LocationPermission.denied;
      }

      // 3. 권한이 없으면 요청
      if (permission == LocationPermission.denied) {
        print('🍽️ [1-3] 권한 요청 중...');
        try {
          permission = await Geolocator.requestPermission()
              .timeout(const Duration(seconds: 8), onTimeout: () {
            print('⚠️ 권한 요청 타임아웃 - 계속 진행');
            return LocationPermission.denied;
          });
          print('🍽️ 권한 요청 결과: $permission');
        } catch (e) {
          print('⚠️ 권한 요청 중 에러: $e - 계속 진행');
          permission = LocationPermission.denied;
        }

        // 권한이 거부되어도 일단 위치 가져오기 시도 (getCurrentPosition이 다시 요청함)
        if (permission == LocationPermission.denied) {
          print('⚠️ 권한 거부됨 - 위치 가져오기 시도 (자동 권한 요청)');
        }
      }

      // 4. 영구 거부 확인
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = '위치 권한이 영구적으로 거부되었습니다.\n설정에서 권한을 허용해주세요.';
          _isLoading = false;
        });
        print('❌ 권한 영구 거부됨');
        return;
      }

      // 5. 권한 확인 완료
      print('✅ 위치 권한 확인 완료');
      await findRestaurantsAndSetMarkers();
      
    } catch (e, stackTrace) {
      print('❌ 권한 확인 중 에러: $e');
      print('❌ 스택 트레이스: $stackTrace');
      setState(() {
        _errorMessage = '위치 권한 확인 중 오류가 발생했습니다.\n에러: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> findRestaurantsAndSetMarkers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 1. 현재 위치 가져오기
      print('\n🍽️ [2단계] 현재 위치 가져오기');
      print('🍽️ 플랫폼: ${Platform.isIOS ? "iOS" : "Android"}');
      
      try {
        // iOS 시뮬레이터에서는 빠르게 실패 처리하고 기본 위치 사용
        if (Platform.isIOS) {
          print('🍽️ iOS 시뮬레이터 감지 - 빠른 타임아웃 설정');
          LocationAccuracy accuracy = LocationAccuracy.low; // 시뮬레이터는 low로 빠르게
          
          print('🍽️ 위치 정확도: $accuracy');
          print('🍽️ 위치 가져오기 시작 (시뮬레이터용 빠른 타임아웃)...');
          
          _currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: accuracy,
            timeLimit: const Duration(seconds: 3), // 시뮬레이터는 3초로 짧게
          ).timeout(
            const Duration(seconds: 5), // 전체 타임아웃 5초
            onTimeout: () {
              print('⚠️ 위치 가져오기 타임아웃 (시뮬레이터)');
              print('⚠️ 기본 위치 사용 (서울 시청)');
              return Position(
                latitude: 37.5665,
                longitude: 126.9780,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                altitudeAccuracy: 0,
                heading: 0,
                headingAccuracy: 0,
                speed: 0,
                speedAccuracy: 0,
              );
            },
          );
        } else {
          // Android는 기존 설정 유지
          LocationAccuracy accuracy = LocationAccuracy.medium;
          
          print('🍽️ 위치 정확도: $accuracy');
          print('🍽️ 위치 가져오기 시작...');
          
          _currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: accuracy,
            timeLimit: const Duration(seconds: 10),
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              print('⚠️ 위치 가져오기 타임아웃 (15초)');
              print('⚠️ 기본 위치 사용 (서울 시청)');
              return Position(
                latitude: 37.5665,
                longitude: 126.9780,
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                altitudeAccuracy: 0,
                heading: 0,
                headingAccuracy: 0,
                speed: 0,
                speedAccuracy: 0,
              );
            },
          );
        }
        
        print('✅ 위치 가져오기 성공!');
        print('✅ 위도: ${_currentPosition!.latitude}');
        print('✅ 경도: ${_currentPosition!.longitude}');
      } catch (e, stackTrace) {
        print('❌ 위치 가져오기 실패: $e');
        print('❌ 에러 타입: ${e.runtimeType}');
        print('❌ 스택 트레이스: $stackTrace');
        
        // 권한 에러인 경우
        if (e.toString().contains('permission') || 
            e.toString().contains('denied') ||
            e.toString().contains('LocationServiceDisabledException')) {
          setState(() {
            _errorMessage = '위치 권한이 필요합니다.\n\n설정 → 개인정보 보호 → 위치 서비스에서\n앱의 위치 권한을 허용해주세요.';
            _isLoading = false;
          });
          print('❌ 위치 권한 에러 - 사용자에게 안내');
          return;
        }
        
        // 타임아웃이나 기타 에러인 경우 기본 위치 사용
        print('⚠️ 기본 위치 사용 (서울 시청)');
        _currentPosition = Position(
          latitude: 37.5665,  // 서울 시청 위도
          longitude: 126.9780, // 서울 시청 경도
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      if (_currentPosition == null) {
        print('⚠️ 위치가 null - 기본 위치 사용');
        _currentPosition = Position(
          latitude: 37.5665,
          longitude: 126.9780,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      print('✅ 위도: ${_currentPosition!.latitude}');
      print('✅ 경도: ${_currentPosition!.longitude}');

      // 2. API 호출
      print('\n🍽️ [3단계] 백엔드 API 호출');

      // 공통 설정에서 base URL 사용
      final baseUrl = ApiConfig.baseUrl;
      final String path = '/api/map/search';
      final params = {
        'foodName': widget.foodName,
        'latitude': _currentPosition!.latitude.toString(),
        'longitude': _currentPosition!.longitude.toString(),
      };

      // URI 생성 (ngrok은 https, 로컬은 http)
      var uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);

      print('📡 요청 URL: $uri');
      print('📤 요청 파라미터:');
      print('   - foodName: ${widget.foodName}');
      print('   - latitude: ${_currentPosition!.latitude}');
      print('   - longitude: ${_currentPosition!.longitude}');

      final startTime = DateTime.now();
      var response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('서버 연결 시간 초과 (10초).\n서버가 실행 중인지 확인해주세요.');
        },
      );
      final duration = DateTime.now().difference(startTime);

      print('📥 응답 시간: ${duration.inMilliseconds}ms');
      print('📥 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        print('✅ 응답 성공!');
        print('📦 응답 데이터: $responseBody');

        _restaurantList = jsonDecode(responseBody);
        print('✅ JSON 파싱 성공');
        print('🏪 검색된 식당 수: ${_restaurantList.length}');

        // 3. 마커 생성
        print('\n🍽️ [4단계] 지도 마커 생성');
        _markers.clear();

        // 내 위치 마커
        _markers.add(
          Marker(
            markerId: const MarkerId('my_location'),
            position: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: '내 위치'),
          ),
        );
        print('📍 내 위치 마커 추가 완료');

        // 식당 마커들
        for (var i = 0; i < _restaurantList.length; i++) {
          var restaurant = _restaurantList[i];
          final lat = restaurant['latitude'];
          final lng = restaurant['longitude'];
          final name = restaurant['name'];
          final address = restaurant['address'];

          if (lat != null && lng != null) {
            _markers.add(
              Marker(
                markerId: MarkerId('restaurant_$i'),
                position: LatLng(lat, lng),
                infoWindow: InfoWindow(
                  title: name ?? '식당',
                  snippet: address ?? '',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            );
            print('📍 [$i] 마커 추가: $name (위도: $lat, 경도: $lng)');
          } else {
            print('⚠️ [$i] 위치 정보 없음: $restaurant');
          }
        }

        print('✅ 총 ${_markers.length}개 마커 생성 완료 (내 위치 포함)');

        // 마커 생성 후 카메라를 현재 위치로 이동
        if (_mapController != null && _currentPosition != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              14.0, // 적절한 줌 레벨
            ),
          );
          print('✅ 카메라를 현재 위치로 이동 완료');
        }

        print('\n========================================');
        print('✅✅✅ 모든 작업 성공! ✅✅✅');
        print('========================================\n');

        if (_restaurantList.isEmpty) {
          setState(() {
            _errorMessage = '"${widget.foodName}"을(를) 판매하는\n주변 식당을 찾지 못했습니다.';
          });
          print('⚠️ 검색 결과가 없습니다.');
        }
      } else {
        String errorBody = utf8.decode(response.bodyBytes);
        print('❌ 서버 에러 발생!');
        print('❌ 상태 코드: ${response.statusCode}');
        print('❌ 에러 내용: $errorBody');
        throw Exception("서버 에러: ${response.statusCode}\n$errorBody");
      }
    } catch (e, stackTrace) {
      print('\n========================================');
      print('❌❌❌ 에러 발생! ❌❌❌');
      print('========================================');
      print('에러: $e');
      print('스택 트레이스: $stackTrace');
      print('========================================\n');

      // Connection refused 오류에 대한 친절한 메시지 (에러 메시지 업데이트 필요 시 여기 수정)
      String errorMessage = '식당 검색 중 오류가 발생했습니다.';
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('errno = 61')) {
        errorMessage = '백엔드 서버에 연결할 수 없습니다.\n\n'
            '확인 사항:\n'
            '1. 백엔드 서버가 실행 중인지 확인\n'
            '2. 서버가 0.0.0.0:8080에 바인딩되어 있는지 확인\n'
            '3. iOS 시뮬레이터의 경우 서버 IP 주소 사용 중\n'
            '   (현재: http://192.168.50.80:8080)\n'
            '   ⚠️ IP 주소가 변경되었다면 코드에서 수정 필요!\n\n'
            '지도는 표시되지만 식당 정보는 불러올 수 없습니다.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = '네트워크 연결 오류가 발생했습니다.\n\n'
            '인터넷 연결과 서버 상태를 확인해주세요.\n\n'
            '지도는 표시되지만 식당 정보는 불러올 수 없습니다.';
      } else {
        errorMessage = '식당 검색 중 오류가 발생했습니다.\n\n'
            '에러: ${e.toString()}\n\n'
            '지도는 표시되지만 식당 정보는 불러올 수 없습니다.';
      }

      setState(() {
        _errorMessage = errorMessage;
        // 서버 연결 실패해도 지도는 표시되도록 _isLoading을 false로 설정
        _isLoading = false;
      });
      
      // 내 위치 마커는 추가 (서버 연결 실패해도)
      if (_currentPosition != null) {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('my_location'),
            position: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: '내 위치'),
          ),
        );
        print('📍 내 위치 마커 추가 완료 (서버 연결 실패)');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("'${widget.foodName}' 주변 가게"),
        backgroundColor: const Color(0xFF1a3344),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('\n🔄 새로고침 시작\n');
              findRestaurantsAndSetMarkers();
            },
            tooltip: '다시 검색',
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. 구글맵 (항상 표시)
            GoogleMap(
              initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                    )
                  : const LatLng(37.5665, 126.9780), // 서울시청 기본 위치
                zoom: 15,
              ),
            // cloudMapId는 선택사항 (Google Cloud Map ID가 있으면 사용)
            // cloudMapId: '9ab22eab75ae97fa799273bf',
              onMapCreated: (controller) {
                _mapController = controller;
                print('✅ Google Map 생성 완료');
                
                // 지도가 완전히 로드된 후 카메라 이동
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_currentPosition != null && mounted) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        15.0, // 줌 레벨 명시
                      ),
                    );
                    print('✅ 카메라 이동 완료: 위도 ${_currentPosition!.latitude}, 경도 ${_currentPosition!.longitude}');
                  } else if (_markers.isNotEmpty && mounted) {
                    // 마커가 있으면 첫 번째 마커 위치로 이동
                    final firstMarker = _markers.first;
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        firstMarker.position,
                        13.0,
                      ),
                    );
                    print('✅ 카메라 이동 완료: 첫 번째 마커 위치로');
                  }
                });
              },
              markers: _markers,  // 마커는 이미 생성되어 있음
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
              zoomControlsEnabled: true,
              compassEnabled: true,
              mapToolbarEnabled: false,
              // 지도 로드 상태 확인
              onCameraMoveStarted: () {
                print('📷 카메라 이동 시작');
              },
              onCameraIdle: () {
                print('📷 카메라 이동 완료');
              },
            onTap: (LatLng position) {
              print('📍 지도 탭: 위도 ${position.latitude}, 경도 ${position.longitude}');
            },
          ),
          // 2. 로딩 오버레이
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                    Text(
                      "주변 식당을 검색하는 중...",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  SizedBox(height: 8),
                  Text(
                    "콘솔 로그를 확인하세요",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              ),
            ),
          // 3. 에러 오버레이
          if (_errorMessage.isNotEmpty && !_isLoading)
            Container(
              color: Colors.white.withOpacity(0.95),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "오류 발생",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          print('\n🔄 다시 시도 시작\n');
                          _checkPermissionAndLoadMap();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 시도'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1a3344),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
              ),

          // 4. 하단 정보
          if (!_isLoading && _errorMessage.isEmpty && _restaurantList.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.restaurant, color: Color(0xFF1a3344)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '주변에 ${_restaurantList.length}개의 식당을 찾았습니다',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    print('🍽️ RestaurantMapScreen 종료\n');
    super.dispose();
  }
}