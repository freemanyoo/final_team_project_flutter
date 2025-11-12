// lib/screens/restaurant_search_page.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // url_launcher 임포트
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../core/config/api_config.dart';

class RestaurantSearchPage extends StatefulWidget {
  const RestaurantSearchPage({super.key});

  @override
  State<RestaurantSearchPage> createState() => _RestaurantSearchPageState();
}

class _RestaurantSearchPageState extends State<RestaurantSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  Position? _currentPosition;
  List<dynamic> _restaurantList = [];
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  bool _hasSearched = false;

  dynamic _selectedRestaurant; // ⭐️ 현재 선택된 식당

  @override
  void initState() {
    super.initState();
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
    _addMyLocationMarker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (Platform.isIOS) {
        try {
          LocationPermission permission = await Geolocator.checkPermission()
              .timeout(const Duration(seconds: 2), onTimeout: () => LocationPermission.denied);

          if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
            print('⚠️ iOS 위치 권한 거부됨 - 기본 위치 사용');
            if (mounted) {
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
              _addMyLocationMarker();
              setState(() {});
            }
            return;
          }

          _currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 3),
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
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
        } catch (e) {
          print('⚠️ iOS 위치 가져오기 실패: $e - 기본 위치 사용');
          if (mounted) {
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
            _addMyLocationMarker();
            setState(() {});
          }
          return;
        }
      } else {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled()
            .timeout(const Duration(seconds: 2), onTimeout: () => true);

        if (!serviceEnabled) {
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
          if (mounted) {
            _addMyLocationMarker();
            setState(() {});
          }
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission()
            .timeout(const Duration(seconds: 2), onTimeout: () => LocationPermission.denied);

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission()
              .timeout(const Duration(seconds: 3), onTimeout: () => LocationPermission.denied);
        }

        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
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
          if (mounted) {
            _addMyLocationMarker();
            setState(() {});
          }
          return;
        }

        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        ).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
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

      if (_currentPosition == null) {
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

      if (mounted) {
        _addMyLocationMarker();

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              14.0,
            ),
          );
        }

        setState(() {});
      }
    } catch (e) {
      print('⚠️ 위치 가져오기 실패: $e - 기본 위치 사용');
      if (mounted) {
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
        _addMyLocationMarker();
        setState(() {});
      }
    }
  }


  void _addMyLocationMarker() {
    if (_currentPosition != null) {
      _markers.removeWhere((marker) => marker.markerId.value == 'my_location');
      _markers.add(
        Marker(
            markerId: const MarkerId('my_location'),
            position: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: '내 위치'),
            // ⭐️ 내 위치 탭 시 선택 해제
            onTap: () {
              setState(() {
                _selectedRestaurant = null;
              });
            }
        ),
      );
    }
  }

  Future<void> _searchRestaurants() async {
    final foodName = _searchController.text.trim();
    if (foodName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('음식 이름을 입력해주세요.')),
      );
      return;
    }

    // ⭐️ 검색 시 키보드 숨기기
    FocusScope.of(context).unfocus();

    if (_currentPosition == null) {
      await _getCurrentLocation();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _hasSearched = true;
      _selectedRestaurant = null; // ⭐️ 검색 시 선택 해제
    });

    try {
      final baseUrl = ApiConfig.baseUrl;
      final String path = '/api/map/search';
      final params = {
        'foodName': foodName,
        'latitude': _currentPosition!.latitude.toString(),
        'longitude': _currentPosition!.longitude.toString(),
      };

      var uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);
      print('📡 맛집 검색 URL: $uri');

      var response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('서버 연결 시간 초과 (10초).\n서버가 실행 중인지 확인해주세요.');
        },
      );

      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        _restaurantList = jsonDecode(responseBody);
        print('🏪 검색된 식당 수: ${_restaurantList.length}');

        _markers.clear();
        _addMyLocationMarker(); // 내 위치 마커 다시 추가

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
                  }
              ),
            );
          }
        }

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
        }

        if (_restaurantList.isEmpty) {
          setState(() {
            _errorMessage = '"$foodName"을(를) 판매하는\n주변 식당을 찾지 못했습니다.';
          });
        }
      } else {
        String errorBody = utf8.decode(response.bodyBytes);
        throw Exception("서버 에러: ${response.statusCode}\n$errorBody");
      }
    } catch (e) {
      print('❌ 맛집 검색 실패: $e');
      setState(() {
        _errorMessage = '검색 중 오류가 발생했습니다.\n${e.toString()}';
        _restaurantList = [];
      });
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
                    _selectedRestaurant = null;
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
          if (lat != null && lng != null)
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
        title: const Text('맛집 검색'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: Column(
        children: [
          // 검색 바
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                        hintText: '음식 이름을 입력하세요 (예: 양념치킨)',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _restaurantList = [];
                              _markers.clear();
                              _errorMessage = '';
                              _hasSearched = false;
                              _selectedRestaurant = null; // ⭐️ 선택 해제
                            });
                            _addMyLocationMarker(); // 내 위치 마커 복원
                            setState(() {});
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!)
                        ),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!)
                        ),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Theme.of(context).primaryColor)
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(vertical: 14)
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _searchRestaurants();
                      }
                    },
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _searchRestaurants,
                  icon: _isLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Icon(Icons.search),
                  label: const Text('검색'),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      backgroundColor: const Color(0xFF1a3344),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)
                      )
                  ),
                ),
              ],
            ),
          ),
          // 맵 또는 에러 메시지
          Expanded(
            child: Stack( // ⭐️ Column -> Stack으로 변경
              children: [
                // 1. 구글 맵
                GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        _currentPosition?.latitude ?? 37.5665,
                        _currentPosition?.longitude ?? 126.9780,
                      ),
                      zoom: 14.0,
                    ),
                    markers: _markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    mapType: MapType.normal,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    // ⭐️ 지도 탭 시 선택 해제
                    onTap: (LatLng position) {
                      if (_selectedRestaurant != null) {
                        setState(() {
                          _selectedRestaurant = null;
                        });
                      }
                    }
                ),

                // 2. 로딩 오버레이 (검색 중일 때)
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
                            "맛집 검색 중...",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 3. 에러 메시지 (검색 후 결과가 없을 때)
                if (_errorMessage.isNotEmpty && _hasSearched && !_isLoading)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8
                            )
                          ]
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey[400]), // ⭐️ 아이콘 변경
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 4. 하단 상세 정보 카드 (선택 시)
                if (_selectedRestaurant != null)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: _buildRestaurantDetailCard(_selectedRestaurant!),
                  ),

                // 5. 하단 검색 결과 요약 (선택 안됐을 시)
                if (_selectedRestaurant == null && _hasSearched && _restaurantList.isNotEmpty && !_isLoading)
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
          ),
        ],
      ),
    );
  }
}