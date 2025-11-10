// lib/screens/simple_map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:developer';

/// navbar의 "maps" 탭에서 사용할 단순 지도 화면
/// 내 위치만 표시
class SimpleMapScreen extends StatefulWidget {
  const SimpleMapScreen({Key? key}) : super(key: key);

  @override
  _SimpleMapScreenState createState() => _SimpleMapScreenState();
}

class _SimpleMapScreenState extends State<SimpleMapScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  Position? _currentPosition;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  // 현재 위치만 가져오기
  Future<void> _loadCurrentLocation() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() {
            _errorMessage = '위치 권한이 거부되었습니다.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _errorMessage = '위치 권한이 영구적으로 거부되었습니다.\n설정에서 권한을 허용해주세요.';
          _isLoading = false;
        });
        return;
      }

      // 현재 위치 가져오기
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      log("위치 가져오기 에러: $e");
      if (!mounted) return;
      setState(() {
        _errorMessage = '위치 정보를 가져올 수 없습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('지도'),
        backgroundColor: const Color(0xFF1a3344),
        foregroundColor: Colors.white,
        actions: [
          // 현재 위치로 이동 버튼
          if (_currentPosition != null)
            IconButton(
              icon: const Icon(Icons.my_location),
              onPressed: () {
                if (mounted && _mapController != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                      ),
                    ),
                  );
                }
              },
            ),
          // 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. 지도 표시
          if (_currentPosition != null && !_isLoading)
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                ),
                zoom: 15,
              ),
              // cloudMapId는 Google Cloud Map ID가 있을 때만 사용
              // cloudMapId: '9ab22eab75ae97fa',
              onMapCreated: (controller) {
                _mapController = controller;
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapType: MapType.normal,
              zoomControlsEnabled: true,
            )
          // 2. 로딩 중
          else if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("위치를 가져오는 중..."),
                ],
              ),
            )
          // 3. 에러 발생
          else if (_errorMessage.isNotEmpty)
              Center(
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
                        onPressed: _loadCurrentLocation,
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

          // 4. 하단 정보 카드
          if (!_isLoading && _errorMessage.isEmpty && _currentPosition != null)
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF1a3344)),
                        SizedBox(width: 8),
                        Text(
                          '현재 위치',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '위도: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '경도: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
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
    super.dispose();
  }
}