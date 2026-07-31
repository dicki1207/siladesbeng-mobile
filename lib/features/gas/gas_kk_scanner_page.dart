import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class GasKKScannerPage extends StatefulWidget {
  const GasKKScannerPage({super.key});

  @override
  State<GasKKScannerPage> createState() => _GasKKScannerPageState();
}

class _GasKKScannerPageState extends State<GasKKScannerPage> {
  int _step = 0;
  // 0: Upload, 1: Loading OCR, 2: Corrector Form

  String? _imagePath;

  // OCR Results (Mock)
  final TextEditingController _noKkController = TextEditingController(
    text: '1408012345678900',
  );
  final List<TextEditingController> _nikControllers = [
    TextEditingController(text: '1408010101900001'), // Suami
    TextEditingController(text: '1408010202920002'), // Istri
    TextEditingController(text: '1408010303120003'), // Anak
  ];

  bool _isBlocked = false;
  String _blockReason = '';

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
        _step = 1;
      });
      _simulateOCR();
    }
  }

  Future<void> _simulateOCR() async {
    // Simulasi waktu proses OCR
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Ganti nomor belakang menjadi acak agar pengguna bisa mengkoreksi
    _noKkController.text = '1408012345678900'; // Default untuk simulasi blokir

    setState(() {
      _step = 2;
    });
  }

  void _submitData() {
    // Cek apakah No KK terdaftar di blacklist minggu ini
    // Untuk keperluan simulasi, KK nomor 1408012345678900 dianggap sudah beli
    if (_noKkController.text.trim() == '1408012345678900') {
      setState(() {
        _isBlocked = true;
        _blockReason =
            'Anggota keluarga Anda (berdasarkan No KK ${_noKkController.text}) sudah membeli gas subsidi minggu ini. Kuota telah habis.';
      });
    } else {
      // Sukses
      Navigator.pop(context, true); // true = valid, KK confirmed
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Verifikasi Kartu Keluarga',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_step == 0) return _buildUploadStep();
    if (_step == 1) return _buildLoadingStep();
    if (_isBlocked) return _buildBlockedScreen();
    return _buildCorrectorStep();
  }

  Widget _buildUploadStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_ind, size: 80, color: Colors.blue[300]),
          const SizedBox(height: 24),
          const Text(
            'Masa Kelangkaan Gas',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Untuk memastikan distribusi gas subsidi merata ke setiap rumah tangga, mohon ambil foto Kartu Keluarga (KK) asli Anda.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black87),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text(
                    'Kamera',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text(
                    'Galeri',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: isDark ? Colors.blue[300] : Colors.blue[800],
                    side: BorderSide(color: isDark ? Colors.blue[300]! : Colors.blue[800]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.blue.withAlpha(50), blurRadius: 20),
              ],
            ),
            child: const CircularProgressIndicator(strokeWidth: 4),
          ),
          const SizedBox(height: 24),
          const Text(
            'AI sedang membaca data KK...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mengekstrak NIK seluruh anggota keluarga',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectorStep() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.orange[900]!.withAlpha(40) : Colors.orange[50],
              border: Border.all(color: isDark ? Colors.orange[700]! : Colors.orange[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: isDark ? Colors.orange[300] : Colors.orange[800]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mohon periksa hasil ketikan AI di bawah ini. Jika ada angka yang salah baca (karena foto buram), silakan perbaiki secara manual.',
                    style: TextStyle(color: isDark ? Colors.orange[200] : Colors.orange[900], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_imagePath != null)
            Container(
              height: 120,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                image: DecorationImage(
                  image: FileImage(File(_imagePath!)),
                  fit: BoxFit.cover,
                ),
              ),
            ),

          const Text(
            'Nomor Kartu Keluarga',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noKkController,
            keyboardType: TextInputType.number,
            maxLength: 16,
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Theme.of(context).cardColor : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.credit_card),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Anggota Keluarga Terdeteksi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ..._nikControllers.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: entry.value,
                keyboardType: TextInputType.number,
                maxLength: 16,
                decoration: InputDecoration(
                  labelText: 'NIK Anggota ${entry.key + 1}',
                  filled: true,
                  fillColor: isDark ? Theme.of(context).cardColor : Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Simpan & Lanjutkan Pesanan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel, size: 80, color: Colors.red[600]),
          const SizedBox(height: 24),
          const Text(
            'Transaksi Ditolak',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _blockReason,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black87),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false), // false = blocked
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.grey[300] : Colors.grey[700],
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Kembali',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
