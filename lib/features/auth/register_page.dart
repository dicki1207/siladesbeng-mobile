import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:siladesbeng_mobile/features/auth/register_otp_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  List<dynamic> _kecamatanList = [];
  String? _selectedKecamatanId;
  List<dynamic> _desaList = [];
  String? _selectedDesaId;
  bool _isLoadingRegions = false;

  @override
  void initState() {
    super.initState();
    _fetchRegions();
  }

  Future<void> _fetchRegions() async {
    setState(() => _isLoadingRegions = true);
    try {
      final res = await http.get(
        Uri.parse('https://siladesbeng.inovasia.site/api/kemitraan/regions'),
      );
      final data = json.decode(res.body);
      if (data['status'] == 'success') {
        if (mounted) {
          setState(() {
            _kecamatanList = data['data'];
          });
        }
      }
    } catch (e) {
      debugPrint('Gagal mengambil data wilayah: $e');
    } finally {
      if (mounted) setState(() => _isLoadingRegions = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('https://siladesbeng.inovasia.site/api/register');
      final body = {
        'email': _emailController.text,
        'password': _passwordController.text,
        'nik': '-',
        'username': _usernameController.text,
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': '-',
        'gender': 'laki-laki',
        'region_id': _selectedDesaId ?? '1',
        'password_confirmation': _passwordConfirmController.text,
      };

      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );
      final data = json.decode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Navigasi ke halaman verifikasi OTP penuh (bukan pop up)
        final isVerified = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RegisterOtpPage(
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
            ),
          ),
        );

        if (isVerified == true && mounted) {
          Navigator.pop(context, true); // Selesai register & kembali
        }
      } else {
        String errorMsg = data['message'] ?? 'Gagal';
        if (data['errors'] != null) {
          errorMsg = (data['errors'] as Map<String, dynamic>).values.first[0]
              .toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMsg'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
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
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: labelText,
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.blueGrey),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String labelText,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
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
        ],
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: labelText,
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.blueGrey),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
        ),
        icon: const Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: Icon(Icons.arrow_drop_down),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Daftar Akun Baru'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Daftar Akun Baru',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan lengkapi data diri Anda di bawah ini dengan benar.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _nameController,
              labelText: 'Nama Lengkap',
              icon: Icons.person_outline,
            ),
            _buildTextField(
              controller: _usernameController,
              labelText: 'Nama Pengguna (Username)',
              icon: Icons.alternate_email,
            ),
            _buildTextField(
              controller: _emailController,
              labelText: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            _buildTextField(
              controller: _phoneController,
              labelText: 'Nomor Telepon',
              icon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
            ),

            // Form Kabupaten Terkunci (Sesuai dengan Web Backend)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withAlpha(10)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white12
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: TextFormField(
                initialValue: 'Kabupaten Bengkalis',
                enabled: false,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : const Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                ),
                decoration: InputDecoration(
                  labelText: 'Kabupaten',
                  labelStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : Colors.blueGrey,
                  ),
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.account_balance_outlined, color: Colors.blueGrey),
                  suffixIcon: const Padding(
                    padding: EdgeInsets.only(right: 16.0),
                    child: Icon(Icons.lock_outline_rounded, color: Colors.grey, size: 20),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ),

            if (_isLoadingRegions)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _buildDropdown(
                labelText: 'Kecamatan',
                icon: Icons.map_outlined,
                value: _selectedKecamatanId,
                items: _kecamatanList.map((kec) {
                  return DropdownMenuItem<String>(
                    value: kec['id'].toString(),
                    child: Text(kec['name'] ?? ''),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedKecamatanId = val;
                    _selectedDesaId = null;
                    _desaList = [];
                    if (val != null) {
                      final selectedKec = _kecamatanList.firstWhere(
                        (k) => k['id'].toString() == val,
                        orElse: () => null,
                      );
                      if (selectedKec != null &&
                          selectedKec['children'] != null) {
                        _desaList = selectedKec['children'];
                      }
                    }
                  });
                },
              ),
              if (_selectedKecamatanId != null)
                _buildDropdown(
                  labelText: 'Desa / Kelurahan',
                  icon: Icons.location_city_outlined,
                  value: _selectedDesaId,
                  items: _desaList.map((desa) {
                    return DropdownMenuItem<String>(
                      value: desa['id'].toString(),
                      child: Text(desa['name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedDesaId = val;
                    });
                  },
                ),
            ],

            _buildTextField(
              controller: _passwordController,
              labelText: 'Kata Sandi',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.blueGrey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            _buildTextField(
              controller: _passwordConfirmController,
              labelText: 'Konfirmasi Kata Sandi',
              icon: Icons.lock_reset_outlined,
              obscureText: _obscurePasswordConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePasswordConfirm
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.blueGrey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePasswordConfirm = !_obscurePasswordConfirm;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Daftar Sekarang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
