import 'package:flutter/material.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';

class PartnershipRegistrationPage extends StatefulWidget {
  const PartnershipRegistrationPage({super.key});

  @override
  State<PartnershipRegistrationPage> createState() =>
      _PartnershipRegistrationPageState();
}

class _PartnershipRegistrationPageState
    extends State<PartnershipRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  final _namaBumdesController = TextEditingController();
  final _namaKetuaController = TextEditingController();
  final _noHpController = TextEditingController();
  final _alamatController = TextEditingController();
  final _desaController = TextEditingController();
  final _kecamatanController = TextEditingController();

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Simulate network request for now
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

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
  }

  @override
  void dispose() {
    _namaBumdesController.dispose();
    _namaKetuaController.dispose();
    _noHpController.dispose();
    _alamatController.dispose();
    _desaController.dispose();
    _kecamatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulir Kemitraan'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data BUMDes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Lengkapi data di bawah ini untuk mengajukan kemitraan resmi dengan SiladesBeng.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              _buildTextField(
                label: 'Nama BUMDes',
                controller: _namaBumdesController,
                hint: 'Contoh: BUMDes Maju Bersama',
                icon: Icons.store_mall_directory_rounded,
              ),
              _buildTextField(
                label: 'Nama Ketua / Penanggung Jawab',
                controller: _namaKetuaController,
                hint: 'Masukkan nama lengkap',
                icon: Icons.person_rounded,
              ),
              _buildTextField(
                label: 'Nomor WhatsApp (Aktif)',
                controller: _noHpController,
                hint: '08xxxxxxxxxx',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),
              _buildTextField(
                label: 'Kecamatan',
                controller: _kecamatanController,
                hint: 'Contoh: Mandau',
                icon: Icons.map_rounded,
              ),
              _buildTextField(
                label: 'Desa / Kelurahan',
                controller: _desaController,
                hint: 'Contoh: Air Jamban',
                icon: Icons.location_city_rounded,
              ),
              _buildTextField(
                label: 'Alamat Lengkap BUMDes',
                controller: _alamatController,
                hint: 'Nama jalan, RT/RW, nomor gedung',
                icon: Icons.home_rounded,
                maxLines: 3,
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
                            'Kirim Pengajuan Mitra',
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
        ],
      ),
    );
  }
}
