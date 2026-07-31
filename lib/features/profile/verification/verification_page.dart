import 'package:flutter/material.dart';
import 'package:siladesbeng_mobile/features/profile/verification/camera_recording_page.dart';
import 'package:siladesbeng_mobile/services/kemitraan_service.dart';

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
          : SingleChildScrollView(
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
                              Text(
                                'Data Pribadi Anda Aman',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Data Anda dienkripsi dan hanya digunakan untuk keperluan verifikasi BUMDes.',
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
                            child: DropdownButton<String>(
                              value: _selectedKecamatanId,
                              isExpanded: true,
                              hint: const Text('Pilih Kecamatan'),
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
                        ),
                      ],
                    ),
                  ),

                  // Desa Dropdown
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
                            child: DropdownButton<String>(
                              value: _selectedDesa,
                              isExpanded: true,
                              hint: const Text('Pilih Desa / Kelurahan'),
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
