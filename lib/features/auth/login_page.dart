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
      final url = Uri.parse('http://10.193.206.148:8000/api/login');
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
            message: 'Berhasil Login!',
            isLogout: false,
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
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
          Uri.parse('http://10.193.206.148:8000/api/login/google'),
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
              message: 'Berhasil Login Google!',
              isLogout: false,
            ),
          );

          await Future.delayed(const Duration(seconds: 2));
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Masuk'),
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
              const SizedBox(height: 20),
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
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Image.asset('logodomain.png', height: 100),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Selamat Datang!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Silakan masuk untuk melanjutkan pesanan Anda.',
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
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.blueGrey, fontSize: 14),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.email_outlined,
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
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.blueAccent,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.blueGrey,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
                    foregroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Lupa Password?',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
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
                        'Masuk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: Image.asset(
                  'assets/images/google_logo.png',
                  height: 24,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.g_mobiledata),
                ),
                label: const Text('Masuk dengan Google'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Belum punya akun?',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      ).then((value) {
                        if (value == true) {
                          if (!context.mounted) return;
                          Navigator.pop(
                            context,
                            true,
                          ); // Close login page if register succeeded
                        }
                      });
                    },
                    child: const Text(
                      'Daftar Sekarang',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
