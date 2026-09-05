import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:siladesbeng_mobile/features/profile/verification/ktp_camera_scanner_page.dart';
import 'package:siladesbeng_mobile/services/kemitraan_service.dart';
import 'package:siladesbeng_mobile/services/kyc_service.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';

class PartnershipRegistrationPage extends StatefulWidget {
  const PartnershipRegistrationPage({super.key});

  @override
  State<PartnershipRegistrationPage> createState() =>
      _PartnershipRegistrationPageState();
}

class _PartnershipRegistrationPageState
    extends State<PartnershipRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final KemitraanService _kemitraanService = KemitraanService();
  final KycService _kycService = KycService();

  bool _isSubmitting = false;
  bool _isLoadingRegions = true;
  bool _isScanningKtp = false;

  final _namaPendaftarController = TextEditingController();
  final _nikController = TextEditingController();
  final _jabatanController = TextEditingController(
    text: 'Kepala Desa / Direktur BUMDes',
  );
  final _noHpController = TextEditingController();
  final _emailController = TextEditingController();
  final _pesanController = TextEditingController();

  List<dynamic> _kecamatans = [];
  String? _selectedKecamatanId;
  List<dynamic> _desas = [];
  String? _selectedDesaId;
  Map<String, dynamic>? _selectedDesaData;

  String? _filePath;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _isLoadingRegions = true;
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

  void _onKecamatanChanged(String? kecamatanId) {
    setState(() {
      _selectedKecamatanId = kecamatanId;
      _selectedDesaId = null;
      _selectedDesaData = null;

      if (kecamatanId != null) {
        final kec = _kecamatans.firstWhere(
          (item) => item['id'].toString() == kecamatanId,
          orElse: () => null,
        );
        _desas = kec != null ? (kec['children'] ?? []) : [];
      } else {
        _desas = [];
      }
    });
  }

  void _onDesaChanged(String? desaId) {
    if (desaId == null) {
      setState(() {
        _selectedDesaId = null;
        _selectedDesaData = null;
      });
      return;
    }

    final desa = _desas.firstWhere(
      (item) => item['id'].toString() == desaId,
      orElse: () => null,
    );

    setState(() {
      _selectedDesaId = desaId;
      _selectedDesaData = desa;
    });
  }

  Future<void> _scanKtpForAutofill() async {
    final String? imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const KtpCameraScannerPage()),
    );

    if (imagePath == null) return;

    setState(() => _isScanningKtp = true);

    try {
      final res = await _kycService.processKtp(imagePath: imagePath);
      if (!mounted) return;
      setState(() => _isScanningKtp = false);

      if (res['status'] == 'success' && res['ocr_data'] != null) {
        final ocr = res['ocr_data'];
        final String? ocrName = ocr['nama'];
        final String? ocrNik = ocr['nik'];
        final String? ocrKec = ocr['kecamatan'];
        final String? ocrDesa = ocr['kelurahan_desa'];

        if (ocrName != null && ocrName.isNotEmpty) {
          _namaPendaftarController.text = ocrName;
        }
        if (ocrNik != null && ocrNik.isNotEmpty) {
          _nikController.text = ocrNik;
        }

        // Try to match Kecamatan and Desa
        if (ocrKec != null && _kecamatans.isNotEmpty) {
          final matchedKec = _kecamatans.firstWhere(
            (k) =>
                k['name'].toString().toLowerCase().contains(ocrKec.toLowerCase()),
            orElse: () => null,
          );
          if (matchedKec != null) {
            _onKecamatanChanged(matchedKec['id'].toString());

            if (ocrDesa != null && _desas.isNotEmpty) {
              final matchedDesa = _desas.firstWhere(
                (d) =>
                    d['name'].toString().toLowerCase().contains(ocrDesa.toLowerCase()),
                orElse: () => null,
              );
              if (matchedDesa != null) {
                _onDesaChanged(matchedDesa['id'].toString());
              }
            }
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data KTP berhasil dipindai & diisi otomatis!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showError('Gagal memproses KTP: ${res['message'] ?? 'Foto kurang jelas'}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isScanningKtp = false);
      _showError('Terjadi kesalahan saat memproses KTP: $e');
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _filePath = result.files.single.path;
        _fileName = result.files.single.name;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedKecamatanId == null || _selectedDesaId == null) {
      _showError('Silakan pilih Kecamatan dan Kelurahan/Desa terlebih dahulu');
      return;
    }

    if (_filePath == null) {
      _showError('Silakan unggah dokumen SK / Surat Legalitas Desa');
      return;
    }

    setState(() => _isSubmitting = true);

    final String regionName = _selectedDesaData?['name'] ?? 'Desa Terkait';

    final result = await _kemitraanService.submitPartnership(
      applicantName: _namaPendaftarController.text.trim(),
      position: _jabatanController.text.trim(),
      contactPhone: _noHpController.text.trim(),
      contactEmail: _emailController.text.trim(),
      regionId: _selectedKecamatanId!,
      regionType: 'desa',
      regionName: regionName,
      reason: _pesanController.text.trim().isNotEmpty
          ? _pesanController.text.trim()
          : 'Pengajuan kemitraan resmi Desa $regionName',
      filePath: _filePath!,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['status'] == 'success') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AnimatedSuccessDialog(
          message:
              'Pengajuan kemitraan Desa berhasil dikirim! Tim Admin Kabupaten Bengkalis akan memverifikasi dokumen SK Anda.',
          isLogout: false,
        ),
      );

      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      Navigator.pop(context); // close dialog
      Navigator.pop(context); // close page
    } else {
      _showError(result['message'] ?? 'Gagal mengirim pengajuan kemitraan');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _namaPendaftarController.dispose();
    _nikController.dispose();
    _jabatanController.dispose();
    _noHpController.dispose();
    _emailController.dispose();
    _pesanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryBlue = Color(0xFF2FA2F1);
    const Color darkBlue = Color(0xFF0284C7);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          title: Text(
            'Pengajuan Kemitraan Desa',
            style: TextStyle(
              fontSize: 16.5.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                    : [primaryBlue, darkBlue],
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
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
      body: _isLoadingRegions
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  // 1. KTP Auto Scan Card
                  _buildKtpAutoFillCard(isDark),
                  SizedBox(height: 16.h),

                  // 2. Status Wilayah Banner
                  if (_selectedDesaData != null) _buildAdminDesaStatusCard(isDark),
                  if (_selectedDesaData != null) SizedBox(height: 16.h),

                  // 3. Form Section 1: Informasi Wilayah
                  _buildSectionCard(
                    isDark: isDark,
                    title: '1. Informasi Wilayah Desa',
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF2FA2F1),
                    children: [
                      // Kabupaten Fixed
                      _buildFixedField(
                        label: 'Kabupaten',
                        value: 'Kabupaten Bengkalis',
                        icon: Icons.account_balance_rounded,
                        isDark: isDark,
                      ),
                      SizedBox(height: 12.h),

                      // Dropdown Kecamatan
                      _buildDropdownField(
                        label: 'Kecamatan',
                        hint: 'Pilih Kecamatan',
                        value: _selectedKecamatanId,
                        items: _kecamatans.map((kec) {
                          return DropdownMenuItem<String>(
                            value: kec['id'].toString(),
                            child: Text(kec['name'] ?? '-'),
                          );
                        }).toList(),
                        onChanged: _onKecamatanChanged,
                        isDark: isDark,
                      ),
                      SizedBox(height: 12.h),

                      // Dropdown Desa / Kelurahan
                      _buildDropdownField(
                        label: 'Kelurahan / Desa',
                        hint: _selectedKecamatanId == null
                            ? 'Pilih Kecamatan terlebih dahulu'
                            : 'Pilih Desa / Kelurahan',
                        value: _selectedDesaId,
                        items: _desas.map((desa) {
                          final bool hasAdmin = desa['has_admin'] == true;
                          return DropdownMenuItem<String>(
                            value: desa['id'].toString(),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    desa['name'] ?? '-',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: hasAdmin
                                        ? const Color(0xFF10B981).withAlpha(25)
                                        : Colors.grey.withAlpha(25),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    hasAdmin ? 'Sudah Bermitra' : 'Belum Terdaftar',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      color: hasAdmin
                                          ? const Color(0xFF10B981)
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: _onDesaChanged,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // 4. Form Section 2: Data Pemohon
                  _buildSectionCard(
                    isDark: isDark,
                    title: '2. Data Penanggung Jawab Desa / BUMDes',
                    icon: Icons.person_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    children: [
                      _buildTextFormField(
                        controller: _namaPendaftarController,
                        label: 'Nama Lengkap (Sesuai KTP)',
                        hint: 'Contoh: Budi Santoso, S.Sos.',
                        icon: Icons.badge_outlined,
                        isDark: isDark,
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Nama penanggung jawab wajib diisi' : null,
                      ),
                      SizedBox(height: 12.h),
                      _buildTextFormField(
                        controller: _nikController,
                        label: 'Nomor Induk Kependudukan (NIK)',
                        hint: '16 Digit NIK',
                        icon: Icons.credit_card_rounded,
                        keyboardType: TextInputType.number,
                        isDark: isDark,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'NIK wajib diisi';
                          if (val.length != 16) return 'NIK harus 16 digit';
                          return null;
                        },
                      ),
                      SizedBox(height: 12.h),
                      _buildTextFormField(
                        controller: _jabatanController,
                        label: 'Jabatan / Posisi di Desa',
                        hint: 'Contoh: Kepala Desa / Direktur BUMDes',
                        icon: Icons.work_outline_rounded,
                        isDark: isDark,
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Jabatan wajib diisi' : null,
                      ),
                      SizedBox(height: 12.h),
                      _buildTextFormField(
                        controller: _noHpController,
                        label: 'Nomor WhatsApp Aktif',
                        hint: 'Contoh: 081234567890',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        isDark: isDark,
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Nomor WhatsApp wajib diisi' : null,
                      ),
                      SizedBox(height: 12.h),
                      _buildTextFormField(
                        controller: _emailController,
                        label: 'Email Kontak Resmi',
                        hint: 'Contoh: desa.bengkalis@gmail.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        isDark: isDark,
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Email wajib diisi';
                          if (!val.contains('@')) return 'Format email tidak valid';
                          return null;
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // 5. Form Section 3: Unggah Dokumen Legalitas
                  _buildSectionCard(
                    isDark: isDark,
                    title: '3. Dokumen Legalitas & SK Desa',
                    icon: Icons.assignment_outlined,
                    iconColor: const Color(0xFF10B981),
                    children: [
                      Text(
                        'Unggah SK Pengangkatan Kepala Desa, SK Pendirian BUMDes, atau Surat Tugas resmi pemerintahan desa (PDF/JPG maks 5MB).',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      InkWell(
                        onTap: _pickFile,
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withAlpha(5) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: _filePath != null
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.white12 : Colors.grey.shade300),
                              width: _filePath != null ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.w),
                                decoration: BoxDecoration(
                                  color: _filePath != null
                                      ? const Color(0xFF10B981).withAlpha(25)
                                      : primaryBlue.withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _filePath != null
                                      ? Icons.check_circle_rounded
                                      : Icons.cloud_upload_outlined,
                                  color: _filePath != null
                                      ? const Color(0xFF10B981)
                                      : primaryBlue,
                                  size: 22.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _fileName ?? 'Pilih Dokumen SK / Surat Tugas',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.bold,
                                        color: _filePath != null
                                            ? const Color(0xFF10B981)
                                            : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      _filePath != null
                                          ? 'Dokumen siap diunggah'
                                          : 'Format: PDF, PNG, JPG (Maks. 5MB)',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: isDark ? Colors.white38 : Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _buildTextFormField(
                        controller: _pesanController,
                        label: 'Catatan / Pesan Pengajuan (Opsional)',
                        hint: 'Tuliskan catatan permohonan kemitraan desa...',
                        icon: Icons.notes_rounded,
                        maxLines: 2,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
      bottomSheet: _buildBottomSubmitBar(isDark),
    );
  }

  Widget _buildKtpAutoFillCard(bool isDark) {
    const Color primaryBlue = Color(0xFF2FA2F1);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [primaryBlue.withAlpha(50), const Color(0xFF0F172A)]
              : [const Color(0xFFEFF6FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: primaryBlue.withAlpha(60),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: primaryBlue.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.document_scanner_rounded,
              color: primaryBlue,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pindai KTP (Isi Otomatis)',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Pindai e-KTP untuk mengisi Nama, NIK & Wilayah otomatis',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            onPressed: _isScanningKtp ? null : _scanKtpForAutofill,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
              elevation: 0,
            ),
            child: _isScanningKtp
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Pindai',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminDesaStatusCard(bool isDark) {
    final bool hasAdmin = _selectedDesaData?['has_admin'] == true;
    final String desaName = _selectedDesaData?['name'] ?? 'Desa';

    if (hasAdmin) {
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withAlpha(15),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Color(0xFF10B981).withAlpha(40)),
        ),
        child: Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                '$desaName sudah memiliki akun kemitraan aktif di SilaDesBeng.',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white70 : const Color(0xFF047857),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2FA2F1).withAlpha(15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Color(0xFF2FA2F1).withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF2FA2F1), size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Permohonan kemitraan $desaName akan langsung diverifikasi oleh Admin Kabupaten Bengkalis.',
              style: TextStyle(
                fontSize: 12.sp,
                color: isDark ? Colors.white70 : const Color(0xFF0284C7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: iconColor, size: 18.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFixedField({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(8) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF2FA2F1), size: 18.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text(
                hint,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isDark ? Colors.white38 : Colors.grey[500],
                ),
              ),
              items: items,
              onChanged: onChanged,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    required bool isDark,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
        ),
        SizedBox(height: 6.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 13.sp,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13.sp,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
            prefixIcon: Icon(icon, size: 18.sp, color: const Color(0xFF2FA2F1)),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFF2FA2F1), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSubmitBar(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2FA2F1),
              disabledBackgroundColor: Colors.grey.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
              elevation: 0,
            ),
            child: _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Kirim Pengajuan Kemitraan Desa',
                    style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
