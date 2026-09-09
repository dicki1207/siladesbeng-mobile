import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';

class RegisterOtpPage extends StatefulWidget {
  final String email;
  final String? phone;

  const RegisterOtpPage({
    super.key,
    required this.email,
    this.phone,
  });

  @override
  State<RegisterOtpPage> createState() => _RegisterOtpPageState();
}

class _RegisterOtpPageState extends State<RegisterOtpPage> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;

  static const Color _primaryBlue = Color(0xFF2FA2F1);
  static const Color _darkBlue = Color(0xFF0284C7);

  Future<void> _resendOtp(String method) async {
    if (_isResending) return;
    setState(() => _isResending = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/register/resend-otp'),
        body: {
          'email': widget.email,
          'method': method,
        },
      );
      final data = json.decode(res.body);
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Kode OTP telah dikirim ulang ke $method'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Gagal mengirim ulang OTP'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kesalahan jaringan: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode OTP harus 4 digit'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/register/verify-otp'),
        body: {
          'email': widget.email,
          'otp_code': otp,
        },
      );

      final data = json.decode(res.body);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        if (data['data'] != null && data['data']['token'] != null) {
          await prefs.setString('auth_token', data['data']['token']);

          final user = data['data']['user'];
          if (user != null) {
            await prefs.setString('profile_name', user['name'] ?? '');
            await prefs.setString('profile_email', user['email'] ?? '');
            if (user['phone'] != null) {
              await prefs.setString('profile_phone', user['phone']);
            }
          }
        }

        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (successContext) => const AnimatedSuccessDialog(
            message: 'Akun Terdaftar!',
            isLogout: false,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        if (!mounted) return;
        Navigator.pop(context); // Tutup dialog success
        Navigator.pop(context, true); // Kembali dengan hasil sukses ke register page
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: const Text('Gagal Verifikasi'),
            content: Text(
              data['message'] ?? 'Kode OTP salah atau telah kadaluarsa.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan koneksi: '),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Verifikasi OTP',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16.5.sp,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: _primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(isDark ? 25 : 35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 16.sp,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          SizedBox(width: 48.w),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [_primaryBlue, _darkBlue],
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 16.h),
              Center(
                child: Image.asset(
                  'assets/images/verifff.png',
                  height: 100.w,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Masukkan Kode OTP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Kode verifikasi telah dikirimkan ke Email Anda:\n',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  fontSize: 13.sp,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 32.h),

              Pinput(
                controller: _otpController,
                length: 4,
                defaultPinTheme: PinTheme(
                  width: 54.w,
                  height: 56.h,
                  textStyle: TextStyle(
                    fontSize: 22.sp,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 20 : 5),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: 54.w,
                  height: 56.h,
                  textStyle: TextStyle(
                    fontSize: 22.sp,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: Border.all(
                      color: _primaryBlue,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryBlue.withAlpha(40),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                mainAxisAlignment: MainAxisAlignment.center,
              ),
              SizedBox(height: 32.h),

              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryBlue, _darkBlue],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryBlue.withAlpha(isDark ? 60 : 80),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20.w,
                          width: 20.w,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Verifikasi OTP',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
              
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Belum Terima Kode? ',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  InkWell(
                    onTap: () => _resendOtp('email'),
                    child: Text(
                      'Kirim Ulang Kode',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: _primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.phone != null && widget.phone!.isNotEmpty) ...[
                SizedBox(height: 16.h),
                Center(
                  child: InkWell(
                    onTap: () => _resendOtp('whatsapp'),
                    child: Text(
                      'Kirim OTP melalui No. Telepon',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                        decoration: TextDecoration.underline,
                        decorationColor: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
