import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class CameraRecordingPage extends StatefulWidget {
  const CameraRecordingPage({super.key});

  @override
  State<CameraRecordingPage> createState() => _CameraRecordingPageState();
}

class _CameraRecordingPageState extends State<CameraRecordingPage> {
  bool _isRecording = false;

  // Tahapan verifikasi
  int _currentStep = 0;
  // 0: Standby, 1: Foto KTP, 2: Rekam Video Wajah

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  String? _cameraError;

  // ML Kit - dengan landmarks dan contours aktif untuk akurasi sudut kepala
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

  // Liveness Steps: 0: Tengok, 1: Kedip, 2: Senyum
  int _livenessStep = 0;
  bool _isFaceInstructionSuccess = false;

  // Frame confirmation counter - memastikan gerakan konsisten
  int _confirmationFrames = 0;
  static const int _requiredFrames = 3;

  // Debug info untuk troubleshoot
  String _debugInfo = '';
  bool _faceDetected = false;

  // Smart Guidance
  String? _brightnessWarning;
  String? _facePositionWarning;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera({bool useFrontCamera = false}) async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(
          () => _cameraError = 'Kamera tidak ditemukan di perangkat ini.',
        );
        return;
      }

      CameraDescription? selectedCamera;
      for (var camera in _cameras!) {
        if (useFrontCamera &&
            camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        } else if (!useFrontCamera &&
            camera.lensDirection == CameraLensDirection.back) {
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
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  void _preparePhotoKTP() {
    setState(() {
      _currentStep = 1;
    });
  }

  Future<void> _takePhotoKTP() async {
    if (!mounted) return;
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final XFile file = await _cameraController!.takePicture();
        debugPrint('KTP Picture saved from camera to ${file.path}');
        _proceedToLiveness();
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> _pickKTPFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      debugPrint('KTP Picture selected from gallery: ${image.path}');
      _proceedToLiveness();
    }
  }

  Future<void> _proceedToLiveness() async {
    setState(() {
      _currentStep = 2;
      _isCameraInitialized = false;
    });
    await _initializeCamera(useFrontCamera: true);
  }

  Future<void> _startLivenessDetection() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isRecording = true;
      _livenessStep = 0;
      _isFaceInstructionSuccess = false;
      _confirmationFrames = 0;
      _debugInfo = '';
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
      setState(() {
        _isRecording = false;
      });
    }
  }

  /// Mendapatkan rotasi input image yang benar berdasarkan platform
  InputImageRotation _getImageRotation(CameraDescription camera) {
    if (Platform.isAndroid) {
      // Pada Android, sensorOrientation biasanya 90 atau 270
      final int sensorOrientation = camera.sensorOrientation;
      final orientations = {
        0: InputImageRotation.rotation0deg,
        90: InputImageRotation.rotation90deg,
        180: InputImageRotation.rotation180deg,
        270: InputImageRotation.rotation270deg,
      };
      return orientations[sensorOrientation] ??
          InputImageRotation.rotation0deg;
    } else {
      // Pada iOS, gunakan rotation0deg
      return InputImageRotation.rotation0deg;
    }
  }

  void _processCameraImage(CameraImage image) async {
    try {
      // --- Smart Guidance (Brightness Check) ---
      if (image.planes.isNotEmpty) {
        final Uint8List yPlane = image.planes[0].bytes;
        int sum = 0;
        int sampleCount = 0;
        for (int i = 0; i < yPlane.length; i += 100) {
          sum += yPlane[i];
          sampleCount++;
        }

        if (sampleCount > 0) {
          double avgBrightness = sum / sampleCount;
          String? warning;
          if (avgBrightness < 40) {
            warning = 'Terlalu Gelap: Cari tempat yang lebih terang';
          } else if (avgBrightness > 220) {
            warning = 'Terlalu Silau: Hindari cahaya matahari langsung';
          }

          if (_brightnessWarning != warning && mounted) {
            setState(() {
              _brightnessWarning = warning;
            });
          }
        }
      }

      // --- Membuat InputImage dengan cara yang benar ---
      // Hanya gunakan plane pertama untuk NV21 (Android) atau BGRA (iOS)
      final Uint8List bytes = image.planes[0].bytes;

      final Size imageSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      final camera = _cameras!.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      final InputImageRotation imageRotation = _getImageRotation(camera);

      final inputImageFormat = InputImageFormatValue.fromRawValue(
        image.format.raw,
      );
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

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: metadata,
      );
      final faces = await _faceDetector.processImage(inputImage);

      if (mounted) {
        if (faces.isEmpty) {
          setState(() {
            _faceDetected = false;
            _debugInfo = 'Wajah belum terdeteksi';
            _facePositionWarning = 'Pastikan wajah terlihat jelas dalam bingkai';
            _confirmationFrames = 0;
          });
        } else {
          final face = faces.first;
          final boundingBox = face.boundingBox;
          final faceWidth = boundingBox.width;
          final faceHeight = boundingBox.height;

          // Validasi ukuran wajah minimal (harus cukup besar di frame)
          final minFaceSize = imageSize.width * 0.15;

          setState(() {
            _faceDetected = true;
          });

          if (faceWidth < minFaceSize || faceHeight < minFaceSize) {
            setState(() {
              _facePositionWarning = 'Dekatkan wajah ke kamera';
              _debugInfo = 'Wajah terlalu kecil (${faceWidth.toInt()}x${faceHeight.toInt()})';
              _confirmationFrames = 0;
            });
          } else {
            setState(() {
              _facePositionWarning = null;
            });

            if (_isRecording) {
              _evaluateLiveness(face);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error ML Kit: $e");
      if (mounted) {
        setState(() {
          _debugInfo = 'Error: ${e.toString().substring(0, e.toString().length.clamp(0, 60))}';
        });
      }
    } finally {
      if (mounted) {
        _isProcessingImage = false;
      }
    }
  }

  void _evaluateLiveness(Face face) {
    if (!_isRecording || _isFaceInstructionSuccess) return;

    bool conditionMet = false;

    if (_livenessStep == 0) {
      // Tengok Kanan / Kiri - threshold diturunkan dari 7 menjadi 25 derajat
      // Tapi kita gunakan threshold bertingkat:
      // > 15 derajat = pasti menoleh
      final double? headY = face.headEulerAngleY;
      if (headY != null) {
        final double absY = headY.abs();
        if (mounted) {
          setState(() {
            _debugInfo = 'Sudut kepala: ${headY.toStringAsFixed(1)} derajat'
                ' (perlu > 15 derajat)';
          });
        }
        if (absY > 15) {
          conditionMet = true;
        }
      } else {
        if (mounted) {
          setState(() {
            _debugInfo = 'headEulerAngleY: null (sensor tidak tersedia)';
          });
        }
      }
    } else if (_livenessStep == 1) {
      // Berkedip - threshold sedikit dilonggarkan
      final double? leftEye = face.leftEyeOpenProbability;
      final double? rightEye = face.rightEyeOpenProbability;
      if (mounted) {
        setState(() {
          _debugInfo = 'Mata L: ${leftEye?.toStringAsFixed(2) ?? "null"}'
              '  R: ${rightEye?.toStringAsFixed(2) ?? "null"}'
              ' (perlu < 0.3)';
        });
      }
      if (leftEye != null && rightEye != null) {
        if (leftEye < 0.3 && rightEye < 0.3) {
          conditionMet = true;
        }
      }
    } else if (_livenessStep == 2) {
      // Senyum
      final double? smile = face.smilingProbability;
      if (mounted) {
        setState(() {
          _debugInfo = 'Senyum: ${smile?.toStringAsFixed(2) ?? "null"}'
              ' (perlu > 0.4)';
        });
      }
      if (smile != null && smile > 0.4) {
        conditionMet = true;
      }
    }

    if (conditionMet) {
      _confirmationFrames++;
      if (_confirmationFrames >= _requiredFrames && !_isFaceInstructionSuccess) {
        setState(() {
          _isFaceInstructionSuccess = true;
          _confirmationFrames = 0;
        });

        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted || !_isRecording) return;

          setState(() {
            _isFaceInstructionSuccess = false;
            _livenessStep++;
            _confirmationFrames = 0;
            _debugInfo = '';
          });

          if (_livenessStep > 2) {
            _cameraController?.stopImageStream();
            _finishVerification();
          }
        });
      }
    } else {
      // Reset counter jika kondisi tidak terpenuhi
      _confirmationFrames = 0;
    }
  }

  Future<void> _finishVerification() async {
    setState(() {
      _isRecording = false;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_verified', true);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AnimatedSuccessDialog(
        message: 'Verifikasi Lapis Ganda Berhasil!',
        isLogout: false,
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    Navigator.pop(context);
    Navigator.pop(context, true);
  }

  String _getFaceInstruction() {
    if (!_isRecording) return 'Posisikan Wajah & Tekan Rekam';

    if (_isFaceInstructionSuccess) return 'Bagus! Tahan sebentar...';

    switch (_livenessStep) {
      case 0:
        return 'Tengok ke Kanan atau Kiri';
      case 1:
        return 'Hadap Depan & Berkedip';
      case 2:
        return 'Hadap Depan & Senyum';
      default:
        return 'Memproses...';
    }
  }

  Color _getOvalColor() {
    if (!_isRecording) return Colors.blueAccent;
    if (_isFaceInstructionSuccess) return Colors.green;
    if (_faceDetected) return Colors.orangeAccent;
    return Colors.red;
  }

  /// Progress bar untuk menunjukkan langkah liveness saat ini
  Widget _buildLivenessProgress() {
    return Positioned(
      bottom: 130,
      left: 40,
      right: 40,
      child: Column(
        children: [
          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final bool isCompleted = index < _livenessStep;
              final bool isCurrent = index == _livenessStep;
              final bool isSuccess = isCurrent && _isFaceInstructionSuccess;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isCurrent ? 40 : 28,
                      height: isCurrent ? 40 : 28,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green
                            : isSuccess
                                ? Colors.green
                                : isCurrent
                                    ? Colors.orangeAccent
                                    : Colors.white.withAlpha(40),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent
                              ? Colors.white
                              : Colors.white.withAlpha(60),
                          width: isCurrent ? 2.5 : 1.5,
                        ),
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_rounded
                            : index == 0
                                ? Icons.rotate_right_rounded
                                : index == 1
                                    ? Icons.remove_red_eye_outlined
                                    : Icons.sentiment_satisfied_alt_rounded,
                        color: Colors.white,
                        size: isCurrent ? 22 : 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      index == 0
                          ? 'Tengok'
                          : index == 1
                              ? 'Kedip'
                              : 'Senyum',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.white60,
                        fontSize: 11,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          // Confirmation progress bar (frame count)
          if (_isRecording && !_isFaceInstructionSuccess && _livenessStep <= 2)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _confirmationFrames / _requiredFrames,
                  minHeight: 4,
                  backgroundColor: Colors.white.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _confirmationFrames > 0 ? Colors.orangeAccent : Colors.white24,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          _currentStep == 0
              ? 'Persiapan'
              : _currentStep == 1
              ? 'Foto KTP'
              : 'Rekam Wajah',
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          if (_cameraError != null)
            Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    _cameraError!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else if (_isCameraInitialized && _cameraController != null)
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: CameraPreview(_cameraController!),
            )
          else
            Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          if (_currentStep == 1)
            Container(
              width: 320,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 3),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Posisikan KTP di dalam bingkai',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ),
              ),
            ),

          if (_currentStep == 2)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 300,
              height: 420,
              decoration: BoxDecoration(
                border: Border.all(color: _getOvalColor(), width: 6),
                borderRadius: const BorderRadius.all(
                  Radius.elliptical(150, 210),
                ),
                boxShadow: _isFaceInstructionSuccess
                    ? [
                        BoxShadow(
                          color: Colors.green.withAlpha(80),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _getFaceInstruction(),
                      key: ValueKey<String>(_getFaceInstruction()),
                      style: TextStyle(
                        color: _isFaceInstructionSuccess
                            ? Colors.greenAccent
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        shadows: const [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),

          // Smart Guidance Banner (Cahaya)
          if (_currentStep == 2 && _brightnessWarning != null)
            Positioned(
              top: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withAlpha(220),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wb_sunny_outlined,
                      color: Colors.black87,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _brightnessWarning!,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Face Position Warning
          if (_currentStep == 2 && _isRecording && _facePositionWarning != null)
            Positioned(
              top: _brightnessWarning != null ? 60 : 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withAlpha(200),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.face_retouching_natural,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _facePositionWarning!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Debug Info Overlay (sensor readings)
          if (_currentStep == 2 && _isRecording && _debugInfo.isNotEmpty)
            Positioned(
              top: _facePositionWarning != null
                  ? (_brightnessWarning != null ? 100 : 60)
                  : (_brightnessWarning != null ? 60 : 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(140),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _debugInfo,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),

          // Liveness Progress indicator
          if (_currentStep == 2 && _isRecording) _buildLivenessProgress(),

          if (_currentStep == 0) Container(color: Colors.black87),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: _currentStep == 0
                      ? _buildInfoChip('Siapkan KTP Asli Anda')
                      : _currentStep == 1
                      ? _buildInfoChip('Pastikan teks pada KTP terbaca jelas')
                      : _currentStep == 2 &&
                            !_isRecording &&
                            _brightnessWarning == null
                      ? _buildInfoChip('Ikuti Instruksi Liveness Saat Merekam')
                      : const SizedBox(),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _currentStep == 0
                      ? _buildPrimaryButton('Mulai Scan KTP', _preparePhotoKTP)
                      : _currentStep == 1
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildPrimaryButton(
                              'Jepret Foto KTP',
                              _takePhotoKTP,
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _pickKTPFromGallery,
                              icon: const Icon(
                                Icons.photo_library,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Unggah dari Galeri',
                                style: TextStyle(
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        )
                      : _currentStep == 2 && !_isRecording
                      ? _buildRecordButton()
                      : const SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _startLivenessDetection,
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withAlpha(100),
              blurRadius: 10,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(Icons.videocam, color: Colors.white, size: 36),
      ),
    );
  }
}
