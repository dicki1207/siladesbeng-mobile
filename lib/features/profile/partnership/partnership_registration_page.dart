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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Pengajuan Kemitraan', style: TextStyle(color: Colors.black87, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoadingRegions 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.shield, color: Colors.green[700], size: 40), // Placeholder for Bengkalis Logo
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'FORM PENGAJUAN KEMITRAAN',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Daftarkan desa/kelurahan Anda untuk bergabung',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  'Sistem Sinergi Layanan dan Aspirasi Desa di Kabupaten Bengkalis',
                                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.handshake, color: Colors.blue, size: 40), // Placeholder for Sila-DesBeng Logo
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(thickness: 1.5),
                      const SizedBox(height: 24),
                      
                      _buildWebTextField(
                        label: 'Nama Lengkap Pendaftar',
                        controller: _namaPendaftarController,
                        hint: 'Budi Santoso',
                      ),
                      _buildWebTextField(
                        label: 'Jabatan',
                        controller: _jabatanController,
                        hint: 'Kepala Desa',
                      ),
                      _buildWebTextField(
                        label: 'Nomor WhatsApp',
                        controller: _noHpController,
                        hint: '08123456789',
                        keyboardType: TextInputType.phone,
                      ),
                      _buildWebTextField(
                        label: 'Email Kontak',
                        controller: _emailController,
                        hint: 'email@desa.id',
                        keyboardType: TextInputType.emailAddress,
                        helperText: '* Email dan Sandi akun Anda akan dikirim melalui email ini. Pastikan email aktif.',
                      ),

                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Informasi Wilayah',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Divider(color: Colors.grey[300])),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Kabupaten (Statis)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Text('Kabupaten Bengkalis', style: TextStyle(fontSize: 14, color: Colors.black87)),
                      ),
                      const SizedBox(height: 12),
                      
                      // Kecamatan Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text('Kecamatan...', style: TextStyle(fontSize: 14)),
                            value: _selectedKecamatanId,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
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
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Desa Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text('Semua Kelurahan/Desa', style: TextStyle(fontSize: 14)),
                            value: _selectedDesaId,
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
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
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      const Text(
                        'Unggah SK/Surat Tugas (Max 5MB)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            border: Border.all(color: Colors.blue[200]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.cloud_upload_outlined, color: Colors.blue, size: 32),
                              const SizedBox(height: 8),
                              Text(
                                _fileName != null ? 'File terpilih: $_fileName' : 'Pilih file atau seret dan lepas',
                                style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'PDF, PNG, JPG maksimal 5MB',
                                style: TextStyle(color: Colors.grey, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      _buildWebTextField(
                        label: 'Pesan Tambahan',
                        controller: _pesanController,
                        hint: 'Alasan mengapa desa Anda ingin bergabung...',
                        maxLines: 4,
                      ),

                      const SizedBox(height: 24),
                      const Text('* Semua kolom wajib diisi', style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[300]!),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: const Text('Batal', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Kirim Pengajuan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWebTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Wajib diisi';
              }
              return null;
            },
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue[400]!),
              ),
            ),
          ),
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text(
                helperText,
                style: const TextStyle(color: Colors.blue, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }
}
