// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';
import '../services/analysis_service.dart';
import '../util/auth_helper.dart';
import 'result_page.dart';

class HomePage extends StatefulWidget {
  final Function(Map<String, dynamic>) onFoodDetected;
  final VoidCallback? onBack; // 뒤로가기 콜백 (선택적)

  const HomePage({super.key, required this.onFoodDetected, this.onBack});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  File? _imageFile;
  File? _imageFileForAnalysis; // 분석용 이미지 파일 백업 (비디오 표시를 위해 _imageFile을 null로 만들 때 사용)
  bool _showImagePreview = false; // 이미지 미리보기 표시 여부
  ImageSource? _imageSource; // 이미지 소스 추적 (카메라 또는 갤러리)
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
      print('📷 카메라 촬영 시작...');
      
      // 카메라 권한 확인 및 요청 (Android는 기존대로 유지, iOS만 타임아웃 추가)
      try {
        final cameraStatus = Platform.isIOS 
            ? await Permission.camera.status.timeout(
                const Duration(seconds: 2), 
                onTimeout: () {
                  print('⚠️ iOS 카메라 권한 확인 타임아웃 - 계속 진행');
                  return PermissionStatus.denied;
                })
            : await Permission.camera.status; // Android는 기존대로
        
        print('📷 현재 카메라 권한 상태: $cameraStatus');
        
        // 영구 거부 상태인 경우 바로 설정으로 이동 (카메라 사용 시도 안 함)
        if (cameraStatus.isPermanentlyDenied) {
          print('📷 카메라 권한이 영구적으로 거부됨 - 설정으로 이동 필요');
          if (mounted) {
            // 더 명확한 안내 다이얼로그 표시
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('카메라 권한 필요'),
                content: const Text(
                  '카메라 권한이 영구적으로 거부되었습니다.\n\n'
                  '카메라를 사용하려면:\n'
                  '1. 아래 "설정 열기" 버튼을 누르세요\n'
                  '2. 앱 설정 화면에서 카메라 권한을 허용하세요\n'
                  '3. 앱으로 돌아와서 다시 시도하세요',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await openAppSettings();
                    },
                    child: const Text('설정 열기'),
                  ),
                ],
              ),
            );
          }
          return; // 카메라 사용 시도하지 않고 종료
        }
        
        if (!cameraStatus.isGranted) {
          print('📷 카메라 권한 요청 중...');
          final requestResult = Platform.isIOS
              ? await Permission.camera.request().timeout(
                  const Duration(seconds: 5),
                  onTimeout: () {
                    print('⚠️ iOS 카메라 권한 요청 타임아웃 - 계속 진행');
                    return PermissionStatus.denied;
                  })
              : await Permission.camera.request(); // Android는 기존대로
          
          print('📷 카메라 권한 요청 결과: $requestResult');
          
          if (!requestResult.isGranted) {
            // 요청 후에도 거부된 경우
            if (requestResult.isPermanentlyDenied) {
              print('📷 카메라 권한이 영구적으로 거부됨 - 설정으로 이동 필요');
              if (mounted) {
                // 더 명확한 안내 다이얼로그 표시
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('카메라 권한 필요'),
                    content: const Text(
                      '카메라 권한이 영구적으로 거부되었습니다.\n\n'
                      '카메라를 사용하려면:\n'
                      '1. 아래 "설정 열기" 버튼을 누르세요\n'
                      '2. 앱 설정 화면에서 카메라 권한을 허용하세요\n'
                      '3. 앱으로 돌아와서 다시 시도하세요',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('취소'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await openAppSettings();
                        },
                        child: const Text('설정 열기'),
                      ),
                    ],
                  ),
                );
              }
            } else {
              // 일반 거부
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('카메라 권한이 필요합니다.\n설정에서 권한을 허용해주세요.'),
                    duration: const Duration(seconds: 4),
                    backgroundColor: Colors.orange[700],
                    action: SnackBarAction(
                      label: '설정 열기',
                      textColor: Colors.white,
                      onPressed: () async {
                        await openAppSettings();
                      },
                    ),
                  ),
                );
              }
            }
            return; // 카메라 사용 시도하지 않고 종료
          }
        }
      } catch (e) {
        // iOS 시뮬레이터에서만 에러 발생 가능, Android는 기존대로
        if (Platform.isIOS) {
          print('⚠️ iOS 카메라 권한 확인 중 에러 (계속 진행): $e');
        } else {
          print('⚠️ 카메라 권한 확인 중 에러: $e');
        }
        // 에러 발생해도 계속 진행 (시뮬레이터 등)
      }
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        print('✅ 카메라 촬영 완료: ${image.path}');
        // 비디오 정지
        _videoController?.pause();
        
        if (mounted) {
          setState(() {
            _imageFile = File(image.path);
            _imageSource = ImageSource.camera; // 카메라로 촬영
            _showImagePreview = true; // 이미지 미리보기 표시
          });
        }
        // 바로 분석하지 않고 미리보기만 표시
      } else {
        print('⚠️ 카메라 촬영 취소됨');
      }
    } catch (e, stackTrace) {
      print('❌ 카메라 오류 발생: $e');
      print('스택 트레이스: $stackTrace');
      if (mounted) {
        // 시뮬레이터 또는 카메라 사용 불가능한 경우 친절한 메시지 표시
        String errorMessage = '카메라를 사용할 수 없습니다.';
        final errorString = e.toString().toLowerCase();
        
        if (errorString.contains('simulator') || 
            errorString.contains('unsupported device') ||
            errorString.contains('backwidedual') ||
            errorString.contains('backauto') ||
            errorString.contains('camera not available')) {
          errorMessage = '시뮬레이터에서는 카메라를 사용할 수 없습니다.\n갤러리에서 사진을 선택해주세요.';
        } else if (errorString.contains('permission') || 
                   errorString.contains('권한') ||
                   errorString.contains('camera permission')) {
          errorMessage = '카메라 권한이 필요합니다.\n설정에서 권한을 허용해주세요.';
        } else if (errorString.contains('camera') && errorString.contains('not available')) {
          errorMessage = '카메라를 사용할 수 없습니다.\n갤러리에서 사진을 선택해주세요.';
        } else {
          errorMessage = '카메라 오류가 발생했습니다.\n갤러리에서 사진을 선택해주세요.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.orange[700],
          ),
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
          _imageSource = ImageSource.gallery; // 갤러리에서 선택
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

  // 이미지 다시 선택/촬영
  void _retakeImage() {
    setState(() {
      _imageFile = null;
      _imageSource = null;
      _showImagePreview = false;
    });
    // 비디오 다시 재생
    _videoController?.play();
  }

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
    });

    // 분석용 이미지 파일 사용 (백업된 파일 또는 현재 파일)
    final imageFileToAnalyze = _imageFileForAnalysis ?? _imageFile;

    if (imageFileToAnalyze == null) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지 파일을 찾을 수 없습니다.')),
        );
      }
      return;
    }

    try {
      final analysisService = AnalysisService();
      
      // 백엔드 API 호출 (userId는 선택적, 백엔드가 JWT 토큰에서 자동으로 추출)
      final result = await analysisService.analyzeImage(
        imageFile: imageFileToAnalyze,
        // userId는 전달하지 않음 (백엔드가 JWT 토큰에서 자동으로 추출)
        // youtubeKeyword: null, // 필요시 추가
        // youtubeOrder: 'relevance',
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        // 결과를 Map 형태로 변환하여 전달
        final detectedFood = result.toMap();
        detectedFood['imagePath'] = imageFileToAnalyze.path;
        
        // 디버그 로그
        print('✅ 분석 완료: ${detectedFood.toString()}');
        print('📞 ResultPage로 이동 시작...');
        
        // 콜백 호출 (MainScreen에 알림)
        widget.onFoodDetected(detectedFood);
        
        // HomePage를 ResultPage로 교체
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultPage(
                food: detectedFood,
                onBack: () {
                  Navigator.pop(context);
                },
              ),
            ),
          );
          print('✅ ResultPage로 이동 완료');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        String errorMessage = '분석 중 오류가 발생했습니다.';
        if (e is AnalysisException) {
          errorMessage = e.message;
        } else {
          errorMessage = '오류: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 시스템 뒤로가기 버튼 비활성화
      onPopInvoked: (didPop) {
        if (didPop) return;
        // 뒤로가기 버튼을 눌렀을 때 onBack 콜백 호출
        if (widget.onBack != null) {
          widget.onBack!();
        } else {
          // onBack이 없으면 기본 동작 (Navigator.pop)
          Navigator.pop(context);
        }
      },
      child: Container(
      color: Colors.white,
      child: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.4, // 화면 높이의 40%
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
                              height: MediaQuery.of(context).size.height * 0.4, // 화면 높이의 40%
                              fit: BoxFit.cover,
                              cacheWidth: (MediaQuery.of(context).size.width * 2).toInt(),
                              filterQuality: FilterQuality.medium,
                            )
                          : _videoController != null && _videoController!.value.isInitialized
                              ? AspectRatio(
                                  aspectRatio: _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                )
                              : Container(
                                    height: MediaQuery.of(context).size.height * 0.4, // 화면 높이의 40%
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
                    const SizedBox(height: 48),
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
                    const SizedBox(height: 48),
                  ] else ...[
                    const SizedBox(height: 40),
                    const Text(
                      '사진을 찍어 음식을 분석해보세요',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '영양 정보와 칼로리를 확인할 수 있습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
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
                              child: Text(
                                _imageSource == ImageSource.camera ? '다시 촬영' : '다시 선택',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
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
                      const SizedBox(height: 24),
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
      ),
    );
  }
}
