import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

class KtpCameraScannerPage extends StatefulWidget {
 const KtpCameraScannerPage({super.key});

 @override
 State<KtpCameraScannerPage> createState() => _KtpCameraScannerPageState();
}

class _KtpCameraScannerPageState extends State<KtpCameraScannerPage>
  with TickerProviderStateMixin, WidgetsBindingObserver {
 CameraController? _cameraController;
 List<CameraDescription>? _cameras;
 bool _isCameraInitialized = false;
 String? _errorMessage;
 FlashMode _flashMode = FlashMode.off;
 bool _isCapturing = false;

 // Animation controllers for scan laser and pulse effects
 late AnimationController _laserAnimController;
 late Animation<double> _laserAnimation;

 @override
 void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _initAnimations();
  _initializeCamera();
 }

 void _initAnimations() {
  _laserAnimController = AnimationController(
   vsync: this,
   duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);

  _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
   CurvedAnimation(parent: _laserAnimController, curve: Curves.easeInOut),
  );
 }

 @override
 void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  _laserAnimController.dispose();
  _cameraController?.dispose();
  super.dispose();
 }

 @override
 void didChangeAppLifecycleState(AppLifecycleState state) {
  if (_cameraController == null || !_cameraController!.value.isInitialized) {
   return;
  }
  if (state == AppLifecycleState.inactive) {
   _cameraController?.dispose();
  } else if (state == AppLifecycleState.resumed) {
   _initializeCamera();
  }
 }

 Future<void> _initializeCamera() async {
  try {
   _cameras = await availableCameras();
   if (_cameras == null || _cameras!.isEmpty) {
    setState(() {
     _errorMessage = 'Kamera tidak ditemukan pada perangkat ini.';
    });
    return;
   }

   // Default to back camera for KTP scanning
   CameraDescription selectedCamera = _cameras!.firstWhere(
    (cam) => cam.lensDirection == CameraLensDirection.back,
    orElse: () => _cameras!.first,
   );

   await _cameraController?.dispose();

   _cameraController = CameraController(
    selectedCamera,
    ResolutionPreset.high,
    enableAudio: false,
    imageFormatGroup: Platform.isAndroid
      ? ImageFormatGroup.nv21
      : ImageFormatGroup.bgra8888,
   );

   await _cameraController!.initialize();
   await _cameraController!.setFlashMode(_flashMode);

   if (mounted) {
    setState(() {
     _isCameraInitialized = true;
     _errorMessage = null;
    });
   }
  } catch (e) {
   if (mounted) {
    setState(() {
     _errorMessage = 'Gagal mengakses kamera: $e';
    });
   }
  }
 }

 Future<void> _toggleFlash() async {
  if (_cameraController == null || !_cameraController!.value.isInitialized) return;

  FlashMode nextMode;
  switch (_flashMode) {
   case FlashMode.off:
    nextMode = FlashMode.torch;
    break;
   case FlashMode.torch:
    nextMode = FlashMode.auto;
    break;
   case FlashMode.auto:
   default:
    nextMode = FlashMode.off;
    break;
  }

  try {
   await _cameraController!.setFlashMode(nextMode);
   setState(() => _flashMode = nextMode);
   HapticFeedback.selectionClick();
  } catch (e) {
   debugPrint('Error setting flash mode: $e');
  }
 }

 IconData _getFlashIcon() {
  switch (_flashMode) {
   case FlashMode.torch:
    return Icons.flash_on_rounded;
   case FlashMode.auto:
    return Icons.flash_auto_rounded;
   case FlashMode.off:
   default:
    return Icons.flash_off_rounded;
  }
 }

 String _getFlashLabel() {
  switch (_flashMode) {
   case FlashMode.torch:
    return 'Flash ON';
   case FlashMode.auto:
    return 'Flash AUTO';
   case FlashMode.off:
   default:
    return 'Flash OFF';
  }
 }

 Future<void> _captureKtp() async {
  if (_cameraController == null ||
    !_cameraController!.value.isInitialized ||
    _isCapturing) {
   return;
  }

  setState(() => _isCapturing = true);
  HapticFeedback.mediumImpact();

  try {
   final XFile photo = await _cameraController!.takePicture();
   if (!mounted) return;

   // Show high quality preview sheet before returning
   final bool? isConfirmed = await _showPreviewDialog(photo.path);
   if (isConfirmed == true && mounted) {
    Navigator.pop(context, photo.path);
   }
  } catch (e) {
   debugPrint('Error capturing photo: $e');
   if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
      content: Text('Gagal mengambil foto: $e'),
      backgroundColor: Colors.redAccent,
     ),
    );
   }
  } finally {
   if (mounted) {
    setState(() => _isCapturing = false);
   }
  }
 }

 Future<bool?> _showPreviewDialog(String imagePath) {
  return showModalBottomSheet<bool>(
   context: context,
   isScrollControlled: true,
   backgroundColor: const Color(0xFF0F172A),
   shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
   ),
   builder: (context) {
    return SafeArea(
     child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
       mainAxisSize: MainAxisSize.min,
       children: [
        // Top handle
        Container(
         width: 44,
         height: 4,
         decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2.r),
         ),
        ),
        SizedBox(height: 16.h),

        Row(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
          Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 20.sp),
          SizedBox(width: 8.w),
          Text(
           'Pratinjau Foto e-KTP 📸',
           style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
           ),
          ),
         ],
        ),
        SizedBox(height: 6.h),
        Text(
         '💡 Pastikan NIK & seluruh teks KTP terbaca jelas dan tidak silau.',
         textAlign: TextAlign.center,
         style: TextStyle(color: Colors.white60, fontSize: 12.sp),
        ),
        SizedBox(height: 18.h),

        // KTP Image Card with Aspect Ratio
        AspectRatio(
         aspectRatio: 1.58,
         child: Container(
          decoration: BoxDecoration(
           borderRadius: BorderRadius.circular(16.r),
           border: Border.all(color: const Color(0xFF2563EB), width: 2),
           boxShadow: [
            BoxShadow(
             color: const Color(0xFF2563EB).withAlpha(50),
             blurRadius: 12,
            ),
           ],
          ),
          child: ClipRRect(
           borderRadius: BorderRadius.circular(14.r),
           child: Image.file(
            File(imagePath),
            fit: BoxFit.cover,
           ),
          ),
         ),
        ),

        SizedBox(height: 24.h),

        // Action buttons
        Row(
         children: [
          // Retake
          Expanded(
           child: OutlinedButton.icon(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            label: const Text('Foto Ulang', style: TextStyle(color: Colors.white70)),
            style: OutlinedButton.styleFrom(
             padding: EdgeInsets.symmetric(vertical: 14.h),
             side: const BorderSide(color: Colors.white24),
             shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
             ),
            ),
            onPressed: () => Navigator.pop(context, false),
           ),
          ),
          SizedBox(width: 14.w),

          // Use Photo
          Expanded(
           child: ElevatedButton.icon(
            icon: const Icon(Icons.check_rounded, color: Colors.white),
            label: const Text(
             'Gunakan KTP',
             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
             padding: EdgeInsets.symmetric(vertical: 14.h),
             backgroundColor: const Color(0xFF2563EB),
             shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
             ),
             elevation: 4,
            ),
            onPressed: () => Navigator.pop(context, true),
           ),
          ),
         ],
        ),
       ],
      ),
     ),
    );
   },
  );
 }

 @override
 Widget build(BuildContext context) {
  final size = MediaQuery.of(context).size;
  // Standard ID-1 card (KTP) is 85.60 mm × 53.98 mm -> aspect ratio ~ 1.58 : 1
  final double cardWidth = size.width * 0.88;
  final double cardHeight = cardWidth / 1.58;

  return Scaffold(
   backgroundColor: Colors.black,
   body: Stack(
    fit: StackFit.expand,
    children: [
     // ── 1. CAMERA PREVIEW ──
     if (_errorMessage != null)
      Center(
       child: Padding(
        padding: EdgeInsets.all(24.0.w),
        child: Text(
         _errorMessage!,
         style: TextStyle(color: Colors.redAccent),
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

     // ── 2. SHOPEE / DANA STYLE KTP BOX MASK CUTOUT ──
     if (_isCameraInitialized && _cameraController != null)
      AnimatedBuilder(
       animation: _laserAnimation,
       builder: (context, _) {
        return CustomPaint(
         size: Size(size.width, size.height),
         painter: KtpBoxMaskPainter(
          boxWidth: cardWidth,
          boxHeight: cardHeight,
          laserProgress: _laserAnimation.value,
         ),
        );
       },
      ),

     // ── 3. TOP APP BAR & FLASH TOGGLE ──
     SafeArea(
      child: Column(
       children: [
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
              Icon(Icons.badge_rounded, color: Color(0xFF60A5FA), size: 16.sp),
              SizedBox(width: 6.w),
              Text(
               'Pindai e-KTP Asli 🪪',
               style: TextStyle(
                color: Colors.white,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.bold,
               ),
              ),
             ],
            ),
           ),
           // Flash Toggle
           IconButton(
            icon: Container(
             padding: EdgeInsets.all(8.w),
             decoration: BoxDecoration(
              color: _flashMode != FlashMode.off
                ? const Color(0xFF2563EB)
                : Colors.black.withAlpha(120),
              shape: BoxShape.circle,
              border: Border.all(
               color: _flashMode != FlashMode.off
                 ? const Color(0xFF60A5FA)
                 : Colors.white24,
              ),
             ),
             child: Icon(
              _getFlashIcon(),
              color: Colors.white,
              size: 18.sp,
             ),
            ),
            tooltip: _getFlashLabel(),
            onPressed: _toggleFlash,
           ),
          ],
         ),
        ),

        // Top Instruction Pill
        Padding(
         padding: EdgeInsets.only(top: 12.h),
         child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
           color: const Color(0xFF0F172A).withAlpha(220),
           borderRadius: BorderRadius.circular(20.r),
           border: Border.all(color: const Color(0xFF2563EB).withAlpha(100)),
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
            Icon(Icons.crop_free_rounded, color: Color(0xFF60A5FA), size: 16.sp),
            SizedBox(width: 8.w),
            Text(
             'Posisikan e-KTP tepat di dalam bingkai kotak 🟦',
             style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
             ),
            ),
           ],
          ),
         ),
        ),
       ],
      ),
     ),

     // ── 4. BOTTOM CONTROLS & SHUTTER BUTTON ──
     Positioned(
      bottom: 36.h,
      left: 20.w,
      right: 20.w,
      child: Column(
       mainAxisSize: MainAxisSize.min,
       children: [
        // Guidance Subtitle
        Container(
         padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
         decoration: BoxDecoration(
          color: Colors.black.withAlpha(140),
          borderRadius: BorderRadius.circular(14.r),
         ),
         child: Text(
          '💡 Pastikan tulisan NIK & Nama jelas, tidak terpotong atau silau pantulan cahaya',
          textAlign: TextAlign.center,
          style: TextStyle(
           color: Colors.white70,
           fontSize: 11.5.sp,
           fontWeight: FontWeight.w500,
          ),
         ),
        ),

        SizedBox(height: 20.h),

        // Shutter Camera Button
        GestureDetector(
         onTap: _captureKtp,
         child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
           shape: BoxShape.circle,
           border: Border.all(color: Colors.white, width: 4),
           color: _isCapturing
             ? const Color(0xFF10B981)
             : const Color(0xFF2563EB),
           boxShadow: [
            BoxShadow(
             color: const Color(0xFF2563EB).withAlpha(120),
             blurRadius: 16,
             spreadRadius: 3,
            ),
           ],
          ),
          child: _isCapturing
            ? const Center(
              child: SizedBox(
               width: 28,
               height: 28,
               child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
               ),
              ),
             )
            : Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 36.sp,
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

// ═══════════════════════════════════════════════════════════════════════════
// SHOPEE / DANA / TOKOPEDIA STYLE KTP BOX MASK CUSTOM PAINTER
// ═══════════════════════════════════════════════════════════════════════════
class KtpBoxMaskPainter extends CustomPainter {
 final double boxWidth;
 final double boxHeight;
 final double laserProgress; // 0.0 to 1.0

 KtpBoxMaskPainter({
  required this.boxWidth,
  required this.boxHeight,
  required this.laserProgress,
 });

 @override
 void paint(Canvas canvas, Size size) {
  final Rect fullScreenRect = Offset.zero & size;
  final Offset center = Offset(size.width / 2, size.height * 0.44);

  final RRect ktpRRect = RRect.fromRectAndRadius(
   Rect.fromCenter(center: center, width: boxWidth, height: boxHeight),
   Radius.circular(16.r),
  );

  // ── 1. DARK BACKGROUND WITH TRANSPARENT KTP BOX CUTOUT ──
  final Path backgroundPath = Path()..addRect(fullScreenRect);
  final Path boxPath = Path()..addRRect(ktpRRect);
  final Path maskPath = Path.combine(PathOperation.difference, backgroundPath, boxPath);

  final Paint maskPaint = Paint()..color = const Color(0xE6050B14);
  canvas.drawPath(maskPath, maskPaint);

  // ── 2. BOX BASE BORDER ──
  final Paint borderPaint = Paint()
   ..color = const Color(0xFF2563EB).withAlpha(100)
   ..style = PaintingStyle.stroke
   ..strokeWidth = 2.0;
  canvas.drawRRect(ktpRRect, borderPaint);

  // ── 3. GLOWING CORNER BRACKETS ──
  _drawCornerBrackets(canvas, ktpRRect.outerRect, const Color(0xFF60A5FA));

  // ── 4. KTP INNER GUIDELINE HINTS (PHOTO & NIK AREA) ──
  _drawKtpInnerGuides(canvas, ktpRRect.outerRect);

  // ── 5. ANIMATED LASER SCANNING LINE ──
  final double laserY = ktpRRect.top + (ktpRRect.height * laserProgress);
  final Paint laserPaint = Paint()
   ..shader = LinearGradient(
    colors: [
     Colors.transparent,
     const Color(0xFF60A5FA).withAlpha(220),
     Colors.transparent,
    ],
   ).createShader(Rect.fromLTWH(ktpRRect.left, laserY - 1, ktpRRect.width, 2))
   ..strokeWidth = 2.5;

  canvas.drawLine(
   Offset(ktpRRect.left + 8, laserY),
   Offset(ktpRRect.right - 8, laserY),
   laserPaint,
  );
 }

 void _drawCornerBrackets(Canvas canvas, Rect rect, Color color) {
  final Paint bracketPaint = Paint()
   ..color = color
   ..style = PaintingStyle.stroke
   ..strokeCap = StrokeCap.round
   ..strokeWidth = 4.0;

  const double len = 24.0;
  const double offset = 2.0;

  final double l = rect.left - offset;
  final double r = rect.right + offset;
  final double t = rect.top - offset;
  final double b = rect.bottom + offset;

  // Top-Left
  canvas.drawLine(Offset(l, t + len), Offset(l, t), bracketPaint);
  canvas.drawLine(Offset(l, t), Offset(l + len, t), bracketPaint);

  // Top-Right
  canvas.drawLine(Offset(r - len, t), Offset(r, t), bracketPaint);
  canvas.drawLine(Offset(r, t), Offset(r, t + len), bracketPaint);

  // Bottom-Left
  canvas.drawLine(Offset(l, b - len), Offset(l, b), bracketPaint);
  canvas.drawLine(Offset(l, b), Offset(l + len, b), bracketPaint);

  // Bottom-Right
  canvas.drawLine(Offset(r - len, b), Offset(r, b), bracketPaint);
  canvas.drawLine(Offset(r, b), Offset(r, b - len), bracketPaint);
 }

 void _drawKtpInnerGuides(Canvas canvas, Rect rect) {
  final Paint guidePaint = Paint()
   ..color = Colors.white.withAlpha(35)
   ..style = PaintingStyle.stroke
   ..strokeWidth = 1.0;

  // Photo frame guideline on right side of KTP
  final double photoWidth = rect.width * 0.26;
  final double photoHeight = rect.height * 0.58;
  final Rect photoRect = Rect.fromLTWH(
   rect.right - photoWidth - (rect.width * 0.06),
   rect.top + (rect.height * 0.28),
   photoWidth,
   photoHeight,
  );

  canvas.drawRRect(
   RRect.fromRectAndRadius(photoRect, Radius.circular(8.r)),
   guidePaint,
  );

  // Small user icon placeholder inside photo frame
  final TextPainter tp = TextPainter(
   text: TextSpan(
    text: String.fromCharCode(Icons.person_outline_rounded.codePoint),
    style: TextStyle(
     fontSize: 20.sp,
     fontFamily: Icons.person_outline_rounded.fontFamily,
     package: Icons.person_outline_rounded.fontPackage,
     color: Colors.white.withAlpha(40),
    ),
   ),
   textDirection: TextDirection.ltr,
  )..layout();

  tp.paint(
   canvas,
   Offset(
    photoRect.center.dx - (tp.width / 2),
    photoRect.center.dy - (tp.height / 2),
   ),
  );
 }

 @override
 bool shouldRepaint(covariant KtpBoxMaskPainter oldDelegate) {
  return oldDelegate.laserProgress != laserProgress ||
    oldDelegate.boxWidth != boxWidth ||
    oldDelegate.boxHeight != boxHeight;
 }
}
