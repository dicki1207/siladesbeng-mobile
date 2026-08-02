import 'package:flutter/material.dart';
import 'package:siladesbeng_mobile/services/auth_service.dart';
import 'package:siladesbeng_mobile/features/auth/forgot_password_otp_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailOrPhoneController = TextEditingController();
  String _selectedMethod = 'email'; // email or whatsapp
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _submit() async {
    final input = _emailOrPhoneController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email/No. HP tidak boleh kosong')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.forgotPassword(input, _selectedMethod);

    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });

    if (result['status'] == 'success') {
      // Demo OTP jika ada (mode debug)
      String? demoOtp = result['demo_otp'];
      if (demoOtp != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demo OTP: $demoOtp'),
            duration: const Duration(seconds: 10),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ForgotPasswordOtpPage(
            emailOrPhone: input,
            otpMethod: _selectedMethod,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Gagal'),
          content: Text(result['message'] ?? 'Terjadi kesalahan sistem.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Lupa Password'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    size: 80,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Reset Kata Sandi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Masukkan alamat email atau nomor WhatsApp yang terdaftar untuk menerima OTP.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),

              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _emailOrPhoneController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email / Nomor WhatsApp',
                    labelStyle: TextStyle(color: Colors.blueGrey, fontSize: 14),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.account_circle_outlined,
                      color: Colors.blueAccent,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Pilihan Metode OTP
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Kirim ke Email', style: TextStyle(fontSize: 14)),
                      value: 'email',
                      // ignore: deprecated_member_use
                      groupValue: _selectedMethod,
                      activeColor: Colors.blueAccent,
                      contentPadding: EdgeInsets.zero,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        setState(() {
                          _selectedMethod = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Kirim ke WhatsApp', style: TextStyle(fontSize: 14)),
                      value: 'whatsapp',
                      // ignore: deprecated_member_use
                      groupValue: _selectedMethod,
                      activeColor: Colors.green,
                      contentPadding: EdgeInsets.zero,
                      // ignore: deprecated_member_use
                      onChanged: (value) {
                        setState(() {
                          _selectedMethod = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 5,
                  shadowColor: Theme.of(
                    context,
                  ).primaryColor.withValues(alpha: 0.5),
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
                        'Kirim Kode OTP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
