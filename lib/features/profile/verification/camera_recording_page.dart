import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/services.dart';
import 'package:siladesbeng_mobile/services/kyc_service.dart';

class CameraRecordingPage extends StatefulWidget {
  final int? kycId;
  final String? nik;
  final String? name;
  final String? address;
  final String? rtRw;
  final String? kecamatan;
  final String? desa;

  const CameraRecordingPage({
    super.key,
    required this.kycId,
    this.nik,
    this.name,
    this.address,
    this.rtRw,
    this.kecamatan,
    this.desa,
  });

  @override
  State<CameraRecordingPage> createState() => _CameraRecordingPageState();
}

class _CameraRecordingPageState extends State<CameraRecordingPage>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  String? _cameraError;

  // ML Kit Face Detector with accurate mode & classification for liveness
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  bool _isProcessingImage = false;
  bool _isRecording = false;

  // Liveness Stages (Shopee / DANA / Tokopedia style):
  // 0: Posisikan Wajah (Hadap Lurus / Center)
  // 1: Tengok Kanan (Turn Right)
  // 2: Tengok Kiri (Turn Left)
  // 3: Kedipkan Mata (Blink Eyes)
  // 4: Selesai / Terverifikasi (Success)
  int _livenessStep = 0;
  bool _isFaceInstructionSuccess = false;

  // Consecutive frames needed to confirm dynamic motion
  int _confirmationFrames = 0;
  int? _firstTurnSign; // Track direction of first head turn for opposite check

  // Dynamic required frames per step — blink is very fast so 1 frame is enough
  int get _requiredFramesForStep {
    switch (_livenessStep) {
      case 0: return 3;  // Center face — need stability
      case 1: return 2;  // Turn head — moderate
      case 2: return 2;  // Opposite turn — moderate
      case 3: return 1;  // Blink — very fast (~150ms), 1 frame is enough
      default: return 2;
    }
  }

  // Real-time Guidance Warnings
  bool _faceDetected = false;
  String? _brightnessWarning;
  String? _facePositionWarning;

  final KycService _kycService = KycService();
  bool _isUploadingFace = false;

  // Animations
  late AnimationController _scannerAnimController;
  late AnimationController _pulseAnimController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeCamera(useFrontCamera: true);
  }

  void _initAnimations() {
    _scannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.03).animate(
      CurvedAnimation(parent: _pulseAnimController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera({bool useFrontCamera = true}) async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() => _cameraError = 'Kamera tidak ditemukan di perangkat ini.');
        return;
      }

      CameraDescription? selectedCamera;
      for (var camera in _cameras!) {
        if (useFrontCamera && camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        } else if (!useFrontCamera && camera.lensDirection == CameraLensDirection.back) {
          selectedCamera = camera;
          break;
        }
      }

      selectedCamera ??= _cameras!.first;

      await _cameraController?.dispose();

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraError = null;
        });

        // Auto-start scanning stream once camera is ready
        _startLivenessDetection();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = 'Gagal mengakses kamera: ${e.toString()}';
        });
      }
    }
  }

  @override
  void dispose() {
    _scannerAnimController.dispose();
    _pulseAnimController.dispose();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _startLivenessDetection() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isRecording) return;

    setState(() {
      _isRecording = true;
      _livenessStep = 0;
      _isFaceInstructionSuccess = false;
      _confirmationFrames = 0;
      _firstTurnSign = null;
      _faceDetected = false;
      _facePositionWarning = null;
    });

    try {
      await _cameraController!.startImageStream((CameraImage image) {
        if (_isProcessingImage || !_isRecording) return;
        _isProcessingImage = true;
        _processCameraImage(image);
      });
    } catch (e) {
      debugPrint('Error starting image stream: $e');
      if (mounted) {
        setState(() => _isRecording = false);
      }
    }
  }

  InputImageRotation _getImageRotation(CameraDescription camera) {
    if (Platform.isAndroid) {
      final int sensorOrientation = camera.sensorOrientation;
      final orientations = {
        0: InputImageRotation.rotation0deg,
        90: InputImageRotation.rotation90deg,
        180: InputImageRotation.rotation180deg,
        270: InputImageRotation.rotation270deg,
      };
      return orientations[sensorOrientation] ?? InputImageRotation.rotation0deg;
    } else {
      return InputImageRotation.rotation0deg;
    }
  }

  void _processCameraImage(CameraImage image) async {
    try {
      // ── Smart Brightness Check ──
      if (image.planes.isNotEmpty) {
        final Uint8List yPlane = image.planes[0].bytes;
        int sum = 0;
        int sampleCount = 0;
        for (int i = 0; i < yPlane.length; i += 120) {
          sum += yPlane[i];
          sampleCount++;
        }

        if (sampleCount > 0) {
          double avgBrightness = sum / sampleCount;
          String? warning;
          if (avgBrightness < 35) {
            warning = 'Kurang Cahaya: Cari tempat yang lebih terang';
          } else if (avgBrightness > 225) {
            warning = 'Terlalu Silau: Hindari cahaya matahari langsung';
          }

          if (_brightnessWarning != warning && mounted) {
            setState(() => _brightnessWarning = warning);
          }
        }
      }

      final Uint8List bytes = image.planes[0].bytes;
      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

      final camera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      final InputImageRotation imageRotation = _getImageRotation(camera);
      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
      if (inputImageFormat == null) {
        _isProcessingImage = false;
        return;
      }

      final metadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: metadata);
      final faces = await _faceDetector.processImage(inputImage);

      if (mounted) {
        if (faces.isEmpty) {
          setState(() {
            _faceDetected = false;
            _facePositionWarning = 'Posisikan wajah di dalam lingkaran';
            _confirmationFrames = 0;
          });
        } else {
          final face = faces.first;
          final faceWidth = face.boundingBox.width;
          final faceHeight = face.boundingBox.height;
          final minFaceSize = imageSize.width * 0.16;

          setState(() => _faceDetected = true);

          if (faceWidth < minFaceSize || faceHeight < minFaceSize) {
            setState(() {
              _facePositionWarning = 'Dekatkan wajah ke kamera';
              _confirmationFrames = 0;
            });
          } else {
            setState(() => _facePositionWarning = null);
            if (_isRecording) {
              _evaluateLiveness(face);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error Face Detection: $e");
    } finally {
      if (mounted) {
        _isProcessingImage = false;
      }
    }
  }

  void _evaluateLiveness(Face face) {
    if (!_isRecording || _isFaceInstructionSuccess) return;

    bool conditionMet = false;

    // ── STAGE 0: Posisikan Wajah (Hadap Depan / Center) ──
    if (_livenessStep == 0) {
      final double? headY = face.headEulerAngleY;
      final double? headZ = face.headEulerAngleZ;
      if (headY != null && headZ != null) {
        // More tolerant: allow up to 15° tilt in both axes
        if (headY.abs() < 15 && headZ.abs() < 15) {
          conditionMet = true;
        }
      } else {
        conditionMet = true;
      }
    }
    // ── STAGE 1: Gerakkan Kepala ke Samping (First Turn — any direction) ──
    else if (_livenessStep == 1) {
      final double? headY = face.headEulerAngleY;
      if (headY != null && headY.abs() > 12) {
        // Record which direction user turned first
        _firstTurnSign = headY > 0 ? 1 : -1;
        conditionMet = true;
      }
    }
    // ── STAGE 2: Gerakkan ke Arah Sebaliknya (Opposite direction) ──
    else if (_livenessStep == 2) {
      final double? headY = face.headEulerAngleY;
      if (headY != null && headY.abs() > 12) {
        final int currentSign = headY > 0 ? 1 : -1;
        // Must be opposite direction from stage 1
        if (_firstTurnSign == null || currentSign != _firstTurnSign) {
          conditionMet = true;
        }
      }
    }
    // ── STAGE 3: Kedipkan Mata (Blink — more lenient threshold) ──
    else if (_livenessStep == 3) {
      final double? leftEye = face.leftEyeOpenProbability;
      final double? rightEye = face.rightEyeOpenProbability;
      if (leftEye != null && rightEye != null) {
        // Average of both eyes, threshold 0.45 (was 0.32 — way too strict)
        if ((leftEye + rightEye) / 2 < 0.45) {
          conditionMet = true;
        }
      } else if (leftEye != null && leftEye < 0.45) {
        // Fallback: single eye detection
        conditionMet = true;
      } else if (rightEye != null && rightEye < 0.45) {
        conditionMet = true;
      }
    }

    if (conditionMet) {
      _confirmationFrames++;
      if (_confirmationFrames >= _requiredFramesForStep && !_isFaceInstructionSuccess) {
        HapticFeedback.mediumImpact();

        setState(() {
          _isFaceInstructionSuccess = true;
          _confirmationFrames = 0;
        });

        Future.delayed(const Duration(milliseconds: 950), () {
          if (!mounted || !_isRecording) return;

          setState(() {
            _isFaceInstructionSuccess = false;
            _livenessStep++;
            _confirmationFrames = 0;
          });

          if (_livenessStep >= 4) {
            _cameraController?.stopImageStream().then((_) async {
              String? imagePath;
              try {
                final file = await _cameraController?.takePicture();
                imagePath = file?.path;
              } catch (e) {
                debugPrint("Gagal mengambil foto selfie: $e");
              }
              _finishVerification(imagePath);
            });
          }
        });
      }
    } else {
      _confirmationFrames = 0;
    }
  }

  Future<void> _finishVerification(String? faceImagePath) async {
    setState(() {
      _isRecording = false;
      _isUploadingFace = true;
    });

    HapticFeedback.heavyImpact();

    if (widget.kycId != null) {
      final response = await _kycService.submitFace(
        kycId: widget.kycId!,
        faceData: [
          {
            'timestamp': DateTime.now().toIso8601String(),
            'status': 'liveness_passed',
            'vendor': 'dukcapil_biometric_standard',
          }
        ],
        faceImagePath: faceImagePath,
        nik: widget.nik,
        name: widget.name,
        address: widget.address,
        rtRw: widget.rtRw,
        kecamatan: widget.kecamatan,
        desa: widget.desa,
      );

      if (!mounted) return;
      setState(() => _isUploadingFace = false);

      if (response['status'] != 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Gagal memproses verifikasi biometrik'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else {
      setState(() => _isUploadingFace = false);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_verified', true);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AnimatedSuccessDialog(
        message: 'Verifikasi Biometrik Wajah Berhasil!',
        isLogout: false,
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    Navigator.pop(context);
    Navigator.pop(context, true);
  }

  // ── Helper Titles & Instructions ──
  String _getCurrentInstructionTitle() {
    if (_isFaceInstructionSuccess) return 'Gerakan Terdeteksi!';
    if (!_faceDetected) return 'Posisikan Wajah';

    switch (_livenessStep) {
      case 0:
        return 'Tatap Lurus ke Depan';
      case 1:
        return 'Tolehkan Kepala ke Kanan';
      case 2:
        return _firstTurnSign == -1
            ? 'Tolehkan Kepala ke Kanan'
            : 'Tolehkan Kepala ke Kiri';
      case 3:
        return 'Kedipkan Kedua Mata';
      default:
        return 'Memproses Biometrik...';
    }
  }

  String _getCurrentInstructionSubtitle() {
    if (_isFaceInstructionSuccess) return 'Bagus! Tahan posisi sebentar...';
    if (!_faceDetected) return 'Posisikan wajah Anda tepat di dalam bingkai oval';

    switch (_livenessStep) {
      case 0:
        return 'Pastikan wajah berada di tengah lingkaran';
      case 1:
        return 'Tolehkan kepala perlahan ke arah kanan';
      case 2:
        return _firstTurnSign == -1
            ? 'Sekarang tolehkan kepala ke arah kanan'
            : 'Sekarang tolehkan kepala ke arah kiri (sebaliknya)';
      case 3:
        return 'Kedipkan kedua mata Anda secara wajar';
      default:
        return 'Menyinkronkan data biometrik kependudukan...';
    }
  }

  double _getLivenessProgressValue() {
    if (_livenessStep >= 4) return 1.0;
    double base = _livenessStep * 0.25;
    if (_isFaceInstructionSuccess) base += 0.25;
    return base.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double ovalWidth = size.width * 0.78;
    final double ovalHeight = ovalWidth * 1.12;

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. CAMERA VIEWPORT ──
          if (_cameraError != null)
            Center(
              child: Padding(
                padding: EdgeInsets.all(24.0.w),
                child: Text(
                  _cameraError!,
                  style: TextStyle(color: Colors.redAccent, fontSize: 14.sp),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else if (_isCameraInitialized && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),

          // ── 2. SHOPEE / DANA STYLE DARK OVAL MASK CUTOUT ──
          if (_isCameraInitialized && _cameraController != null)
            CustomPaint(
              size: Size(size.width, size.height),
              painter: FaceScanMaskPainter(
                ovalWidth: ovalWidth,
                ovalHeight: ovalHeight,
                progress: _getLivenessProgressValue(),
                isSuccess: _isFaceInstructionSuccess,
                isFaceDetected: _faceDetected,
                laserProgress: _scannerAnimController.value,
              ),
            ),

          // ── 3. TOP APP BAR & STEP PROGRESS BAR ──
          SafeArea(
            child: Column(
              children: [
                // Top Header Row
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(120),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(150),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 16.sp),
                            SizedBox(width: 6.w),
                            Text(
                              'e-KYC Liveness Biometrik',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 40.w), // Spacer balance
                    ],
                  ),
                ),

                SizedBox(height: 6.h),

                // 4-Step Indicator Pills
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Row(
                    children: [
                      _buildStepPill('1. Posisi', 0),
                      SizedBox(width: 6.w),
                      _buildStepPill('2. Kanan', 1),
                      SizedBox(width: 6.w),
                      _buildStepPill('3. Kiri', 2),
                      SizedBox(width: 6.w),
                      _buildStepPill('4. Kedip', 3),
                    ],
                  ),
                ),

                // Smart Guidance Alert Badge
                if (_brightnessWarning != null || _facePositionWarning != null)
                  Padding(
                    padding: EdgeInsets.only(top: 14.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: (_brightnessWarning != null
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFEF4444))
                            .withAlpha(220),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(80),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _brightnessWarning != null
                                ? Icons.wb_sunny_rounded
                                : Icons.center_focus_strong_rounded,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            _brightnessWarning ?? _facePositionWarning!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── 4. FLOATING INTERACTIVE INSTRUCTION CARD (BOTTOM) ──
          Positioned(
            bottom: 36.h,
            left: 20.w,
            right: 20.w,
            child: ScaleTransition(
              scale: _isFaceInstructionSuccess ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: _isFaceInstructionSuccess
                      ? const Color(0xFF064E3B).withAlpha(240)
                      : const Color(0xFF0F172A).withAlpha(235),
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(
                    color: _isFaceInstructionSuccess
                        ? const Color(0xFF10B981)
                        : const Color(0xFF2563EB).withAlpha(120),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isFaceInstructionSuccess
                              ? const Color(0xFF10B981)
                              : const Color(0xFF2563EB))
                          .withAlpha(70),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Animated Live Instruction Icon
                    _LiveInstructionIcon(
                      livenessStep: _livenessStep,
                      isSuccess: _isFaceInstructionSuccess,
                      faceDetected: _faceDetected,
                      firstTurnSign: _firstTurnSign,
                    ),

                    SizedBox(width: 14.w),

                    // Instruction Texts
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getCurrentInstructionTitle(),
                            style: TextStyle(
                              color: _isFaceInstructionSuccess
                                  ? const Color(0xFF6EE7B7)
                                  : Colors.white,
                              fontSize: 15.5.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            _getCurrentInstructionSubtitle(),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── 5. UPLOAD / FINALIZING OVERLAY ──
          if (_isUploadingFace)
            Container(
              color: Colors.black.withAlpha(210),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFF10B981),
                      strokeWidth: 3.5,
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Menyinkronkan Data Biometrik...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Verifikasi Dukcapil / SIAK sedang diproses',
                      style: TextStyle(color: Colors.white60, fontSize: 12.5.sp),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepPill(String label, int stepIndex) {
    final bool isPassed = _livenessStep > stepIndex;
    final bool isCurrent = _livenessStep == stepIndex;

    Color pillBg;
    Color textCol;
    Color borderCol;

    if (isPassed) {
      pillBg = const Color(0xFF10B981);
      textCol = Colors.white;
      borderCol = const Color(0xFF10B981);
    } else if (isCurrent) {
      pillBg = const Color(0xFF2563EB);
      textCol = Colors.white;
      borderCol = const Color(0xFF60A5FA);
    } else {
      pillBg = Colors.white.withAlpha(15);
      textCol = Colors.white54;
      borderCol = Colors.white10;
    }

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(vertical: 6.h),
        decoration: BoxDecoration(
          color: pillBg,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: borderCol, width: isCurrent ? 1.5 : 1),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withAlpha(90),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textCol,
            fontSize: 11.sp,
            fontWeight: isCurrent || isPassed ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIVE ANIMATED INSTRUCTION BADGE (DYNAMIC MOTION & EYE BLINKING)
// ═══════════════════════════════════════════════════════════════════════════
class _LiveInstructionIcon extends StatefulWidget {
  final int livenessStep;
  final bool isSuccess;
  final bool faceDetected;
  final int? firstTurnSign;

  const _LiveInstructionIcon({
    required this.livenessStep,
    required this.isSuccess,
    required this.faceDetected,
    this.firstTurnSign,
  });

  @override
  State<_LiveInstructionIcon> createState() => _LiveInstructionIconState();
}

class _LiveInstructionIconState extends State<_LiveInstructionIcon>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _turnController;
  late AnimationController _blinkController;
  late AnimationController _successController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _turnAnimation;
  late Animation<double> _blinkScaleAnimation;
  late Animation<double> _successScaleAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Subtle pulsing for center face / reticle
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.90, end: 1.10).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // 2. Gliding swing for head turns (kanan / kiri)
    _turnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _turnAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _turnController, curve: Curves.easeInOutCubic),
    );

    // 3. Realistic human eye blink cycle
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _blinkScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 65), // Mata terbuka
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.05)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 8, // Mengedip cepat
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0.05), weight: 6), // Tertutup sejenak
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 9, // Membuka kembali
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 12), // Istirahat terbuka
    ]).animate(_blinkController);

    // 4. Elastic pop on success
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _successScaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    if (widget.isSuccess) {
      _successController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant _LiveInstructionIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSuccess && widget.isSuccess) {
      _successController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _turnController.dispose();
    _blinkController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSuccess = widget.isSuccess;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 52.w,
      height: 52.w,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isSuccess
              ? const [Color(0xFF10B981), Color(0xFF059669)]
              : const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isSuccess ? const Color(0xFF10B981) : const Color(0xFF3B82F6))
                .withAlpha(isSuccess ? 140 : 100),
            blurRadius: isSuccess ? 16 : 10,
            spreadRadius: isSuccess ? 3 : 1,
          ),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: _buildAnimatedContent(key: ValueKey('${widget.livenessStep}_$isSuccess')),
        ),
      ),
    );
  }

  Widget _buildAnimatedContent({required Key key}) {
    if (widget.isSuccess) {
      return ScaleTransition(
        key: key,
        scale: _successScaleAnimation,
        child: Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 30.sp,
        ),
      );
    }

    switch (widget.livenessStep) {
      case 0:
        // STAGE 0: Posisikan Wajah (Tatap Lurus)
        return AnimatedBuilder(
          key: key,
          animation: _pulseAnimation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Icon(
                    Icons.center_focus_strong_rounded,
                    color: Colors.white.withAlpha(150),
                    size: 29.sp,
                  ),
                ),
                Icon(
                  Icons.face_rounded,
                  color: Colors.white,
                  size: 19.sp,
                ),
              ],
            );
          },
        );

      case 1:
        // STAGE 1: Tolehkan Kepala ke Kanan (Animasi Wajah + Panah meluncur ke kanan)
        return AnimatedBuilder(
          key: key,
          animation: _turnAnimation,
          builder: (context, child) {
            final double slideX = (_turnAnimation.value * 3.w);
            final double tiltAngle = _turnAnimation.value * 0.10;
            return Transform.translate(
              offset: Offset(slideX, 0),
              child: Transform.rotate(
                angle: tiltAngle,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.face_rounded,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    SizedBox(width: 2.w),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ],
                ),
              ),
            );
          },
        );

      case 2:
        // STAGE 2: Tolehkan Kepala ke Kiri (Arah Sebaliknya)
        final bool turnLeft = widget.firstTurnSign != -1;
        return AnimatedBuilder(
          key: key,
          animation: _turnAnimation,
          builder: (context, child) {
            final double direction = turnLeft ? -1.0 : 1.0;
            final double slideX = (_turnAnimation.value * 3.w) * direction;
            final double tiltAngle = (_turnAnimation.value * 0.10) * direction;
            return Transform.translate(
              offset: Offset(slideX, 0),
              child: Transform.rotate(
                angle: tiltAngle,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: turnLeft
                      ? [
                          Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                          SizedBox(width: 2.w),
                          Icon(
                            Icons.face_rounded,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ]
                      : [
                          Icon(
                            Icons.face_rounded,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                          SizedBox(width: 2.w),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 16.sp,
                          ),
                        ],
                ),
              ),
            );
          },
        );

      case 3:
        // STAGE 3: Kedipkan Mata (Animasi Kelopak Mata berkedip secara natural)
        return AnimatedBuilder(
          key: key,
          animation: _blinkScaleAnimation,
          builder: (context, child) {
            final double scaleY = _blinkScaleAnimation.value;
            final bool isShut = scaleY <= 0.22;
            return isShut
                ? Icon(
                    Icons.remove_rounded,
                    color: Colors.white,
                    size: 28.sp,
                  )
                : Transform.scale(
                    scaleY: scaleY,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.remove_red_eye_rounded,
                      color: Colors.white,
                      size: 26.sp,
                    ),
                  );
          },
        );

      default:
        return Icon(
          Icons.verified_user_rounded,
          key: key,
          color: Colors.white,
          size: 26.sp,
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHOPEE / DANA / TOKOPEDIA STYLE BIOMETRIC OVAL MASK CUSTOM PAINTER
// ═══════════════════════════════════════════════════════════════════════════
class FaceScanMaskPainter extends CustomPainter {
  final double ovalWidth;
  final double ovalHeight;
  final double progress; // 0.0 to 1.0
  final bool isSuccess;
  final bool isFaceDetected;
  final double laserProgress; // 0.0 to 1.0 for sweep effect

  FaceScanMaskPainter({
    required this.ovalWidth,
    required this.ovalHeight,
    required this.progress,
    required this.isSuccess,
    required this.isFaceDetected,
    required this.laserProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect fullScreenRect = Offset.zero & size;
    final Offset center = Offset(size.width / 2, size.height * 0.44);

    final Rect ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    // ── 1. DARK BACKGROUND WITH TRANSPARENT OVAL CUTOUT ──
    final Path backgroundPath = Path()..addRect(fullScreenRect);
    final Path ovalPath = Path()..addOval(ovalRect);
    final Path maskPath = Path.combine(PathOperation.difference, backgroundPath, ovalPath);

    final Paint maskPaint = Paint()..color = const Color(0xE0050B14);
    canvas.drawPath(maskPath, maskPaint);

    // ── 2. OVAL BASE TRACK BORDER ──
    final Paint trackBorderPaint = Paint()
      ..color = Colors.white.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawOval(ovalRect, trackBorderPaint);

    // ── 3. GLOWING BIOMETRIC PROGRESS RING ──
    final Color progressColor = isSuccess
        ? const Color(0xFF10B981)
        : (isFaceDetected ? const Color(0xFF2563EB) : const Color(0xFFEF4444));

    // Outer Glow effect
    final Paint glowPaint = Paint()
      ..color = progressColor.withAlpha(isSuccess ? 120 : 70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(ovalRect, glowPaint);

    // Active Progress Arc Stroke
    if (progress > 0) {
      final Paint progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: isSuccess
              ? [const Color(0xFF34D399), const Color(0xFF10B981)]
              : [const Color(0xFF60A5FA), const Color(0xFF2FA2F1), const Color(0xFF0284C7)],
        ).createShader(ovalRect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5.5;

      final double sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(ovalRect, -math.pi / 2, sweepAngle, false, progressPaint);
    }

    // ── 4. CORNER HUD BIOMETRIC BRACKET ACCENTS ──
    _drawBiometricCornerBrackets(canvas, center, ovalWidth, ovalHeight, progressColor);

    // ── 5. LASER SWEEP SCAN LINE EFFECT ──
    if (isFaceDetected && !isSuccess) {
      final double laserY = (center.dy - ovalHeight / 2) + (ovalHeight * laserProgress);
      final double halfWidthAtY = (ovalWidth / 2) *
          math.sqrt((1 - math.pow((laserY - center.dy) / (ovalHeight / 2), 2)).clamp(0.0, 1.0));

      final Paint laserPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            const Color(0xFF60A5FA).withAlpha(180),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(center.dx - halfWidthAtY, laserY - 1, halfWidthAtY * 2, 2))
        ..strokeWidth = 2.0;

      canvas.drawLine(
        Offset(center.dx - halfWidthAtY + 10, laserY),
        Offset(center.dx + halfWidthAtY - 10, laserY),
        laserPaint,
      );
    }
  }

  void _drawBiometricCornerBrackets(
    Canvas canvas,
    Offset center,
    double width,
    double height,
    Color color,
  ) {
    final Paint bracketPaint = Paint()
      ..color = color.withAlpha(220)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    const double bracketLen = 18.0;
    final double left = center.dx - width / 2 - 6;
    final double right = center.dx + width / 2 + 6;
    final double top = center.dy - height / 2 - 6;
    final double bottom = center.dy + height / 2 + 6;

    // Top-Left bracket
    canvas.drawLine(Offset(left, top + bracketLen), Offset(left, top), bracketPaint);
    canvas.drawLine(Offset(left, top), Offset(left + bracketLen, top), bracketPaint);

    // Top-Right bracket
    canvas.drawLine(Offset(right - bracketLen, top), Offset(right, top), bracketPaint);
    canvas.drawLine(Offset(right, top), Offset(right, top + bracketLen), bracketPaint);

    // Bottom-Left bracket
    canvas.drawLine(Offset(left, bottom - bracketLen), Offset(left, bottom), bracketPaint);
    canvas.drawLine(Offset(left, bottom), Offset(left + bracketLen, bottom), bracketPaint);

    // Bottom-Right bracket
    canvas.drawLine(Offset(right - bracketLen, bottom), Offset(right, bottom), bracketPaint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - bracketLen), bracketPaint);
  }

  @override
  bool shouldRepaint(covariant FaceScanMaskPainter oldDelegate) {
    return oldDelegate.ovalWidth != ovalWidth ||
        oldDelegate.ovalHeight != ovalHeight ||
        oldDelegate.progress != progress ||
        oldDelegate.isSuccess != isSuccess ||
        oldDelegate.isFaceDetected != isFaceDetected ||
        oldDelegate.laserProgress != laserProgress;
  }
}
