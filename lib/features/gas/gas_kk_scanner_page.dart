import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class GasKKScannerPage extends StatefulWidget {
  const GasKKScannerPage({super.key});

  @override
  State<GasKKScannerPage> createState() => _GasKKScannerPageState();
}

class _GasKKScannerPageState extends State<GasKKScannerPage> {
  int _step = 0; // 0: Upload & Panduan, 1: Loading OCR, 2: Form Koreksi
  String? _imagePath;

  // OCR Results (Mock / AI Extracted)
  final TextEditingController _noKkController = TextEditingController(
    text: '1408012345678900',
  );

  final List<Map<String, dynamic>> _familyMembers = [
    {
      'role': 'Kepala Keluarga (Suami)',
      'controller': TextEditingController(text: '1408010101900001'),
    },
    {
      'role': 'Istri',
      'controller': TextEditingController(text: '1408010202920002'),
    },
    {
      'role': 'Anak',
      'controller': TextEditingController(text: '1408010303120003'),
    },
  ];

  bool _isBlocked = false;
  String _blockReason = '';

  @override
  void dispose() {
    _noKkController.dispose();
    for (final member in _familyMembers) {
      (member['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 90, // Kualitas tinggi agar NIK terbaca tajam
    );

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
        _step = 1;
      });
      _simulateOCR();
    }
  }

  Future<void> _simulateOCR() async {
    // Simulasi waktu proses OCR AI membaca KK
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      _step = 2;
    });
  }

  void _addFamilyMember() {
    setState(() {
      _familyMembers.add({
        'role': 'Anggota Keluarga ${_familyMembers.length + 1}',
        'controller': TextEditingController(),
      });
    });
  }

  void _removeFamilyMember(int index) {
    if (_familyMembers.length > 1) {
      setState(() {
        _familyMembers[index]['controller'].dispose();
        _familyMembers.removeAt(index);
      });
    }
  }

  void _submitData() {
    final String cleanKk = _noKkController.text.trim();

    if (cleanKk.length < 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nomor Kartu Keluarga (KK) harus 16 digit.'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Simulasi proteksi kuota subsidi mingguan:
    // Jika No KK tertentu sudah tercatat transaksi di minggu berjalan
    if (cleanKk == '1408012345678900') {
      setState(() {
        _isBlocked = true;
        _blockReason =
            'Berdasarkan data No. KK $cleanKk, jatah kuota gas subsidi untuk keluarga Anda sudah terpakai pada minggu ini. Silakan melakukan pemesanan kembali minggu depan.';
      });
    } else {
      // Validasi berhasil
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Kartu Keluarga berhasil diverifikasi!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Verifikasi Kartu Keluarga',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 17,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildCurrentStep(),
    );
  }

  Widget _buildCurrentStep() {
    if (_isBlocked) return _buildBlockedScreen();
    if (_step == 0) return _buildUploadAndGuideStep();
    if (_step == 1) return _buildLoadingOcrStep();
    return _buildCorrectorStep();
  }

  // ═══════════════════════════════════════════════════════════════════
  // STEP 0: PANDUAN SCAN KK & UPLOAD
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildUploadAndGuideStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
      children: [
        // 1. Emergency Crisis Alert Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF7C2D12).withValues(alpha: 0.4),
                      const Color(0xFF451A03).withValues(alpha: 0.6),
                    ]
                  : [const Color(0xFFFFF7ED), const Color(0xFFFFEDD5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFFEA580C) : const Color(0xFFFDBA74),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFEA580C),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distribusi Masa Kelangkaan Gas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: isDark
                            ? const Color(0xFFFDBA74)
                            : const Color(0xFF9A3412),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Scan Kartu Keluarga (KK) diperlukan untuk memastikan setiap rumah tangga mendapatkan kuota subsidi secara adil dan merata.',
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF7C2D12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 2. Interactive Document Framing Mockup
        Container(
          height: 190,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131C2E) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Simulated Document Grid
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header simulated KK
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'KARTU KELUARGA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: primaryColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'No. KK: 350711xxxxxxxx',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 12),
                        // Table mockup lines
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 6,
                              color: isDark ? Colors.white24 : Colors.grey[300],
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 80,
                              height: 6,
                              color: primaryColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 40,
                              height: 6,
                              color: isDark ? Colors.white24 : Colors.grey[300],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 45,
                              height: 6,
                              color: isDark ? Colors.white24 : Colors.grey[300],
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 85,
                              height: 6,
                              color: primaryColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 35,
                              height: 6,
                              color: isDark ? Colors.white24 : Colors.grey[300],
                            ),
                          ],
                        ),
                        const Spacer(),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.center_focus_strong_rounded,
                                  size: 14,
                                  color: Color(0xFF10B981),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Area Fokus Scan No. KK & NIK',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Targeting Corner Brackets
              Positioned(
                top: 14,
                left: 14,
                child: _buildCornerBracket(
                  primaryColor,
                  isTop: true,
                  isLeft: true,
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: _buildCornerBracket(
                  primaryColor,
                  isTop: true,
                  isLeft: false,
                ),
              ),
              Positioned(
                bottom: 14,
                left: 14,
                child: _buildCornerBracket(
                  primaryColor,
                  isTop: false,
                  isLeft: true,
                ),
              ),
              Positioned(
                bottom: 14,
                right: 14,
                child: _buildCornerBracket(
                  primaryColor,
                  isTop: false,
                  isLeft: false,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 3. Checklist Panduan Foto Berkualitas
        Text(
          'Petunjuk Agar NIK & No. KK Terbaca Tajam:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),

        _buildGuideItem(
          icon: Icons.wb_sunny_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: 'Pencahayaan Terang',
          subtitle:
              'Hindari pantulan silau lampu dan bayangan tangan pada teks.',
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildGuideItem(
          icon: Icons.table_restaurant_rounded,
          iconColor: const Color(0xFF3B82F6),
          title: 'Posisikan Datar & Rata',
          subtitle: 'Letakkan lembar KK di atas meja datar berlatar kontras.',
          isDark: isDark,
        ),
        const SizedBox(height: 8),
        _buildGuideItem(
          icon: Icons.document_scanner_rounded,
          iconColor: const Color(0xFF10B981),
          title: 'Fokuskan Tabel NIK',
          subtitle:
              'Pastikan baris nomor KK & NIK anggota keluarga tidak goyang/buram.',
          isDark: isDark,
        ),

        const SizedBox(height: 26),

        // 4. CTA Buttons (Ergonomic & Thumb-Friendly)
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_rounded, size: 20),
            label: const Text(
              'Buka Kamera Pemindai KK',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: primaryColor.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: Icon(
              Icons.photo_library_rounded,
              size: 20,
              color: primaryColor,
            ),
            label: Text(
              'Pilih Foto dari Galeri',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: primaryColor, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerBracket(
    Color color, {
    required bool isTop,
    required bool isLeft,
  }) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? BorderSide(color: color, width: 3) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: color, width: 3) : BorderSide.none,
          left: isLeft ? BorderSide(color: color, width: 3) : BorderSide.none,
          right: !isLeft ? BorderSide(color: color, width: 3) : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildGuideItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // STEP 1: AI OCR SCANNING ANIMATION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildLoadingOcrStep() {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(
                  width: 65,
                  height: 65,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: primaryColor,
                  ),
                ),
                Icon(
                  Icons.document_scanner_rounded,
                  size: 30,
                  color: primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 26),
            Text(
              'AI Sedang Membaca Dokumen KK...',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Mengekstrak Nomor KK & NIK seluruh anggota keluarga secara otomatis.',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // STEP 2: VERIFIKASI & FORM KOREKSI HASIL OCR
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildCorrectorStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
      children: [
        // Helper Note Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(
              0xFF3B82F6,
            ).withValues(alpha: isDark ? 0.18 : 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI telah mengekstrak data dari foto KK Anda. Silakan periksa kembali dan perbaiki angka jika ada pembacaan yang keliru.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF1E3A8A),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Photo Preview Thumbnail (Compact & Retake Button)
        if (_imagePath != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C2E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(_imagePath!),
                    width: 70,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Foto Kartu Keluarga',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dokumen terlampir',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _step = 0),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text(
                    'Foto Ulang',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 20),

        // Nomor Kartu Keluarga Field
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nomor Kartu Keluarga (KK)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '16 Digit',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131C2E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),
          child: TextField(
            controller: _noKkController,
            keyboardType: TextInputType.number,
            maxLength: 16,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
              letterSpacing: 1.0,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.badge_rounded,
                color: primaryColor,
                size: 20,
              ),
              counterText: '',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ),

        const SizedBox(height: 22),

        // Anggota Keluarga Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'NIK Anggota Keluarga (${_familyMembers.length})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            TextButton.icon(
              onPressed: _addFamilyMember,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
              label: const Text('+ Tambah NIK', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        ..._familyMembers.asMap().entries.map((entry) {
          final int index = entry.key;
          final Map<String, dynamic> member = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C2E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 18,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member['role'] ?? 'Anggota ${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      TextField(
                        controller: member['controller'],
                        keyboardType: TextInputType.number,
                        maxLength: 16,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Masukkan 16 digit NIK...',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                          ),
                          counterText: '',
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_familyMembers.length > 1)
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.red.shade400,
                    ),
                    onPressed: () => _removeFamilyMember(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          );
        }),

        const SizedBox(height: 24),

        // Submit Button
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _submitData,
            icon: const Icon(Icons.verified_rounded, size: 20),
            label: const Text(
              'Simpan & Lanjutkan Pemesanan',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: const Color(0xFF10B981).withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // BLOCKED / QUOTA EXCEEDED SCREEN
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildBlockedScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: isDark ? 0.25 : 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.block_rounded,
                size: 56,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Batas Kuota Subsidi Tercapai',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF131C2E)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFFECACA),
                ),
              ),
              child: Text(
                _blockReason,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF991B1B),
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Kembali ke Halaman Gas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
