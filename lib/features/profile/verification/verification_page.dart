import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:siladesbeng_mobile/features/profile/verification/camera_recording_page.dart';
import 'package:siladesbeng_mobile/features/profile/verification/ktp_camera_scanner_page.dart';
import 'package:siladesbeng_mobile/services/kemitraan_service.dart';
import 'package:siladesbeng_mobile/services/kyc_service.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _addressController = TextEditingController();
  final _rtRwController = TextEditingController();
  String? _selectedKecamatan;
  String? _selectedKecamatanId;
  String? _selectedDesa;

  List<dynamic> _kecamatans = [];
  List<dynamic> _desas = [];

  bool _isLoadingRegions = true;
  final KemitraanService _kemitraanService = KemitraanService();
  final KycService _kycService = KycService();

  // State for OCR-first flow
  bool _hasUploadedKtp = false;
  bool _isProcessingOcr = false;
  int? _kycId;
  String? _ktpPath;

  @override
  void initState() {
    super.initState();
    _fetchRegions();
  }

  Future<void> _fetchRegions() async {
    final regions = await _kemitraanService.getRegions();
    if (mounted) {
      setState(() {
        _kecamatans = regions;
        _isLoadingRegions = false;
      });
    }
  }

  Future<void> _scanKtp() async {
    // Open dedicated Shopee/DANA style KTP camera scanner
    final String? imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const KtpCameraScannerPage()),
    );

    if (imagePath != null && mounted) {
      _processKtpImage(imagePath);
    }
  }

  Future<void> _pickKtpFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      _processKtpImage(image.path);
    }
  }

  Future<void> _processKtpImage(String path) async {
    setState(() {
      _isProcessingOcr = true;
      _ktpPath = path;
    });

    final response = await _kycService.processKtp(imagePath: path);

    if (!mounted) return;

    setState(() {
      _isProcessingOcr = false;
    });

    if (response['status'] == 'success') {
      _kycId = response['kyc_id'];
      final ocrData = response['ocr_data'] ?? {};

      setState(() {
        _hasUploadedKtp = true;
        if (ocrData['name'] != null) {
          _nameController.text = ocrData['name'];
        }
        if (ocrData['nik'] != null) {
          _nikController.text = ocrData['nik'];
        }
        if (ocrData['address'] != null) {
          _addressController.text = ocrData['address'];
        }

        String rtRw = '';
        if (ocrData['rt'] != null) {
          rtRw += ocrData['rt'];
        }
        if (ocrData['rw'] != null) {
          rtRw += '/${ocrData['rw']}';
        }
        if (rtRw.isNotEmpty) {
          _rtRwController.text = rtRw;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('e-KTP berhasil dipindai & data terbaca otomatis!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Gagal membaca e-KTP.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _proceedToCamera() {
    if (_nameController.text.isEmpty ||
        _nikController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _selectedKecamatan == null ||
        _selectedDesa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi semua data!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraRecordingPage(
          kycId: _kycId,
          nik: _nikController.text,
          name: _nameController.text,
          address: _addressController.text,
          rtRw: _rtRwController.text,
          kecamatan: _selectedKecamatan,
          desa: _selectedDesa,
        ),
      ),
    ).then((isVerified) {
      if (!mounted) return;
      if (isVerified == true) {
        Navigator.pop(context, true); // Return to profile and reload
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Lengkapi Data Diri',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17.sp,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: const Color(0xFF2563EB),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFF2FA2F1), const Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipRRect(
            child: Stack(
              children: [
                Positioned(
                  top: -30,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(22),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -15,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoadingRegions
          ? const Center(child: CircularProgressIndicator())
          : _isProcessingOcr
          ? _buildLoadingState()
          : !_hasUploadedKtp
          ? _buildUploadState()
          : _buildFormState(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_ktpPath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF2563EB), width: 2),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Image.file(
                  File(_ktpPath!),
                  width: 220,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
          const CircularProgressIndicator(color: Color(0xFF2563EB)),
          SizedBox(height: 18.h),
          Text(
            'Membaca Data e-KTP (OCR)...',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4.h),
          Text(
            'Mengekstrak NIK, Nama, dan Alamat secara otomatis',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF0EA5E9);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.0.w, vertical: 16.0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner / Instruksi Atas
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFBAE6FD),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.document_scanner_rounded,
                    color: primaryColor,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pindai e-KTP Asli',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5.sp,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        'Posisikan e-KTP Anda di dalam bingkai kamera untuk verifikasi data otomatis.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Interactive KTP Scanner Preview Card
          GestureDetector(
            onTap: _scanKtp,
            child: AspectRatio(
              aspectRatio: 1.58,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: isDark ? 0.6 : 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Corner HUD Brackets
                    Positioned(
                      top: 14.h,
                      left: 14.w,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: primaryColor, width: 3),
                            left: BorderSide(color: primaryColor, width: 3),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 14.h,
                      right: 14.w,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: primaryColor, width: 3),
                            right: BorderSide(color: primaryColor, width: 3),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 14.h,
                      left: 14.w,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: primaryColor, width: 3),
                            left: BorderSide(color: primaryColor, width: 3),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 14.h,
                      right: 14.w,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: primaryColor, width: 3),
                            right: BorderSide(color: primaryColor, width: 3),
                          ),
                        ),
                      ),
                    ),

                    // Center Scanner Illustration & Action Hint
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_enhance_rounded,
                              color: primaryColor,
                              size: 38.sp,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Ketuk untuk Membuka Kamera',
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Mendukung deteksi NIK & Nama otomatis',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B),
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

          SizedBox(height: 20.h),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _scanKtp,
              icon: Icon(Icons.camera_alt_rounded, size: 18.sp),
              label: Text(
                'Buka Scanner e-KTP',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
            ),
          ),

          SizedBox(height: 10.h),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _pickKtpFromGallery,
              icon: Icon(
                Icons.photo_library_outlined,
                size: 18.sp,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
              label: Text(
                'Unggah Foto KTP dari Galeri',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5.sp,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
            ),
          ),

          SizedBox(height: 20.h),

          // Tips & Ketentuan Card
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Colors.amber[700],
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Panduan Pemindaian e-KTP:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.sp,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                _buildTipRow('Gunakan e-KTP fisik asli (bukan fotokopi).'),
                SizedBox(height: 6.h),
                _buildTipRow(
                  'Pastikan seluruh bagian KTP masuk ke dalam bingkai.',
                ),
                SizedBox(height: 6.h),
                _buildTipRow(
                  'Pastikan tulisan NIK & Nama jelas serta tidak terkena pantulan cahaya.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(String tip) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          size: 15.sp,
          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            tip,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormState() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.0.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner/Header
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(20),
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: Colors.green.withAlpha(50)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 40.sp),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'KTP Berhasil Dibaca',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Silakan periksa kembali dan lengkapi data yang belum terisi sebelum lanjut verifikasi wajah.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 30.h),

          _buildTextField(
            controller: _nameController,
            labelText: 'Nama Lengkap (Sesuai KTP)',
            icon: Icons.person_outline,
          ),

          _buildTextField(
            controller: _nikController,
            labelText: 'NIK KTP (16 Digit)',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
          ),

          // Kecamatan Dropdown
          Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedKecamatanId,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              decoration: InputDecoration(
                hintText: 'Pilih Kecamatan',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: Icon(
                  Icons.map_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.r),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.r),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                  ),
                ),
              ),
              items: _kecamatans.map((kec) {
                return DropdownMenuItem<String>(
                  value: kec['id'].toString(),
                  child: Text(kec['name']),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedKecamatanId = val;
                  final selectedKec = _kecamatans.firstWhere(
                    (k) => k['id'].toString() == val,
                  );
                  _selectedKecamatan = selectedKec['name'];
                  _selectedDesa = null;
                  _desas = selectedKec['children'] ?? [];
                });
              },
            ),
          ),

          // Desa Dropdown
          Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _selectedDesa,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              decoration: InputDecoration(
                hintText: 'Pilih Desa / Kelurahan',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: Icon(
                  Icons.location_city_outlined,
                  color: Theme.of(context).iconTheme.color,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.r),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.r),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                  ),
                ),
              ),
              items: _desas.map((desa) {
                return DropdownMenuItem<String>(
                  value: desa['name'].toString(),
                  child: Text(desa['name']),
                );
              }).toList(),
              onChanged: _desas.isEmpty
                  ? null
                  : (val) {
                      setState(() {
                        _selectedDesa = val;
                      });
                    },
            ),
          ),

          _buildTextField(
            controller: _rtRwController,
            labelText: 'RT / RW (Contoh: 001/002)',
            icon: Icons.map_outlined,
          ),

          _buildTextField(
            controller: _addressController,
            labelText: 'Alamat Lengkap (Jalan, No. Rumah)',
            icon: Icons.home_outlined,
          ),

          SizedBox(height: 30.h),
          ElevatedButton.icon(
            onPressed: _proceedToCamera,
            icon: const Icon(Icons.face),
            label: const Text(
              'Lanjut Verifikasi Wajah',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.r),
              ),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          hintText: labelText,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Theme.of(context).iconTheme.color),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.r),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.r),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            vertical: 16.h,
            horizontal: 20.w,
          ),
        ),
      ),
    );
  }
}
