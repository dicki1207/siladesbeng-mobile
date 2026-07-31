import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:siladesbeng_mobile/features/profile/verification/camera_recording_page.dart';

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

  List<Map<String, String>> _kecamatanList = [];
  List<Map<String, String>> _desaList = [];

  bool _isLoadingKecamatan = false;
  bool _isLoadingDesa = false;

  @override
  void initState() {
    super.initState();
    _fetchKecamatan();
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Future<void> _fetchKecamatan() async {
    setState(() => _isLoadingKecamatan = true);
    try {
      // 1408 adalah ID Kabupaten Bengkalis
      final response = await http.get(
        Uri.parse(
          'https://emsifa.github.io/api-wilayah-indonesia/api/districts/1408.json',
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _kecamatanList = data
              .map(
                (item) => {
                  'id': item['id'].toString(),
                  'name': 'Kecamatan ${_capitalize(item['name'].toString())}',
                },
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching kecamatan: $e');
    } finally {
      setState(() => _isLoadingKecamatan = false);
    }
  }

  Future<void> _fetchDesa(String kecamatanId) async {
    setState(() => _isLoadingDesa = true);
    try {
      final response = await http.get(
        Uri.parse(
          'https://emsifa.github.io/api-wilayah-indonesia/api/villages/$kecamatanId.json',
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _desaList = data
              .map(
                (item) => {
                  'id': item['id'].toString(),
                  'name': _capitalize(item['name'].toString()),
                },
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching desa: $e');
    } finally {
      setState(() => _isLoadingDesa = false);
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
      MaterialPageRoute(builder: (_) => const CameraRecordingPage()),
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
      body: SingleChildScrollView(
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
                    Icons.security,
                    color: Colors.blueAccent,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Keamanan Terjamin',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Data Anda dienkripsi dan hanya digunakan untuk keperluan verifikasi BUMDes.',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              'Lengkapi Data Diri & Alamat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

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

            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.map_outlined, color: Colors.grey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: _isLoadingKecamatan
                          ? const Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : DropdownButton<String>(
                              value: _selectedKecamatan,
                              isExpanded: true,
                              hint: const Text('Pilih Kecamatan'),
                              items: _kecamatanList
                                  .map(
                                    (k) => DropdownMenuItem(
                                      value: k['name'],
                                      child: Text(k['name']!),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val == null) return;
                                setState(() {
                                  _selectedKecamatan = val;
                                  _selectedKecamatanId = _kecamatanList
                                      .firstWhere(
                                        (k) => k['name'] == val,
                                      )['id'];
                                  _selectedDesa = null;
                                  _desaList = [];
                                });
                                _fetchDesa(_selectedKecamatanId!);
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(5),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.location_city_outlined, color: Colors.grey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: _isLoadingDesa
                          ? const Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : DropdownButton<String>(
                              value: _selectedDesa,
                              isExpanded: true,
                              hint: const Text('Pilih Desa / Kelurahan'),
                              items: _desaList
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d['name'],
                                      child: Text(d['name']!),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _selectedKecamatan == null
                                  ? null
                                  : (val) =>
                                        setState(() => _selectedDesa = val),
                            ),
                    ),
                  ),
                ],
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
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text(
                'Lanjut Rekam Wajah & KTP',
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Theme.of(context).shadowColor.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          hintText: labelText,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          icon: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Icon(icon, color: Theme.of(context).iconTheme.color),
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
