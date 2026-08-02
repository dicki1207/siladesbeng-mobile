import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:siladesbeng_mobile/features/profile/verification/camera_recording_page.dart';
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
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    setState(() {
      _isProcessingOcr = true;
      _ktpPath = image.path;
    });

    final response = await _kycService.processKtp(imagePath: image.path);

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

        // Note: Kecamatan and Desa are harder to auto-select accurately via OCR text match
        // but can be implemented with partial match if necessary. User can re-select manually.
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('KTP berhasil dipindai! Silakan periksa data Anda.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Gagal membaca KTP.'),
          backgroundColor: Colors.redAccent,
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
      MaterialPageRoute(builder: (_) => CameraRecordingPage(
        kycId: _kycId,
        nik: _nikController.text,
        name: _nameController.text,
        address: _addressController.text,
        rtRw: _rtRwController.text,
        kecamatan: _selectedKecamatan,
        desa: _selectedDesa,
      )),
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
        title: const Text('Lengkapi Data Diri'),
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
              borderRadius: BorderRadius.circular(15),
              child: Image.file(
                File(_ktpPath!),
                width: 200,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
          ],
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Sedang membaca KTP...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildUploadState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner/Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(20),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue.withAlpha(50)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.document_scanner,
                  color: Colors.blueAccent,
                  size: 40,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pindai KTP Anda',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ambil foto KTP Anda. Sistem akan secara otomatis membaca dan mengisi data Anda.',
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
          const SizedBox(height: 40),
          
          GestureDetector(
            onTap: _scanKtp,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.blueAccent.withAlpha(100),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 64, color: Colors.blueAccent),
                  SizedBox(height: 16),
                  Text(
                    'Ketuk untuk mengambil Foto KTP',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
              value: _selectedKecamatanId,
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
              value: _selectedDesa,
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
