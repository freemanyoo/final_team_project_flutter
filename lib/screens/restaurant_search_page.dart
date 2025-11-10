// lib/screens/restaurant_search_page.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
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

  @override
  void initState() {
    super.initState();
    // 초기 위치를 먼저 설정하여 맵이 안전하게 표시되도록 함
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
    // 비동기로 위치 가져오기 시도
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
        // iOS에서는 권한 확인을 먼저 하고, 거부된 경우 기본 위치 사용
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

    if (_currentPosition == null) {
      await _getCurrentLocation();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _hasSearched = true;
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

        // 마커 생성
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
          }
        }

        // 카메라 이동
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('맛집 검색'),
        backgroundColor: Colors.white,
        elevation: 0,
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
                                });
                                if (_currentPosition != null) {
                                  _markers.add(
                                    Marker(
                                      markerId: const MarkerId('my_location'),
                                      position: LatLng(
                                        _currentPosition!.latitude,
                                        _currentPosition!.longitude,
                                      ),
                                      icon: BitmapDescriptor.defaultMarkerWithHue(
                                          BitmapDescriptor.hueBlue),
                                      infoWindow: const InfoWindow(title: '내 위치'),
                                    ),
                                  );
                                }
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: const Text('검색'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          // 맵 또는 에러 메시지
          Expanded(
            child: _isLoading && !_hasSearched
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty && _hasSearched
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : GoogleMap(
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
                      ),
          ),
        ],
      ),
    );
  }
}

