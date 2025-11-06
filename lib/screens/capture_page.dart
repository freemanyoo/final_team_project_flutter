// lib/screens/capture_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:async';

class CapturePage extends StatefulWidget {
  final Function(Map<String, dynamic>) onFoodDetected;

  const CapturePage({super.key, required this.onFoodDetected});

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  File? _imageFile;
  File? _imageFileForAnalysis; // 분석용 이미지 파일 백업 (비디오 표시를 위해 _imageFile을 null로 만들 때 사용)
  bool _showImagePreview = false; // 이미지 미리보기 표시 여부
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: -20, end: 20).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // 비디오 플레이어 초기화 (비동기로 처리하여 UI 블로킹 방지)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVideo();
    });
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/video.mp4');
      await _videoController!.initialize();
      if (mounted) {
        _videoController!.setLooping(true); // 반복 재생
        _videoController!.play();
        setState(() {});
      }
    } catch (e) {
      print('비디오 로드 오류: $e');
      // 비디오 로드 실패 시에도 UI는 정상 표시
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // 카메라로 사진 촬영
  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        // 비디오 정지
        _videoController?.pause();
        
        setState(() {
          _imageFile = File(image.path);
          _showImagePreview = true; // 이미지 미리보기 표시
        });
        // 바로 분석하지 않고 미리보기만 표시
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카메라 오류: $e')),
        );
      }
    }
  }

  // 갤러리에서 사진 선택
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        // 비디오 정지
        _videoController?.pause();
        
        setState(() {
          _imageFile = File(image.path);
          _showImagePreview = true; // 이미지 미리보기 표시
        });
        // 바로 분석하지 않고 미리보기만 표시
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('갤러리 오류: $e')),
        );
      }
    }
  }

  // 이미지 확인하고 분석 시작
  void _confirmAndAnalyze() {
    if (_imageFile != null) {
      setState(() {
        _showImagePreview = false; // 미리보기 숨기고 분석 화면으로
        // 분석 중에는 비디오를 다시 재생하기 위해 이미지 파일을 임시로 null 처리
        // 실제 분석은 _processImage에서 _imageFile을 사용하므로 백업해둠
        _imageFileForAnalysis = _imageFile;
        _imageFile = null; // 화면에 비디오가 보이도록
      });
      // 비디오 다시 재생
      _videoController?.play();
      _processImage();
    }
  }

  // 이미지 다시 선택
  void _retakeImage() {
    setState(() {
      _imageFile = null;
      _showImagePreview = false;
    });
    // 비디오 다시 재생
    _videoController?.play();
  }

  void _processImage() {
    setState(() {
      _isProcessing = true;
    });

    // 분석용 이미지 파일 사용 (백업된 파일 또는 현재 파일)
    final imageFileToAnalyze = _imageFileForAnalysis ?? _imageFile;

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        final detectedFood = {
          'name': '해산물 스파게티',
          'calories': 426,
          'weight': 340,
          'rating': 7,
          'imagePath': imageFileToAnalyze?.path,
        };
        widget.onFoodDetected(detectedFood);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _imageFile != null
                              ? Image.file(
                                  _imageFile!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                )
                              : _videoController != null && _videoController!.value.isInitialized
                                  ? AspectRatio(
                                      aspectRatio: _videoController!.value.aspectRatio,
                                      child: VideoPlayer(_videoController!),
                                    )
                                  : Container(
                                      height: 200,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFF1a4d4d),
                                            Color(0xFF0d2626),
                                          ],
                                        ),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                        ),
                      ),
                      // 이미지 미리보기 모드
                      if (_showImagePreview && _imageFile != null) ...[
                        const SizedBox(height: 24),
                        const Text(
                          '사진을 확인해주세요',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '이미지가 올바르게 선택되었나요?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ] else ...[
                        const SizedBox(height: 32),
                      ],
                      // 버튼 영역
                      if (_showImagePreview && _imageFile != null) ...[
                        // 이미지 미리보기 모드: 확인 및 다시 촬영 버튼
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _retakeImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[200],
                                  foregroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  '다시 촬영',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF667eea),
                                      Color(0xFF764ba2),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: ElevatedButton(
                                  onPressed: _confirmAndAnalyze,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    '확인',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // 일반 모드: 사진 촬영 및 갤러리 버튼
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF667eea),
                                Color(0xFF764ba2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _takePicture,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              '📷 사진 촬영하기',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _pickFromGallery,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              '🖼️ 갤러리에서 선택',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '앱을 닫거나 기기를 잠그지 마시오',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
          if (_isProcessing)
            // 비디오 위에 반투명 오버레이와 로딩 표시
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '음식을 분석하고 있습니다...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
}