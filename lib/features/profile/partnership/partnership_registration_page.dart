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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('FORM PENGAJUAN KEMITRAAN'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoadingRegions 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Daftarkan desa/kelurahan Anda untuk bergabung',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    _buildTextField(
                      label: 'Nama Lengkap Pendaftar',
                      controller: _namaPendaftarController,
                      hint: 'Budi Santoso',
                      icon: Icons.person_rounded,
                    ),
                    _buildTextField(
                      label: 'Jabatan',
                      controller: _jabatanController,
                      hint: 'Kepala Desa',
                      icon: Icons.work_rounded,
                    ),
                    _buildTextField(
                      label: 'Nomor WhatsApp',
                      controller: _noHpController,
                      hint: '08123456789',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                      label: 'Email Kontak',
                      controller: _emailController,
                      hint: 'email@desa.id',
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                      helperText: '* Email dan Sandi akun Anda akan dikirim melalui email ini. Pastikan email aktif.',
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'Informasi Wilayah',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    // Kabupaten (Statis)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Text('Kabupaten Bengkalis', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 16),
                    
                    // Kecamatan Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Semua Kecamatan'),
                          value: _selectedKecamatanId,
                          items: _kecamatans.map((kec) {
                            return DropdownMenuItem<String>(
                              value: kec['id'].toString(),
                              child: Text(kec['name']),
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
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Desa Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Semua Kelurahan/Desa'),
                          value: _selectedDesaId,
                          items: _desas.map((desa) {
                            return DropdownMenuItem<String>(
                              value: desa['id'].toString(),
                              child: Text(desa['name']),
                            );
                          }).toList(),
                          onChanged: _desas.isEmpty ? null : (value) {
                            setState(() {
                              _selectedDesaId = value;
                            });
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    const Text(
                      'Unggah SK/Surat Tugas (Max 5MB)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(15),
                          border: Border.all(color: Colors.blue.withAlpha(100), style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.cloud_upload_outlined, color: Colors.blue, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              _fileName ?? 'Pilih file atau seret dan lepas',
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const Text(
                              'PDF, PNG, JPG maksimal 5MB',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildTextField(
                      label: 'Pesan Tambahan',
                      controller: _pesanController,
                      hint: 'Alasan mengapa desa Anda ingin bergabung...',
                      icon: Icons.message_rounded,
                      maxLines: 4,
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E3C72), Color(0xFF2FA2F1)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2FA2F1).withAlpha(80),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : const Text(
                                  'Kirim Pengajuan Kemitraan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kolom ini wajib diisi';
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                prefixIcon: Padding(
                  padding: EdgeInsets.only(
                    bottom: maxLines > 1 ? (20.0 * (maxLines - 1)) : 0,
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryColor,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                helperText,
                style: const TextStyle(color: Colors.blue, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}
