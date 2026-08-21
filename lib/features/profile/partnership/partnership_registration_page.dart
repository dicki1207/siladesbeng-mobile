import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:siladesbeng_mobile/features/profile/verification/ktp_camera_scanner_page.dart';
import 'package:siladesbeng_mobile/services/kemitraan_service.dart';
import 'package:siladesbeng_mobile/services/kyc_service.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';

class PartnershipRegistrationPage extends StatefulWidget {
  final String initialRole; // 'desa', 'rw', 'rt'

  const PartnershipRegistrationPage({
    super.key,
    this.initialRole = 'desa',
  });

  @override
  State<PartnershipRegistrationPage> createState() =>
      _PartnershipRegistrationPageState();
}

class _PartnershipRegistrationPageState
    extends State<PartnershipRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final KemitraanService _kemitraanService = KemitraanService();
  final KycService _kycService = KycService();

  late String _currentRole; // 'desa', 'rw', 'rt'
  bool _isSubmitting = false;
  bool _isLoadingRegions = true;
  bool _isScanningKtp = false;

  final _namaPendaftarController = TextEditingController();
  final _nikController = TextEditingController();
  final _jabatanController = TextEditingController();
  final _noHpController = TextEditingController();
  final _emailController = TextEditingController();
  final _pesanController = TextEditingController();

  // RT / RW specific controllers
  final _rtNumberController = TextEditingController();
  final _rwNumberController = TextEditingController();

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
    _currentRole = widget.initialRole;
    _updateDefaultJabatan();
    _fetchRegions();
  }

  void _updateDefaultJabatan() {
    if (_currentRole == 'desa') {
      if (_jabatanController.text.isEmpty ||
          _jabatanController.text.startsWith('Ketua RT') ||
          _jabatanController.text.startsWith('Ketua RW')) {
        _jabatanController.text = 'Kepala Desa / Perangkat Desa';
      }
    } else if (_currentRole == 'rw') {
      final rwNo = _rwNumberController.text.trim();
      _jabatanController.text = rwNo.isNotEmpty ? 'Ketua RW $rwNo' : 'Ketua RW';
    } else if (_currentRole == 'rt') {
      final rtNo = _rtNumberController.text.trim();
      _jabatanController.text = rtNo.isNotEmpty ? 'Ketua RT $rtNo' : 'Ketua RT';
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

    // Check if role is RT/RW and Desa has NO admin
    if ((_currentRole == 'rw' || _currentRole == 'rt') && desa != null) {
      final bool hasAdmin = desa['has_admin'] == true;
      if (!hasAdmin) {
        _showDesaBelumTerdaftarDialog(desa['name'] ?? 'Desa');
      }
    }
  }

  void _showDesaBelumTerdaftarDialog(String desaName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Warning Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.gpp_maybe_rounded,
                    color: Color(0xFFD97706),
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              const Text(
                'Desa Belum Bergabung',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Description
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(10) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                child: Text(
                  'Mohon maaf, pendaftaran akun kepengurusan ${_currentRole.toUpperCase()} untuk $desaName belum dapat diproses.\n\nDesa Anda tercatat belum bergabung dalam kemitraan resmi SilaDesBeng. Pendaftaran ${_currentRole.toUpperCase()} memerlukan verifikasi dan persetujuan dari Pemerintah Desa setempat untuk memastikan keabsahan wilayah tugas Anda.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _currentRole = 'desa';
                      _updateDefaultJabatan();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Beralih ke formulir pendaftaran Desa.'),
                        backgroundColor: Color(0xFF0EA5E9),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_business_rounded, color: Colors.white, size: 18),
                  label: const Text(
                    'Daftarkan Desa Anda',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _selectedDesaId = null;
                      _selectedDesaData = null;
                    });
                  },
                  child: Text(
                    'Pilih Desa / Wilayah Lain',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        final String? ocrRtRw = ocr['rt_rw'];

        if (ocrName != null && ocrName.isNotEmpty) {
          _namaPendaftarController.text = ocrName;
        }
        if (ocrNik != null && ocrNik.isNotEmpty) {
          _nikController.text = ocrNik;
        }

        // Auto parse RT/RW if available (e.g. "003/002")
        if (ocrRtRw != null && ocrRtRw.contains('/')) {
          final parts = ocrRtRw.split('/');
          if (parts.isNotEmpty) {
            _rtNumberController.text = parts[0].trim();
          }
          if (parts.length > 1) {
            _rwNumberController.text = parts[1].trim();
          }
          _updateDefaultJabatan();
        }

        // Try to match Kecamatan and Desa
        if (ocrKec != null && _kecamatans.isNotEmpty) {
          final matchedKec = _kecamatans.firstWhere(
            (k) => k['name'].toString().toLowerCase().contains(ocrKec.toLowerCase()),
            orElse: () => null,
          );
          if (matchedKec != null) {
            _onKecamatanChanged(matchedKec['id'].toString());

            if (ocrDesa != null && _desas.isNotEmpty) {
              final matchedDesa = _desas.firstWhere(
                (d) => d['name'].toString().toLowerCase().contains(ocrDesa.toLowerCase()),
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

    if (_selectedDesaId == null) {
      _showError('Silakan pilih Kelurahan/Desa terlebih dahulu');
      return;
    }

    // Guard: RT / RW cannot register if Desa has no admin
    if ((_currentRole == 'rw' || _currentRole == 'rt') &&
        _selectedDesaData != null &&
        _selectedDesaData!['has_admin'] != true) {
      _showDesaBelumTerdaftarDialog(_selectedDesaData!['name'] ?? 'Desa');
      return;
    }

    if (_filePath == null) {
      _showError('Silakan unggah dokumen SK / Surat Tugas');
      return;
    }

    setState(() => _isSubmitting = true);

    // Build region name depending on role
    String regionName = _selectedDesaData?['name'] ?? '-';
    if (_currentRole == 'rt') {
      final rtNo = _rtNumberController.text.trim();
      final rwNo = _rwNumberController.text.trim();
      regionName = 'RT $rtNo / RW $rwNo ($regionName)';
    } else if (_currentRole == 'rw') {
      final rwNo = _rwNumberController.text.trim();
      regionName = 'RW $rwNo ($regionName)';
    }

    final result = await _kemitraanService.submitPartnership(
      applicantName: _namaPendaftarController.text.trim(),
      position: _jabatanController.text.trim(),
      contactPhone: _noHpController.text.trim(),
      contactEmail: _emailController.text.trim(),
      regionId: _selectedDesaId!,
      regionType: _currentRole,
      regionName: regionName,
      reason: _pesanController.text.trim().isNotEmpty
          ? _pesanController.text.trim()
          : 'Pengajuan akun ${_currentRole.toUpperCase()} $regionName',
      filePath: _filePath!,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['status'] == 'success') {
      final String successMsg = _currentRole == 'desa'
          ? 'Pengajuan kemitraan Admin Desa berhasil dikirim! Tim Admin Kabupaten akan segera memverifikasi SK Anda.'
          : 'Pengajuan akun ${_currentRole.toUpperCase()} berhasil dikirim! Permohonan akan diverifikasi langsung oleh Admin Desa ${_selectedDesaData?['name'] ?? ''}.';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AnimatedSuccessDialog(
          message: successMsg,
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
    _rtNumberController.dispose();
    _rwNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF0EA5E9);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Pengajuan Kemitraan Akun',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1E3C72),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingRegions
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  // 1. Role Selector Tab (Desa, RW, RT)
                  _buildRoleSegmentedBar(isDark),
                  const SizedBox(height: 16),

                  // 2. KTP Auto Scan Card
                  _buildKtpAutoFillCard(isDark),
                  const SizedBox(height: 16),

                  // 3. Status Wilayah & Admin Desa Banner (if Desa selected)
                  if (_selectedDesaData != null) _buildAdminDesaStatusCard(isDark),
                  if (_selectedDesaData != null) const SizedBox(height: 16),

                  // 4. Form Section 1: Informasi Wilayah
                  _buildSectionCard(
                    isDark: isDark,
                    title: '1. Informasi Wilayah',
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    children: [
                      // Kabupaten Fixed
                      _buildFixedField(
                        label: 'Kabupaten',
                        value: 'Kabupaten Bengkalis',
                        icon: Icons.account_balance_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

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
                      const SizedBox(height: 12),

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
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: hasAdmin
                                        ? const Color(0xFF10B981).withAlpha(25)
                                        : Colors.grey.withAlpha(25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    hasAdmin ? 'Mitra Aktif' : 'Belum Ada Admin',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: hasAdmin ? const Color(0xFF10B981) : Colors.grey[600],
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

                      // Nomor RT / RW if applicable
                      if (_currentRole == 'rt' || _currentRole == 'rw') ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (_currentRole == 'rt')
                              Expanded(
                                child: _buildTextFormField(
                                  controller: _rtNumberController,
                                  label: 'Nomor RT',
                                  hint: 'Contoh: 003',
                                  icon: Icons.numbers_rounded,
                                  keyboardType: TextInputType.number,
                                  isDark: isDark,
                                  onChanged: (_) => _updateDefaultJabatan(),
                                  validator: (val) => val == null || val.isEmpty ? 'Isi No. RT' : null,
                                ),
                              ),
                            if (_currentRole == 'rt') const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextFormField(
                                controller: _rwNumberController,
                                label: _currentRole == 'rt' ? 'RW Naungan' : 'Nomor RW',
                                hint: 'Contoh: 002',
                                icon: Icons.tag_rounded,
                                keyboardType: TextInputType.number,
                                isDark: isDark,
                                onChanged: (_) => _updateDefaultJabatan(),
                                validator: (val) => val == null || val.isEmpty ? 'Isi No. RW' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 5. Form Section 2: Data Pemohon
                  _buildSectionCard(
                    isDark: isDark,
                    title: '2. Data Pribadi Pengurus',
                    icon: Icons.person_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    children: [
                      _buildTextFormField(
                        controller: _namaPendaftarController,
                        label: 'Nama Lengkap (Sesuai KTP)',
                        hint: 'Contoh: Budi Santoso',
                        icon: Icons.badge_outlined,
                        isDark: isDark,
                        validator: (val) => val == null || val.isEmpty ? 'Nama pendaftar wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _jabatanController,
                        label: 'Jabatan / Posisi',
                        hint: 'Contoh: Ketua RT 003',
                        icon: Icons.work_outline_rounded,
                        isDark: isDark,
                        validator: (val) => val == null || val.isEmpty ? 'Jabatan wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _noHpController,
                        label: 'Nomor WhatsApp Aktif',
                        hint: 'Contoh: 081234567890',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        isDark: isDark,
                        validator: (val) => val == null || val.isEmpty ? 'Nomor WhatsApp wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _emailController,
                        label: 'Email Kontak',
                        hint: 'Contoh: rt03.desa@gmail.com',
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
                  const SizedBox(height: 16),

                  // 6. Form Section 3: Unggah Dokumen Legalitas
                  _buildSectionCard(
                    isDark: isDark,
                    title: '3. Dokumen Legalitas & SK',
                    icon: Icons.assignment_outlined,
                    iconColor: const Color(0xFF10B981),
                    children: [
                      Text(
                        _currentRole == 'desa'
                            ? 'Unggah SK Pengangkatan Kepala Desa / Surat Kepengurusan BUMDes resmi (PDF/JPG max 5MB).'
                            : 'Unggah SK Pengangkatan ${_currentRole.toUpperCase()} yang ditandatangani Kepala Desa (PDF/JPG max 5MB).',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickFile,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withAlpha(5) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
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
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _filePath != null
                                      ? const Color(0xFF10B981).withAlpha(25)
                                      : primaryColor.withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _filePath != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                                  color: _filePath != null ? const Color(0xFF10B981) : primaryColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _fileName ?? 'Pilih File Dokumen SK / Surat Tugas',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: _filePath != null
                                            ? (_currentRole == 'desa' ? primaryColor : const Color(0xFF10B981))
                                            : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _filePath != null ? 'Dokumen siap diunggah' : 'Format: PDF, PNG, JPG (Maks. 5MB)',
                                      style: TextStyle(
                                        fontSize: 11,
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
                      const SizedBox(height: 12),
                      _buildTextFormField(
                        controller: _pesanController,
                        label: 'Catatan / Pesan Pengajuan (Opsional)',
                        hint: 'Tuliskan catatan pengajuan atau informasi tambahan...',
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

  Widget _buildRoleSegmentedBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildRoleTabItem('desa', '🏛️ Admin Desa', isDark),
          _buildRoleTabItem('rw', '👥 Ketua RW', isDark),
          _buildRoleTabItem('rt', '🏠 Ketua RT', isDark),
        ],
      ),
    );
  }

  Widget _buildRoleTabItem(String roleKey, String label, bool isDark) {
    final isSelected = _currentRole == roleKey;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentRole = roleKey;
            _updateDefaultJabatan();
          });

          // If changing to RT/RW and selected desa has no admin, prompt warning
          if ((roleKey == 'rw' || roleKey == 'rt') &&
              _selectedDesaData != null &&
              _selectedDesaData!['has_admin'] != true) {
            _showDesaBelumTerdaftarDialog(_selectedDesaData!['name'] ?? 'Desa');
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF0EA5E9) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildKtpAutoFillCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A8A).withAlpha(150), const Color(0xFF0F172A)]
              : [const Color(0xFFEFF6FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3B82F6).withAlpha(60),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.document_scanner_rounded, color: Color(0xFF3B82F6), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pindai KTP (Isi Otomatis)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Pindai e-KTP untuk mengisi Nama, NIK & Wilayah instan',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isScanningKtp ? null : _scanKtpForAutofill,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _isScanningKtp
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Pindai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminDesaStatusCard(bool isDark) {
    final bool hasAdmin = _selectedDesaData?['has_admin'] == true;
    final String desaName = _selectedDesaData?['name'] ?? 'Desa';

    if (_currentRole == 'desa') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0EA5E9).withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF0EA5E9).withAlpha(40)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF0EA5E9), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Pendaftaran kemitraan Desa akan diverifikasi langsung oleh Admin Kabupaten Bengkalis.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF0369A1),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (hasAdmin) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10B981).withAlpha(40)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$desaName Sudah Bergabung',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pemerintah Desa aktif & siap memvalidasi permohonan akun ${_currentRole.toUpperCase()} Anda.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$desaName Belum Bergabung',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pemerintah Desa belum mengaktifkan kemitraan SilaDesBeng. Daftarkan Desa Anda terlebih dahulu agar kepengurusan ${_currentRole.toUpperCase()} dapat divalidasi.',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSectionCard({
    required bool isDark,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withAlpha(8) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF0EA5E9), size: 18),
              const SizedBox(width: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              hint: Text(
                hint,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey[500]),
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.grey[400]),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF0EA5E9)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSubmitBar(bool isDark) {
    final bool isBlocked = (_currentRole == 'rw' || _currentRole == 'rt') &&
        _selectedDesaData != null &&
        _selectedDesaData!['has_admin'] != true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
          height: 52,
          child: ElevatedButton(
            onPressed: (_isSubmitting || isBlocked) ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              disabledBackgroundColor: Colors.grey.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    isBlocked
                        ? 'Desa Belum Memiliki Admin'
                        : (_currentRole == 'desa'
                            ? 'Ajukan Kemitraan Desa'
                            : 'Ajukan Akun ${_currentRole.toUpperCase()} ke Admin Desa'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
