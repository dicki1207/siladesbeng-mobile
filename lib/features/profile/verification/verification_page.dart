import 'dart:io';
import 'package:flutter/material.dart';
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
        if (ocrData['name'] != null) _nameController.text = ocrData['name'];
        if (ocrData['nik'] != null) _nikController.text = ocrData['nik'];
        if (ocrData['address'] != null) _addressController.text = ocrData['address'];

        String rtRw = '';
        if (ocrData['rt'] != null) rtRw += ocrData['rt'];
        if (ocrData['rw'] != null) rtRw += '/${ocrData['rw']}';
        if (rtRw.isNotEmpty) _rtRwController.text = rtRw;
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Lengkapi Data Diri (e-KYC)'),
        centerTitle: true,
        elevation: 0,
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
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF2563EB), width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.file(
                  File(_ktpPath!),
                  width: 220,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          const CircularProgressIndicator(color: Color(0xFF2563EB)),
          const SizedBox(height: 18),
          const Text(
            'Membaca Data e-KTP (OCR)...',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mengekstrak NIK, Nama, dan Alamat secara otomatis',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF0EA5E9);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner / Instruksi Atas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFBAE6FD),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.document_scanner_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pindai e-KTP Asli',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Posisikan e-KTP Anda di dalam bingkai kamera untuk verifikasi data otomatis.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Interactive KTP Scanner Preview Card
          GestureDetector(
            onTap: _scanKtp,
            child: AspectRatio(
              aspectRatio: 1.58,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: isDark ? 0.6 : 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Corner HUD Brackets
                    Positioned(
                      top: 14,
                      left: 14,
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
                      top: 14,
                      right: 14,
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
                      bottom: 14,
                      left: 14,
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
                      bottom: 14,
                      right: 14,
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
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_enhance_rounded,
                              color: primaryColor,
                              size: 38,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Ketuk untuk Membuka Kamera',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mendukung deteksi NIK & Nama otomatis',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
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

          const SizedBox(height: 20),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _scanKtp,
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: const Text(
                'Buka Scanner e-KTP',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _pickKtpFromGallery,
              icon: Icon(
                Icons.photo_library_outlined,
                size: 18,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
              label: Text(
                'Unggah Foto KTP dari Galeri',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tips & Ketentuan Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
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
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Panduan Pemindaian e-KTP:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTipRow('Gunakan e-KTP fisik asli (bukan fotokopi).'),
                const SizedBox(height: 6),
                _buildTipRow('Pastikan seluruh bagian KTP masuk ke dalam bingkai.'),
                const SizedBox(height: 6),
                _buildTipRow('Pastikan tulisan NIK & Nama jelas serta tidak terkena pantulan cahaya.'),
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
          size: 15,
          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            tip,
            style: TextStyle(
              fontSize: 12,
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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner/Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(20),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.green.withAlpha(50)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 40,
                ),
                const SizedBox(width: 16),
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
                      const SizedBox(height: 4),
                      Text(
                        'Silakan periksa kembali dan lengkapi data yang belum terisi sebelum lanjut verifikasi wajah.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

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
            padding: const EdgeInsets.only(bottom: 16),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedKecamatanId,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              decoration: InputDecoration(
                hintText: 'Pilih Kecamatan',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.map_outlined, color: Theme.of(context).iconTheme.color),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
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
                  final selectedKec = _kecamatans.firstWhere((k) => k['id'].toString() == val);
                  _selectedKecamatan = selectedKec['name'];
                  _selectedDesa = null;
                  _desas = selectedKec['children'] ?? [];
                });
              },
            ),
          ),

          // Desa Dropdown
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedDesa,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              decoration: InputDecoration(
                hintText: 'Pilih Desa / Kelurahan',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.location_city_outlined, color: Theme.of(context).iconTheme.color),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
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
              onChanged: _desas.isEmpty ? null : (val) {
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

          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _proceedToCamera,
            icon: const Icon(Icons.face),
            label: const Text(
              'Lanjut Verifikasi Wajah',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
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
      padding: const EdgeInsets.only(bottom: 16),
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
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
        ),
      ),
    );
  }
}
