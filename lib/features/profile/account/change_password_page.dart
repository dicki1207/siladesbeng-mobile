import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _submitChangePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi semua kolom kata sandi'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi baru dan konfirmasi tidak cocok'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final response = await http.post(
        Uri.parse('http://10.250.3.148:8000/api/profile/password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: {
          'current_password': _currentPasswordController.text,
          'new_password': _newPasswordController.text,
          'new_password_confirmation': _confirmPasswordController.text,
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AnimatedSuccessDialog(
            message: 'Kata Sandi Berhasil Diubah!',
            isLogout: false,
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pop(context); // close dialog
        Navigator.pop(context); // close page
      } else {
        String errorMsg = data['message'] ?? 'Gagal mengubah kata sandi';
        if (data['errors'] != null) {
          errorMsg = (data['errors'] as Map<String, dynamic>).values.first[0]
              .toString();
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal terhubung ke server'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Ubah Kata Sandi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: const Color(0xFF2563EB),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFF2FA2F1), const Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipRRect(
            child: Stack(
              children: [
                Positioned(
                  top: -30,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(22),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -15,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perbarui Keamanan Akun',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Gunakan kombinasi huruf, angka, dan karakter unik agar kata sandi kuat.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _buildPasswordField(
              label: 'Kata Sandi Saat Ini',
              controller: _currentPasswordController,
              obscureText: _obscureCurrent,
              onToggleVisibility: () =>
                  setState(() => _obscureCurrent = !_obscureCurrent),
            ),
            const SizedBox(height: 18),

            _buildPasswordField(
              label: 'Kata Sandi Baru',
              controller: _newPasswordController,
              obscureText: _obscureNew,
              onToggleVisibility: () =>
                  setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 18),

            _buildPasswordField(
              label: 'Konfirmasi Kata Sandi Baru',
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              onToggleVisibility: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitChangePassword(),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitChangePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Simpan Kata Sandi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    TextInputAction textInputAction = TextInputAction.next,
    Function(String)? onSubmitted,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade300,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: primaryColor,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
