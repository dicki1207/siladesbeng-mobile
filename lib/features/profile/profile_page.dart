import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/main_wrapper.dart';
import 'package:siladesbeng_mobile/features/profile/account/edit_profile_page.dart';
import 'package:siladesbeng_mobile/features/transaction/transaction_history_page.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:siladesbeng_mobile/features/auth/login_page.dart';
import 'package:siladesbeng_mobile/features/profile/info/about_page.dart';
import 'package:siladesbeng_mobile/features/profile/partnership/partnership_page.dart';
import 'package:siladesbeng_mobile/features/profile/info/help_faq_page.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';
import 'package:siladesbeng_mobile/features/profile/verification/verification_page.dart';
import 'package:siladesbeng_mobile/features/profile/mutation/domicile_transfer_page.dart';
import 'package:siladesbeng_mobile/widgets/premium_header.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoggedIn = false;
  String _name = 'Mushlihul Arif';
  String _email = 'mushlihul@example.com';
  String? _imagePath;
  String? _imageUrl;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
        });
      }
      return;
    }

    setState(() {
      _isLoggedIn = true;
      _name = prefs.getString('profile_name') ?? 'Mushlihul Arif';
      _email = prefs.getString('profile_email') ?? 'mushlihul@example.com';
      _imagePath = prefs.getString('profile_image');
      _imageUrl = prefs.getString('profile_image_url');
      _isVerified = prefs.getBool('is_verified') ?? false;
    });

    // Verifikasi token ke server di latar belakang
    try {
      final response = await http.get(
        Uri.parse('http://10.250.3.148:8000/api/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 401) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesi Anda telah berakhir. Silakan login kembali.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          _logout(context, forced: true);
        }
      } else if (response.statusCode == 200) {
        // Update local data with fresh data
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final user = data['data']['user'];
          await prefs.setString('profile_name', user['name'] ?? '');
          await prefs.setString('profile_email', user['email'] ?? '');
          if (data['data']['avatar_url'] != null) {
            await prefs.setString(
              'profile_image_url',
              data['data']['avatar_url'],
            );
          }
          if (user['nik'] != null) {
            await prefs.setBool('is_verified', true);
          } else {
            await prefs.setBool('is_verified', false);
          }

          if (mounted) {
            setState(() {
              _name = user['name'] ?? _name;
              _email = user['email'] ?? _email;
              _isVerified = user['nik'] != null;
              if (data['data']['avatar_url'] != null) {
                _imageUrl = data['data']['avatar_url'];
              }
            });
          }
        }
      }
    } catch (e) {
      // Biarkan jika gagal koneksi
    }
  }

  Future<void> _logout(BuildContext context, {bool forced = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('profile_name');
    await prefs.remove('profile_email');
    await prefs.remove('profile_image_url');
    await prefs.remove('profile_image');
    await prefs.remove('user_role');
    await prefs.remove('is_verified');
    if (!context.mounted) return;

    if (!forced) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AnimatedSuccessDialog(
          message: 'Sampai Jumpa!',
          isLogout: true,
        ),
      );
      await Future.delayed(const Duration(seconds: 2));
      if (!context.mounted) return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainWrapper()),
      (route) => false,
    );
  }

  Widget _buildDigitalKTP() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D253F),
            Color(0xFF19406B),
            Color(0xFF1E528D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D253F).withAlpha(120),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROVINSI JAWA BARAT',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'KABUPATEN BANDUNG',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withAlpha(35),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.greenAccent.withAlpha(120),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: Colors.greenAccent,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'TERVALIDASI AI',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              color: Colors.white.withAlpha(25),
              height: 1,
              thickness: 1,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ID WARGA TERDAFTAR',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'SLD-2026-8891',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'NAMA LENGKAP WARGA',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 75,
                height: 95,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withAlpha(180),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (_imagePath != null)
                      ? Image.file(
                          File(_imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.person_rounded,
                            size: 45,
                            color: Colors.white70,
                          ),
                        )
                      : (_imageUrl != null)
                      ? Image.network(
                          _imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.person_rounded,
                            size: 45,
                            color: Colors.white70,
                          ),
                        )
                      : const Icon(
                          Icons.person_rounded,
                          size: 45,
                          color: Colors.white70,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'WILAYAH DOMISILI RESMI',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'RT 02 / RW 01',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Top Header Profile
            PremiumHeader(
              bottomPadding: 15.0,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      ).then((_) => _loadProfile());
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                        child: ClipOval(
                          child: Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[200],
                            child: (_imagePath != null)
                                ? Image.file(
                                    File(_imagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.person,
                                      size: 45,
                                      color: Colors.grey,
                                    ),
                                  )
                                : (_imageUrl != null)
                                ? Image.network(
                                    _imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.person,
                                      size: 45,
                                      color: Colors.grey,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 45,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        !_isLoggedIn ? 'Tamu' : _name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      if (_isLoggedIn && _isVerified) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    !_isLoggedIn ? 'Silakan login terlebih dahulu' : _email,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium!.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoggedIn && !_isVerified)
                    GestureDetector(
                      onTap: () {
                        _showVerificationInvitation(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: Colors.orange[700],
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Lengkapi Data Diri',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (_isLoggedIn && _isVerified) ...[
              const SizedBox(height: 10),
              _buildDigitalKTP(),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FutureBuilder<SharedPreferences>(
                  future: SharedPreferences.getInstance(),
                  builder: (context, snapshot) {
                    final status = snapshot.data?.getString('transfer_status');
                    if (status == 'pending') {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(20),
                          border: Border.all(
                            color: Colors.orange.withAlpha(50),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.hourglass_empty,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Pemindahan Domisili Anda sedang diproses oleh admin.',
                                style: TextStyle(
                                  color: Colors.orange[800],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DomicileTransferPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text(
                          'Mutasi Domisili & Tarik Warga (Handshake)',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                          side: BorderSide(
                            color: Theme.of(context).primaryColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Menus - Modern Grouped Section Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    context,
                    'Aktivitas & Kemitraan',
                    Colors.blue[600]!,
                  ),
                  const SizedBox(height: 14),
                  _buildMenuGroup(
                    context,
                    [
                      _buildMenuTile(
                        context,
                        icon: Icons.receipt_long_rounded,
                        title: 'Riwayat Aktivitas',
                        subtitle: 'Lacak pesanan gas, sewa & laporan warga',
                        targetPage: const TransactionHistoryPage(),
                        iconColor: Colors.blue[600],
                        isFirst: true,
                        isLast: _isVerified, // Menjadi yang terakhir jika kemitraan disembunyikan
                      ),
                      if (!_isVerified)
                        _buildMenuTile(
                          context,
                          icon: Icons.handshake_rounded,
                          title: 'Gabung Kemitraan',
                          subtitle: 'Daftarkan desa Anda ke Sila-DesBeng',
                          targetPage: const PartnershipPage(),
                          iconColor: Colors.teal[600],
                          isFirst: false,
                          isLast: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    context,
                    'Pengaturan & Informasi',
                    Colors.green[600]!,
                  ),
                  const SizedBox(height: 14),
                  _buildMenuGroup(
                    context,
                    [
                      if (_isLoggedIn)
                        _buildMenuTile(
                          context,
                          icon: Icons.manage_accounts_rounded,
                          title: 'Edit Profil & PIN Keamanan',
                          subtitle: 'Ubah data diri, kata sandi, dan keamanan akun',
                          targetPage: const EditProfilePage(),
                          iconColor: Colors.green,
                          isFirst: true,
                          isLast: false,
                        ),
                      _buildMenuTile(
                        context,
                        icon: Icons.help_outline_rounded,
                        title: 'Pusat Bantuan & FAQ',
                        subtitle: 'Panduan penggunaan dan pertanyaan umum',
                        targetPage: const HelpFaqPage(),
                        iconColor: Colors.amber[800],
                        isFirst: !_isLoggedIn,
                        isLast: false,
                      ),
                      _buildMenuTile(
                        context,
                        icon: Icons.info_outline_rounded,
                        title: 'Tentang Sila-DesBeng',
                        subtitle: 'Versi aplikasi & informasi pengembang desa',
                        targetPage: const AboutPage(),
                        iconColor: Colors.indigo[600],
                        isFirst: false,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_isLoggedIn) {
                            _logout(context);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            ).then((value) {
                              if (value == true) {
                                _loadProfile();
                              }
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLoggedIn
                              ? Colors.white
                              : Theme.of(context).primaryColor,
                          foregroundColor: _isLoggedIn
                              ? Colors.redAccent
                              : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                            side: BorderSide(
                              color: _isLoggedIn
                                  ? Colors.redAccent
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                        ),
                        icon: Icon(
                          _isLoggedIn ? Icons.logout : Icons.login,
                          size: 20,
                        ),
                        label: Text(
                          _isLoggedIn ? 'Keluar' : 'Login / Daftar Akun',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 100), // Spacing for bottom nav
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    Color accentColor,
  ) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 20,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
        ),
      ],
    );
  }

  Widget _buildMenuGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.withAlpha(30),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? targetPage,
    Color? iconColor,
    required bool isFirst,
    required bool isLast,
  }) {
    final activeColor = iconColor ?? Theme.of(context).primaryColor;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(isFirst ? 18 : 0),
              bottom: Radius.circular(isLast ? 18 : 0),
            ),
            onTap: () async {
              if (targetPage != null) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => targetPage),
                );
                if (result == true) {
                  _loadProfile();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur dalam pengembangan')),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: activeColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: activeColor, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey,
                      size: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 64, right: 18),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey.withAlpha(30),
            ),
          ),
      ],
    );
  }
  void _showVerificationInvitation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  size: 80,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Buka Akses Penuh!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Yuk lengkapi data diri Anda untuk menikmati dan mengakses seluruh fitur serta unit layanan BUMDes dengan aman dan nyaman.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VerificationPage(),
                      ),
                    ).then((_) => _loadProfile());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mulai Lengkapi Data',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text('Nanti Saja'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
