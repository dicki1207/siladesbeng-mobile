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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Pengajuan Kemitraan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: _isLoadingRegions 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[700]!, Colors.blue[500]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withAlpha(60),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo Bengkalis
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    'http://10.250.3.148:8000/Admin/img/illustrations/logokab.png',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                    errorBuilder: (c, e, s) => const Icon(Icons.account_balance, color: Colors.white, size: 24),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Logo SiladesBeng
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    'http://10.250.3.148:8000/Admin/img/illustrations/logodomain.webp',
                                    width: 30,
                                    height: 30,
                                    fit: BoxFit.contain,
                                    errorBuilder: (c, e, s) => const Icon(Icons.handshake, color: Colors.white, size: 24),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Form Pengajuan Kemitraan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Daftarkan desa/kelurahan Anda untuk bergabung\nSistem Sinergi Layanan dan Aspirasi Desa',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withAlpha(200),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Section: Data Pendaftar
                    _buildSectionTitle(Icons.person_outline, 'Data Pendaftar'),
                    const SizedBox(height: 16),

                    _buildTextField(
                      label: 'Nama Lengkap',
                      controller: _namaPendaftarController,
                      hint: 'Budi Santoso',
                      prefixIcon: Icons.badge_outlined,
                    ),
                    _buildTextField(
                      label: 'Jabatan',
                      controller: _jabatanController,
                      hint: 'Kepala Desa',
                      prefixIcon: Icons.work_outline,
                    ),
                    _buildTextField(
                      label: 'Nomor WhatsApp',
                      controller: _noHpController,
                      hint: '08123456789',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                      label: 'Email Kontak',
                      controller: _emailController,
                      hint: 'email@desa.id',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Colors.blue[400]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Email dan sandi akun akan dikirim melalui email ini.',
                              style: TextStyle(fontSize: 11, color: Colors.blue[400], fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Section: Informasi Wilayah
                    _buildSectionTitle(Icons.location_on_outlined, 'Informasi Wilayah'),
                    const SizedBox(height: 16),

                    // Kabupaten (Statis)
                    _buildStaticField('Kabupaten', 'Kabupaten Bengkalis'),
                    const SizedBox(height: 12),
                    
                    // Kecamatan Dropdown
                    _buildDropdownField(
                      label: 'Kecamatan',
                      hint: 'Pilih Kecamatan...',
                      value: _selectedKecamatanId,
                      items: _kecamatans.map((kec) {
                        return DropdownMenuItem<String>(
                          value: kec['id'].toString(),
                          child: Text(kec['name'], style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedKecamatanId = value;
                          _selectedDesaId = null;
                          final selectedKec = _kecamatans.firstWhere((k) => k['id'].toString() == value);
                          _desas = selectedKec['children'] ?? [];
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Desa Dropdown
                    _buildDropdownField(
                      label: 'Kelurahan/Desa',
                      hint: 'Pilih Kelurahan/Desa...',
                      value: _selectedDesaId,
                      items: _desas.map((desa) {
                        return DropdownMenuItem<String>(
                          value: desa['id'].toString(),
                          child: Text(desa['name'], style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: _desas.isEmpty ? null : (value) {
                        setState(() {
                          _selectedDesaId = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 28),

                    // Section: Dokumen
                    _buildSectionTitle(Icons.upload_file_outlined, 'Dokumen Pendukung'),
                    const SizedBox(height: 16),

                    Text(
                      'SK/Surat Tugas (Max 5MB)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickFile,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: BoxDecoration(
                          color: _filePath != null 
                              ? (isDark ? Colors.green.withAlpha(20) : Colors.green[50])
                              : (isDark ? Colors.blue.withAlpha(15) : Colors.blue[50]),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _filePath != null 
                                ? Colors.green.withAlpha(100)
                                : (isDark ? Colors.blue.withAlpha(60) : Colors.blue[200]!),
                            width: 1.5,
                            strokeAlign: BorderSide.strokeAlignInside,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _filePath != null 
                                    ? Colors.green.withAlpha(30)
                                    : Colors.blue.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _filePath != null ? Icons.check_circle : Icons.cloud_upload_outlined,
                                color: _filePath != null ? Colors.green : Colors.blue,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _fileName ?? 'Ketuk untuk memilih file',
                              style: TextStyle(
                                color: _filePath != null ? Colors.green : Colors.blue,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_filePath == null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'PDF, PNG, JPG maksimal 5MB',
                                style: TextStyle(color: Colors.grey[500], fontSize: 11),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Section: Pesan
                    _buildSectionTitle(Icons.message_outlined, 'Pesan Tambahan'),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Alasan Bergabung',
                      controller: _pesanController,
                      hint: 'Alasan mengapa desa Anda ingin bergabung...',
                      maxLines: 4,
                      prefixIcon: null,
                    ),

                    const SizedBox(height: 12),
                    Text(
                      '* Semua kolom wajib diisi',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 24),
                    
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'Batal',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              disabledBackgroundColor: Colors.blue[300],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Kirim Pengajuan',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: Colors.grey.withAlpha(60))),
      ],
    );
  }

  Widget _buildStaticField(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[600])),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardColor.withAlpha(150) : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(value, style: TextStyle(fontSize: 14, color: isDark ? Colors.white54 : Colors.black54)),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.grey[400] : Colors.grey[600])),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardColor : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text(hint, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              dropdownColor: isDark ? Theme.of(context).cardColor : Colors.white,
              value: value,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
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
        style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 13, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: Colors.blue.withAlpha(150)) : null,
          filled: true,
          fillColor: isDark ? Theme.of(context).cardColor : const Color(0xFFF8F9FA),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: maxLines > 1 ? 16 : 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue[400]!, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}
