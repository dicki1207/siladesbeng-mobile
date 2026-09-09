import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/services/kemitraan_service.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';

class PartnershipRegistrationPage extends StatefulWidget {
  const PartnershipRegistrationPage({super.key});

  @override
  State<PartnershipRegistrationPage> createState() => _PartnershipRegistrationPageState();
}

class _PartnershipRegistrationPageState extends State<PartnershipRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final KemitraanService _kemitraanService = KemitraanService();

  bool _isSubmitting = false;
  bool _isLoadingRegions = true;

  final _namaPendaftarController = TextEditingController();
  final _noHpController = TextEditingController();
  final _pesanController = TextEditingController();
  
  // Extra text fields for RW / RT
  final _nomorRwController = TextEditingController();
  final _nomorRtController = TextEditingController();
  
  String? _profileEmail = '';

  String? _selectedTingkatJabatan;
  List<String> _tingkatJabatanOptions = ['desa', 'rw', 'rt'];
  
  String? _selectedJabatanSpesifik;
  List<String> _jabatanSpesifikOptions = [];

  String? _selectedKecamatanId;
  String? _selectedDesaId;
  Map<String, dynamic>? _selectedDesaData;

  List<dynamic> _kecamatans = [];
  List<dynamic> _desas = [];

  String? _filePath;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    _isLoadingRegions = true;
    _fetchRegions();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('profile_name') ?? '';
    final email = prefs.getString('profile_email') ?? '';
    if (mounted) {
      setState(() {
        _namaPendaftarController.text = name;
        _profileEmail = email;
      });
    }
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
    if (kecamatanId == null) return;
    setState(() {
      _selectedKecamatanId = kecamatanId;
      _selectedDesaId = null;
      _selectedDesaData = null;
      _desas = _kecamatans.firstWhere((k) => k['id'].toString() == kecamatanId)['children'] ?? [];
      _updateTingkatJabatanOptions();
    });
  }

  void _onDesaChanged(String? desaId) {
    if (desaId == null) return;
    setState(() {
      _selectedDesaId = desaId;
      _selectedDesaData = _desas.firstWhere((d) => d['id'].toString() == desaId, orElse: () => null);
      _updateTingkatJabatanOptions();
    });
  }

  void _updateTingkatJabatanOptions() {
    final bool hasAdmin = _selectedDesaData?['has_admin'] == true;
    setState(() {
      if (hasAdmin) {
        _tingkatJabatanOptions = ['rw', 'rt'];
        if (_selectedTingkatJabatan == 'desa') {
          _selectedTingkatJabatan = null;
          _selectedJabatanSpesifik = null;
        }
      } else {
        _tingkatJabatanOptions = ['desa', 'rw', 'rt'];
      }
      _updateJabatanSpesifikOptions();
    });
  }

  void _onTingkatJabatanChanged(String? val) {
    setState(() {
      _selectedTingkatJabatan = val;
      _selectedJabatanSpesifik = null;
      _updateJabatanSpesifikOptions();
    });
  }

  void _updateJabatanSpesifikOptions() {
    if (_selectedTingkatJabatan == 'desa') {
      _jabatanSpesifikOptions = ['Kepala Desa', 'Sekretaris Desa', 'BPD', 'Perangkat Desa', 'Pengelola Layanan Desa', 'Lainnya'];
    } else if (_selectedTingkatJabatan == 'rw') {
      _jabatanSpesifikOptions = ['Ketua RW', 'Sekretaris RW', 'Pengurus RW Lainnya'];
    } else if (_selectedTingkatJabatan == 'rt') {
      _jabatanSpesifikOptions = ['Ketua RT', 'Sekretaris RT', 'Pengurus RT Lainnya'];
    } else {
      _jabatanSpesifikOptions = [];
    }
  }

  String _getTingkatJabatanLabel(String val) {
    switch (val) {
      case 'desa': return 'Pemerintah Desa / Kelurahan';
      case 'rw': return 'Pengurus RW';
      case 'rt': return 'Pengurus RT';
      default: return val;
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTingkatJabatan == null) {
      _showError('Silakan pilih Tingkat Jabatan terlebih dahulu');
      return;
    }
    
    if (_selectedJabatanSpesifik == null) {
      _showError('Silakan pilih Jabatan Spesifik terlebih dahulu');
      return;
    }

    if (_selectedKecamatanId == null || _selectedDesaId == null) {
      _showError('Silakan pilih Kecamatan dan Kelurahan/Desa terlebih dahulu');
      return;
    }

    if (_filePath == null) {
      _showError('Silakan unggah dokumen SK / Surat Tugas');
      return;
    }

    setState(() => _isSubmitting = true);

    String parentRegionId = _selectedKecamatanId!;
    String finalRegionName = _selectedDesaData?['name'] ?? 'Desa';
    
    if (_selectedTingkatJabatan == 'desa') {
      parentRegionId = _selectedKecamatanId!;
      finalRegionName = _selectedDesaData?['name'] ?? 'Desa';
    } else if (_selectedTingkatJabatan == 'rw') {
      parentRegionId = _selectedDesaId!;
      String cleanRw = _nomorRwController.text.replaceAll(RegExp(r'[^0-9]'), '');
      String formattedRw = cleanRw.isNotEmpty ? 'RW ${cleanRw.padLeft(2, '0')}' : _nomorRwController.text;
      finalRegionName = formattedRw;
    } else if (_selectedTingkatJabatan == 'rt') {
      parentRegionId = _selectedDesaId!;
      String cleanRw = _nomorRwController.text.replaceAll(RegExp(r'[^0-9]'), '');
      String cleanRt = _nomorRtController.text.replaceAll(RegExp(r'[^0-9]'), '');
      String formattedRw = cleanRw.isNotEmpty ? 'RW ${cleanRw.padLeft(2, '0')}' : _nomorRwController.text;
      String formattedRt = cleanRt.isNotEmpty ? 'RT ${cleanRt.padLeft(2, '0')}' : _nomorRtController.text;
      finalRegionName = '$formattedRt / $formattedRw';
    }

    final result = await _kemitraanService.submitPartnership(
      applicantName: _namaPendaftarController.text.trim(),
      position: _selectedJabatanSpesifik!,
      contactPhone: _noHpController.text.trim(),
      contactEmail: _profileEmail ?? '',
      regionId: parentRegionId,
      regionType: _selectedTingkatJabatan!,
      regionName: finalRegionName,
      reason: _pesanController.text.trim().isNotEmpty
          ? _pesanController.text.trim()
          : 'Pengajuan kemitraan resmi',
      filePath: _filePath!,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['status'] == 'success') {
      final navigator = Navigator.of(context);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              navigator.pop(); // Tutup dialog
              navigator.pop(); // Kembali ke halaman sebelumnya
            }
          });
          return AnimatedSuccessDialog(
            message: 'Pengajuan Berhasil',
            subMessage: 'Pengajuan kemitraan Anda telah dikirim dan sedang dalam proses peninjauan.',
          );
        },
      );
    } else {
      _showError(result['message'] ?? 'Gagal mengirim pengajuan. Silakan coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryBlue = Color(0xFF2FA2F1);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: AppBar(
          backgroundColor: primaryBlue,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Gabung Kemitraan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp),
            onPressed: () => Navigator.pop(context),
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
                  
                  // Banner Email
                  if (_profileEmail != null && _profileEmail!.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: primaryBlue.withAlpha(20),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: primaryBlue.withAlpha(50)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: primaryBlue, size: 18.sp),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'Email pemberitahuan akan dikirimkan ke: $_profileEmail. Pastikan akun ini adalah akun permanen Anda.',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: isDark ? Colors.white70 : Colors.blueGrey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 1. Data Pemohon & Jabatan
                  _buildSectionCard(
                    isDark: isDark,
                    title: '1. Data Penanggung Jawab',
                    icon: Icons.person_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    children: [
                      _buildTextFormField(
                        controller: _namaPendaftarController,
                        label: 'Nama Lengkap (Sesuai KTP)',
                        hint: 'Contoh: Budi Santoso, S.Sos.',
                        icon: Icons.badge_outlined,
                        isDark: isDark,
                        readOnly: true, // Karena di web readonly
                      ),
                      SizedBox(height: 12.h),
                      _buildDropdownField(
                        label: 'Tingkat Jabatan',
                        hint: 'Pilih Tingkat',
                        value: _selectedTingkatJabatan,
                        items: _tingkatJabatanOptions.map((opt) {
                          return DropdownMenuItem<String>(
                            value: opt,
                            child: Text(_getTingkatJabatanLabel(opt)),
                          );
                        }).toList(),
                        onChanged: _onTingkatJabatanChanged,
                        isDark: isDark,
                      ),
                      SizedBox(height: 12.h),
                      _buildDropdownField(
                        label: 'Jabatan Spesifik',
                        hint: _selectedTingkatJabatan == null ? 'Pilih Tingkat Jabatan Dulu' : 'Pilih Jabatan',
                        value: _selectedJabatanSpesifik,
                        items: _jabatanSpesifikOptions.map((opt) {
                          return DropdownMenuItem<String>(
                            value: opt,
                            child: Text(opt),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedJabatanSpesifik = val);
                        },
                        isDark: isDark,
                      ),
                      SizedBox(height: 12.h),
                      _buildTextFormField(
                        controller: _noHpController,
                        label: 'Nomor WhatsApp Aktif',
                        hint: 'Contoh: 08123456789',
                        icon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        isDark: isDark,
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Nomor telepon wajib diisi' : null,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // 2. Status Wilayah Banner
                  if (_selectedDesaData != null) _buildAdminDesaStatusCard(isDark),
                  if (_selectedDesaData != null) SizedBox(height: 16.h),

                  // 3. Informasi Wilayah
                  _buildSectionCard(
                    isDark: isDark,
                    title: '2. Informasi Wilayah',
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF2FA2F1),
                    children: [
                      _buildFixedField(
                        label: 'Kabupaten',
                        value: 'Kabupaten Bengkalis',
                        icon: Icons.account_balance_rounded,
                        isDark: isDark,
                      ),
                      SizedBox(height: 12.h),
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
                      if (_selectedTingkatJabatan == 'rw' || _selectedTingkatJabatan == 'rt')
                        Padding(
                          padding: EdgeInsets.only(top: 12.h),
                          child: _buildTextFormField(
                            controller: _nomorRwController,
                            label: 'Nomor RW',
                            hint: 'Contoh: 01',
                            icon: Icons.numbers_rounded,
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Nomor RW wajib diisi' : null,
                          ),
                        ),
                      if (_selectedTingkatJabatan == 'rt')
                        Padding(
                          padding: EdgeInsets.only(top: 12.h),
                          child: _buildTextFormField(
                            controller: _nomorRtController,
                            label: 'Nomor RT',
                            hint: 'Contoh: 01',
                            icon: Icons.numbers_rounded,
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                            validator: (val) =>
                                val == null || val.isEmpty ? 'Nomor RT wajib diisi' : null,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // 4. Unggah Dokumen
                  _buildSectionCard(
                    isDark: isDark,
                    title: '3. Dokumen Persyaratan',
                    icon: Icons.file_present_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    children: [
                      Text(
                        'Unggah SK / Surat Tugas Resmi',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      InkWell(
                        onTap: _pickFile,
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isDark ? Colors.white24 : Colors.grey.shade300,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2FA2F1).withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _fileName == null ? Icons.cloud_upload_outlined : Icons.check_circle_outline,
                                  color: const Color(0xFF2FA2F1),
                                  size: 24.sp,
                                ),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _fileName ?? 'Pilih file atau seret dan lepas',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: _fileName == null ? FontWeight.w600 : FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    if (_fileName == null) SizedBox(height: 2.h),
                                    if (_fileName == null)
                                      Text(
                                        'SK Jabatan (PDF, PNG, JPG maks 5MB)',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: isDark ? Colors.white60 : Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      _buildTextFormField(
                        controller: _pesanController,
                        label: 'Pesan Tambahan (Opsional)',
                        hint: 'Alasan mengapa wilayah desa Anda ingin bergabung...',
                        icon: Icons.message_rounded,
                        maxLines: 3,
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

  Widget _buildAdminDesaStatusCard(bool isDark) {
    final bool hasAdmin = _selectedDesaData?['has_admin'] == true;
    final String desaName = _selectedDesaData?['name'] ?? 'Desa';

    if (!hasAdmin) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Amber 100
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFFDE68A)), // Amber 200
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: const Color(0xFFD97706), size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              '$desaName sudah memiliki Admin Desa. Anda hanya dapat mendaftar sebagai Pengurus RW atau RT.',
              style: TextStyle(
                fontSize: 11.sp,
                color: const Color(0xFF92400E), // Amber 900
                height: 1.4,
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
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
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
    bool readOnly = false,
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
          readOnly: readOnly,
          style: TextStyle(
            fontSize: 13.sp,
            color: readOnly ? (isDark ? Colors.white54 : Colors.grey[600]) : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13.sp,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
            prefixIcon: Icon(icon, size: 18.sp, color: readOnly ? Colors.grey : const Color(0xFF2FA2F1)),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            filled: true,
            fillColor: readOnly ? (isDark ? Colors.white.withAlpha(10) : Colors.grey.shade200) : (isDark ? const Color(0xFF0F172A) : Colors.white),
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
                    'Kirim Pengajuan Kemitraan',
                    style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
