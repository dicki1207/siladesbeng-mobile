import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';
import 'package:pinput/pinput.dart';

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
        Uri.parse('http://10.121.197.148:8000/api/kemitraan/regions'),
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
      final url = Uri.parse('http://10.121.197.148:8000/api/register');
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
        // Tampilkan modal OTP jika register tahap 1 sukses
        _showOtpDialog(_emailController.text);
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

  void _showOtpDialog(String email) {
    final otpController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Verifikasi OTP', textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Masukkan kode 4 digit yang dikirim ke email:\n$email',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.blueGrey),
                  ),

                  const SizedBox(height: 20),
                  Pinput(
                    controller: otpController,
                    length: 4,
                    defaultPinTheme: PinTheme(
                      width: 50,
                      height: 50,
                      textStyle: const TextStyle(
                        fontSize: 22,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blueGrey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 50,
                      height: 50,
                      textStyle: const TextStyle(
                        fontSize: 22,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          if (otpController.text.length != 4) return;

                          setDialogState(() => isVerifying = true);

                          try {
                            final res = await http.post(
                              Uri.parse(
                                'http://10.121.197.148:8000/api/register/verify-otp',
                              ),
                              body: {
                                'email': email,
                                'otp_code': otpController.text,
                              },
                            );

                            final data = json.decode(res.body);

                            if (res.statusCode == 200 ||
                                res.statusCode == 201) {
                              // OTP Benar, simpan token
                              final prefs =
                                  await SharedPreferences.getInstance();
                              if (data['data'] != null &&
                                  data['data']['token'] != null) {
                                await prefs.setString(
                                  'auth_token',
                                  data['data']['token'],
                                );

                                final user = data['data']['user'];
                                if (user != null) {
                                  await prefs.setString(
                                    'profile_name',
                                    user['name'] ?? '',
                                  );
                                  await prefs.setString(
                                    'profile_email',
                                    user['email'] ?? '',
                                  );
                                }
                              }

                              if (!dialogContext.mounted) return;
                              Navigator.pop(dialogContext); // Tutup dialog OTP

                              if (!mounted) return;
                              // ignore: use_build_context_synchronously
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (successContext) =>
                                    const AnimatedSuccessDialog(
                                      message: 'Akun Terdaftar',
                                      isLogout: false,
                                    ),
                              );

                              await Future.delayed(
                                const Duration(milliseconds: 1000),
                              );
                              if (!mounted) return;
                              // ignore: use_build_context_synchronously
                              Navigator.pop(context); // Tutup dialog success
                              // ignore: use_build_context_synchronously
                              Navigator.pop(context, true); // Kembali ke login
                            } else {
                              setDialogState(() => isVerifying = false);
                              if (!dialogContext.mounted) return;
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(data['message'] ?? 'OTP Salah'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isVerifying = false);
                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('Terjadi kesalahan jaringan'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Verifikasi',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
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
              'Buat Akun Baru',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Masukkan data diri Anda dengan benar.',
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
