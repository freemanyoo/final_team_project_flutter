// lib/screens/restaurant_map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // url_launcher 임포트
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../util/debug_helper.dart';
import '../core/config/api_config.dart';

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
  dynamic _selectedRestaurant; // ⭐️ 현재 선택된 식당

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
      if (Platform.isIOS) {
        print('🍽️ [1-1] iOS 플랫폼 감지 - getCurrentPosition()이 자동으로 권한 처리');
        print('🍽️ [1-2] 바로 위치 가져오기 시도 (권한 요청 포함)');
        await findRestaurantsAndSetMarkers();
        return;
      }

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

        if (permission == LocationPermission.denied) {
          print('⚠️ 권한 거부됨 - 위치 가져오기 시도 (자동 권한 요청)');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = '위치 권한이 영구적으로 거부되었습니다.\n설정에서 권한을 허용해주세요.';
          _isLoading = false;
        });
        print('❌ 권한 영구 거부됨');
        return;
      }

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
      _selectedRestaurant = null; // ⭐️ 검색 시 선택 해제
    });

    try {
      // 1. 현재 위치 가져오기
      print('\n🍽️ [2단계] 현재 위치 가져오기');
      print('🍽️ 플랫폼: ${Platform.isIOS ? "iOS" : "Android"}');

      try {
        if (Platform.isIOS) {
          print('🍽️ iOS 시뮬레이터 감지 - 빠른 타임아웃 설정');
          LocationAccuracy accuracy = LocationAccuracy.low;
          print('🍽️ 위치 정확도: $accuracy');
          print('🍽️ 위치 가져오기 시작 (시뮬레이터용 빠른 타임아웃)...');

          _currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: accuracy,
            timeLimit: const Duration(seconds: 3),
          ).timeout(
            const Duration(seconds: 5),
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

        print('⚠️ 기본 위치 사용 (서울 시청)');
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

      final baseUrl = ApiConfig.baseUrl;
      final String path = '/api/map/search';
      final params = {
        'foodName': widget.foodName,
        'latitude': _currentPosition!.latitude.toString(),
        'longitude': _currentPosition!.longitude.toString(),
      };

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
              onTap: () { // ⭐️ 내 위치 탭 시 선택 해제
                setState(() {
                  _selectedRestaurant = null;
                });
              }
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
                // ⭐️ 마커 탭 이벤트 추가
                onTap: () {
                  print('📍 마커 탭: $name');
                  setState(() {
                    _selectedRestaurant = restaurant;
                  });
                },
              ),
            );
            print('📍 [$i] 마커 추가: $name (위도: $lat, 경도: $lng)');
          } else {
            print('⚠️ [$i] 위치 정보 없음: $restaurant');
          }
        }

        print('✅ 총 ${_markers.length}개 마커 생성 완료 (내 위치 포함)');

        if (_mapController != null && _currentPosition != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              ),
              14.0,
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
        _isLoading = false;
      });

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

  /// ⭐️ 외부 지도 앱을 실행하는 헬퍼 메서드 (URL 수정됨)
  // ⭐️ 7. 외부 지도 앱을 실행하는 헬퍼 메서드 (최종 - geo: 스킴 사용)
  Future<void> _launchMaps(double lat, double lng, String name) async {

    // 1. 식당 이름을 URL에서 사용할 수 있도록 인코딩합니다.
    final String encodedName = Uri.encodeComponent(name);

    // 2. ⭐️⭐️⭐️ 최종 수정: http:// 대신 geo: 스킴을 사용합니다.
    // 'geo:위도,경도?q=검색어' 형식은 기기에 설치된
    // 지도 앱(구글맵, 애플맵 등)을 직접 실행시킵니다.
    final url = Uri.parse('geo:$lat,$lng?q=$encodedName');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('지도 실행 오류: $e');
      // ⭐️ 비동기 작업 후 UI 업데이트 시 'mounted' 확인
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('지도 앱을 열 수 없습니다: $e')),
        );
      }
    }
  }

  /// ⭐️ 선택된 식당의 상세 정보 카드를 만드는 헬퍼 메서드
  Widget _buildRestaurantDetailCard(dynamic restaurant) {
    final String name = restaurant['name'] ?? '이름 없음';
    final String address = restaurant['address'] ?? '주소 없음';
    final double? lat = restaurant['latitude'];
    final double? lng = restaurant['longitude'];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_menu, color: Color(0xFF1a3344), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedRestaurant = null; // 닫기 버튼
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4.0, right: 16.0),
            child: Text(
              address,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (lat != null && lng != null) // 위치 정보가 있을 때만 버튼 표시
            ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text('Google 지도로 보기'),
                  onPressed: () {
                    _launchMaps(lat, lng, name);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5F5F5),
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ]
        ],
      ),
    );
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
          // 1. 구글맵
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
              )
                  : const LatLng(37.5665, 126.9780),
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              print('✅ Google Map 생성 완료');

              Future.delayed(const Duration(milliseconds: 500), () {
                if (_currentPosition != null && mounted) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                      15.0,
                    ),
                  );
                  print(
                      '✅ 카메라 이동 완료: 위도 ${_currentPosition!.latitude}, 경도 ${_currentPosition!.longitude}');
                } else if (_markers.isNotEmpty && mounted) {
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
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            zoomControlsEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: false,
            onCameraMoveStarted: () {
              print('📷 카메라 이동 시작');
            },
            onCameraIdle: () {
              print('📷 카메라 이동 완료');
            },
            // ⭐️ 지도 탭 시 선택 해제
            onTap: (LatLng position) {
              print('📍 지도 탭: 위도 ${position.latitude}, 경도 ${position.longitude}');
              if (_selectedRestaurant != null) {
                setState(() {
                  _selectedRestaurant = null;
                });
              }
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

          // 3. 에러 오버레이 (검색 결과가 없는 경우)
          // ⭐️ 로직 수정: _restaurantList.isEmpty 조건 추가
          if (_errorMessage.isNotEmpty && !_isLoading && _restaurantList.isEmpty)
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
                        "검색 결과 없음", // "오류 발생" -> "검색 결과 없음"
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

          // 4. 하단 검색 결과 (선택된 식당이 *없을* 때만 표시)
          if (!_isLoading && _errorMessage.isEmpty && _restaurantList.isNotEmpty && _selectedRestaurant == null)
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

          // 5. 하단 식당 상세 정보 카드 (선택된 식당이 *있을* 때만 표시)
          if (_selectedRestaurant != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildRestaurantDetailCard(_selectedRestaurant!),
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