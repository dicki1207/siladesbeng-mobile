import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:siladesbeng_mobile/services/firebase_messaging_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';
import 'package:siladesbeng_mobile/features/auth/register_page.dart';
import 'package:siladesbeng_mobile/features/auth/forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('http://10.250.3.148:8000/api/login');
      final body = {
        'email': _emailController.text,
        'password': _passwordController.text,
      };

      final response = await http.post(
        url,
        body: body,
        headers: {'Accept': 'application/json'},
      );
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

        // Simpan Role asli dari backend
        if (data['data']['user'] != null &&
            data['data']['user']['role'] != null) {
          await prefs.setString('user_role', data['data']['user']['role']);
        } else {
          await prefs.setString('user_role', 'warga'); // Fallback
        }

        // Set status verifikasi berdasarkan ketersediaan NIK
        if (data['data']['user'] != null &&
            data['data']['user']['nik'] != null) {
          await prefs.setBool('is_verified', true);
        } else {
          await prefs.setBool('is_verified', false);
        }

        // Update FCM Token
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await FirebaseMessagingService.updateTokenToServer(fcmToken);
        }

        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AnimatedSuccessDialog(
            message: 'Berhasil Masuk',
            isLogout: false,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1000));
        if (!mounted) return;
        Navigator.pop(context); // Close dialog
        Navigator.pop(
          context,
          true,
        ); // Close login page, return true to indicate success
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

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await GoogleSignIn().signOut();
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login dibatalkan.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        String locationName = '';
        try {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            Position position = await Geolocator.getCurrentPosition();
            List<Placemark> placemarks = await Geocoding()
                .placemarkFromCoordinates(
                  position.latitude,
                  position.longitude,
                );
            if (placemarks.isNotEmpty) {
              Placemark place = placemarks[0];
              locationName = place.subLocality ?? place.locality ?? '';
            }
          }
        } catch (locErr) {
          debugPrint('Location Error: $locErr');
        }

        final response = await http.post(
          Uri.parse('http://10.250.3.148:8000/api/login/google'),
          headers: {'Accept': 'application/json'},
          body: {
            'email': user.email ?? '',
            'name': user.displayName ?? 'Google User',
            'google_id': user.uid,
            'location_name': locationName,
          },
        );
        final data = json.decode(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['data']['token']);
          await prefs.setString(
            'profile_name',
            data['data']['user']['name'] ?? user.displayName ?? 'Google User',
          );
          await prefs.setString(
            'profile_email',
            data['data']['user']['email'] ?? user.email ?? '',
          );
          if (data['data']['user'] != null &&
              data['data']['user']['role'] != null) {
            await prefs.setString('user_role', data['data']['user']['role']);
          } else {
            await prefs.setString('user_role', 'warga');
          }

          if (data['data']['user'] != null &&
              data['data']['user']['nik'] != null) {
            await prefs.setBool('is_verified', true);
          } else {
            await prefs.setBool('is_verified', false);
          }
          await prefs.remove('profile_image');
          if (user.photoURL != null) {
            await prefs.setString('profile_image_url', user.photoURL!);
          }

          // Update FCM Token
          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await FirebaseMessagingService.updateTokenToServer(fcmToken);
          }

          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AnimatedSuccessDialog(
              message: 'Berhasil Masuk',
              isLogout: false,
            ),
          );

          await Future.delayed(const Duration(milliseconds: 1000));
          if (!mounted) return;
          Navigator.pop(context); // Close dialog
          Navigator.pop(context, true); // Close login page
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal: ${data['message']}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error Google Sign In: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Top Header with Premium Gradient & Curved Edge
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 240,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                          : [const Color(0xFF2FA2F1), const Color(0xFF0284C7)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withAlpha(50)
                            : const Color(0x332FA2F1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Ambient Glowing Circle 1
                      Positioned(
                        top: -40,
                        right: -30,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(25),
                          ),
                        ),
                      ),
                      // Ambient Glowing Circle 2
                      Positioned(
                        bottom: 30,
                        left: -40,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withAlpha(18),
                          ),
                        ),
                      ),
                      // Top Bar (Back Button + Title)
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const Text(
                                'Masuk Akun',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 48), // Balance spacer
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating Logo Card on Header
                Positioned(
                  bottom: -45,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withAlpha(80)
                              : const Color(0x2E2FA2F1),
                          blurRadius: 24,
                          spreadRadius: 4,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'logodomain.png',
                      height: 72,
                      width: 72,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 60),

            // Welcome Text Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    'Selamat Datang!',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Silakan masuk untuk mengakses layanan desa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Form Input Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Email Input Field
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        hintText: 'nama@email.com',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13.5,
                          fontWeight: FontWeight.normal,
                        ),
                        labelText: 'Alamat Email',
                        labelStyle: TextStyle(
                          color: isDark
                              ? Colors.grey[400]
                              : const Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.email_rounded,
                              color: primaryColor,
                              size: 18,
                            ),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Password Input Field
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : const Color(0xFFE2E8F0),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                        labelText: 'Kata Sandi',
                        labelStyle: TextStyle(
                          color: isDark
                              ? Colors.grey[400]
                              : const Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              color: primaryColor,
                              size: 18,
                            ),
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Forgot Password Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Lupa Password?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Premium Gradient Login Button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2FA2F1),
                          const Color(0xFF0284C7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2FA2F1).withAlpha(80),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Masuk Sekarang',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Google Sign In Button
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(6),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: Image.asset(
                        'assets/images/google_logo.png',
                        height: 20,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.g_mobiledata, size: 24),
                      ),
                      label: Text(
                        'Masuk dengan Google',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                          color: isDark
                              ? Colors.white12
                              : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Register Footer Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum punya akun? ',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          ).then((value) {
                            if (value == true) {
                              if (!context.mounted) return;
                              Navigator.pop(context, true);
                            }
                          });
                        },
                        child: Text(
                          'Daftar Sekarang',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Official Trust Badge at the Bottom
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withAlpha(8)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 13,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Terenkripsi & Terintegrasi Pemkab Bengkalis',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
