import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:siladesbeng_mobile/services/auth_service.dart';
import 'package:siladesbeng_mobile/features/auth/forgot_password_otp_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailOrPhoneController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  static const Color _primaryBlue = Color(0xFF2FA2F1);
  static const Color _darkBlue = Color(0xFF0284C7);

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final input = _emailOrPhoneController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email atau Nomor Telepon tidak boleh kosong'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Deteksi otomatis: jika input berisi '@' => email, selain itu => whatsapp
    final method = input.contains('@') ? 'email' : 'whatsapp';

    final result = await _authService.forgotPassword(input, method);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['status'] == 'success') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ForgotPasswordOtpPage(emailOrPhone: input, otpMethod: method),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Lupa Kata Sandi',
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
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 12.h),

              // Ikon Visual Modern
              Center(
                child: Container(
                  width: 90.w,
                  height: 90.w,
                  decoration: BoxDecoration(
                    color: _primaryBlue.withAlpha(isDark ? 30 : 20),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 68.w,
                      height: 68.w,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryBlue, _darkBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _primaryBlue.withAlpha(isDark ? 50 : 80),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.lock_reset_rounded,
                        size: 36.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // Judul & Keterangan
              Text(
                'Atur Ulang Kata Sandi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'Masukkan email atau nomor HP untuk menerima kode OTP.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  fontSize: 13.sp,
                  height: 1.4,
                ),
              ),

              SizedBox(height: 24.h),

              // Card Form Input
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 25 : 5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email atau Nomor HP',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _emailOrPhoneController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Email atau nomor WhatsApp',
                        hintStyle: TextStyle(
                          fontSize: 12.5.sp,
                          color: isDark ? Colors.white30 : Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        prefixIcon: Icon(
                          Icons.alternate_email_rounded,
                          color: _primaryBlue,
                          size: 18.sp,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 13.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: const BorderSide(
                            color: _primaryBlue,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Tombol Kirim OTP
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
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  icon: _isLoading
                      ? const SizedBox.shrink()
                      : Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                  label: _isLoading
                      ? SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Kirim Kode OTP',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 24.h),

              // Tautan Kembali ke Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ingat kata sandi Anda? ',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Masuk',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: _primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
}
