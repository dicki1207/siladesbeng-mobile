import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://10.193.206.148:8000/api/register');
      final body = {
        'email': _emailController.text,
        'password': _passwordController.text,
        'nik': '-',
        'username': _emailController.text,
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': '-',
        'gender': 'laki-laki',
        'region_id': '1',
        'password_confirmation': _passwordConfirmController.text,
      };

      final response = await http.post(url, body: body);
      final data = json.decode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        if (data['data'] != null && data['data']['token'] != null) {
          await prefs.setString('auth_token', data['data']['token']);

          final user = data['data']['user'];
          if (user != null) {
            await prefs.setString('profile_name', user['name'] ?? '');
            await prefs.setString('profile_email', user['email'] ?? '');
            if (data['data']['avatar_url'] != null) {
              await prefs.setString(
                'profile_image_url',
                data['data']['avatar_url'],
              );
            }
          }
        }

        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AnimatedSuccessDialog(
            message: 'Berhasil Daftar!',
            isLogout: false,
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pop(context); // Close dialog
        Navigator.pop(
          context,
          true,
        ); // Close register page and indicate success to login page
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
        const SnackBar(
          content: Text('Gagal terhubung ke Server!'),
          backgroundColor: Colors.redAccent,
        ),
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
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
            _buildTextField(
              controller: _passwordController,
              labelText: 'Kata Sandi',
              icon: Icons.lock_outline,
              obscureText: true,
            ),
            _buildTextField(
              controller: _passwordConfirmController,
              labelText: 'Konfirmasi Kata Sandi',
              icon: Icons.lock_reset_outlined,
              obscureText: true,
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
