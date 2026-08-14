import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';
import 'package:siladesbeng_mobile/services/kemitraan_service.dart';

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
  bool _isSubmitting = false;
  bool _isLoadingRegions = true;

  final _namaPendaftarController = TextEditingController();
  final _jabatanController = TextEditingController();
  final _noHpController = TextEditingController();
  final _emailController = TextEditingController();
  final _pesanController = TextEditingController();

  List<dynamic> _kecamatans = [];
  String? _selectedKecamatanId;
  List<dynamic> _desas = [];
  String? _selectedDesaId;

  String? _filePath;
  String? _fileName;

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

    if (_filePath == null) {
      _showError('Silakan unggah SK/Surat Tugas terlebih dahulu');
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _kemitraanService.submitPartnership(
      applicantName: _namaPendaftarController.text,
      position: _jabatanController.text,
      contactPhone: _noHpController.text,
      contactEmail: _emailController.text,
      regionId: _selectedDesaId!,
      reason: _pesanController.text,
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
              'Pengajuan kemitraan berhasil dikirim! Tim kami akan segera menghubungi Anda.',
          isLogout: false,
        ),
      );

      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      Navigator.pop(context); // close dialog
      Navigator.pop(context); // close page
    } else {
      _showError(result['message'] ?? 'Gagal mengirim pengajuan');
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
    _jabatanController.dispose();
    _noHpController.dispose();
    _emailController.dispose();
    _pesanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Pengajuan Kemitraan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingRegions
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  // 1. Compact Header Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  'http://10.250.3.148:8000/Admin/img/illustrations/logokab.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => Icon(Icons.account_balance, color: primaryColor, size: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  'http://10.250.3.148:8000/Admin/img/illustrations/logodomain.webp',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => Icon(Icons.handshake_outlined, color: primaryColor, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Form Kemitraan Desa',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Daftarkan desa Anda ke Sistem SILA-DesBeng',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 2. Section: Data Pendaftar
                  _buildSectionHeader('Data Pendaftar'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCleanTextField(
                          controller: _namaPendaftarController,
                          label: 'Nama Lengkap Pendaftar',
                          hint: 'Budi Santoso',
                          prefixIcon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildCleanTextField(
                          controller: _jabatanController,
                          label: 'Jabatan di Desa / Kelurahan',
                          hint: 'Kepala Desa / Sekretaris Desa',
                          prefixIcon: Icons.work_outline_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildCleanTextField(
                          controller: _noHpController,
                          label: 'Nomor WhatsApp / HP',
                          hint: '08123456789',
                          prefixIcon: Icons.phone_android_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildCleanTextField(
                          controller: _emailController,
                          label: 'Email Kontak Resmi',
                          hint: 'kontak@desa.id',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 14, color: primaryColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Email dan kata sandi akun akan dikirimkan ke alamat email ini.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 3. Section: Informasi Wilayah
                  _buildSectionHeader('Informasi Wilayah'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kabupaten (Prefilled & Locked)
                        _buildStaticLockedField(
                          label: 'Kabupaten',
                          value: 'Kabupaten Bengkalis',
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 12),

                        // Kecamatan Dropdown
                        _buildCleanDropdownField(
                          label: 'Kecamatan',
                          hint: 'Pilih Kecamatan...',
                          value: _selectedKecamatanId,
                          prefixIcon: Icons.map_outlined,
                          items: _kecamatans.map((kec) {
                            return DropdownMenuItem<String>(
                              value: kec['id'].toString(),
                              child: Text(
                                kec['name'],
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedKecamatanId = value;
                              _selectedDesaId = null;
                              final selectedKec = _kecamatans.firstWhere(
                                (k) => k['id'].toString() == value,
                                orElse: () => null,
                              );
                              _desas = selectedKec != null ? (selectedKec['children'] ?? []) : [];
                            });
                          },
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 12),

                        // Desa / Kelurahan Dropdown
                        _buildCleanDropdownField(
                          label: 'Kelurahan / Desa',
                          hint: _desas.isEmpty ? 'Pilih Kecamatan terlebih dahulu' : 'Pilih Kelurahan/Desa...',
                          value: _selectedDesaId,
                          prefixIcon: Icons.holiday_village_outlined,
                          items: _desas.map((desa) {
                            return DropdownMenuItem<String>(
                              value: desa['id'].toString(),
                              child: Text(
                                desa['name'],
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: _desas.isEmpty
                              ? null
                              : (value) {
                                  setState(() => _selectedDesaId = value);
                                },
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 4. Section: Dokumen Pendukung (COMPACT UPLOADER STRIP)
                  _buildSectionHeader('Dokumen Pendukung'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _filePath != null
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.15)),
                        width: _filePath != null ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SK Pengangkatan / Surat Tugas',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Compact Upload Strip Tile
                        Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: _pickFile,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: _filePath != null
                                    ? const Color(0xFF10B981).withValues(alpha: 0.08)
                                    : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC)),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _filePath != null
                                      ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                      : (isDark ? Colors.white12 : Colors.grey.shade300),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _filePath != null
                                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                          : primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _filePath != null ? Icons.description_rounded : Icons.upload_file_rounded,
                                      color: _filePath != null ? const Color(0xFF10B981) : primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _fileName ?? 'Pilih Berkas SK / Surat Tugas',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: _filePath != null
                                                ? (isDark ? Colors.white : const Color(0xFF1E293B))
                                                : (isDark ? Colors.white70 : Colors.black87),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _filePath != null
                                              ? 'Berkas siap diunggah'
                                              : 'Format PDF, JPG, PNG (Maks 5MB)',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _filePath != null
                                                ? const Color(0xFF10B981)
                                                : (isDark ? Colors.white38 : Colors.grey[500]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: _filePath != null
                                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                          : primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _filePath != null ? 'Ganti' : 'Pilih',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: _filePath != null ? const Color(0xFF10B981) : primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 5. Section: Pesan Tambahan
                  _buildSectionHeader('Pesan Tambahan'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCleanTextField(
                          controller: _pesanController,
                          label: 'Alasan Bergabung / Keterangan',
                          hint: 'Tuliskan alasan atau harapan desa Anda bergabung...',
                          prefixIcon: Icons.edit_note_rounded,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '* Semua data dan dokumen akan diverifikasi oleh admin kabupaten.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

      // Sticky Bottom Bar
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.15),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 35,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 65,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _isSubmitting ? 'Mengirim...' : 'Kirim Pengajuan',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white70 : const Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildStaticLockedField({
    required String label,
    required String value,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.location_city_rounded, size: 18, color: primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 11, color: isDark ? Colors.white54 : Colors.grey[600]),
                    const SizedBox(width: 3),
                    Text(
                      'Terkunci',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white54 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCleanDropdownField({
    required String label,
    required String hint,
    required String? value,
    required IconData prefixIcon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade300,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Row(
                children: [
                  Icon(prefixIcon, size: 18, color: primaryColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hint,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white24 : Colors.grey[400],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              dropdownColor: Theme.of(context).cardColor,
              value: value,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCleanTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade300,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Wajib diisi';
              }
              return null;
            },
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white24 : Colors.grey[400],
              ),
              prefixIcon: Icon(prefixIcon, size: 18, color: primaryColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
