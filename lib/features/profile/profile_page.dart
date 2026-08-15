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
import 'package:siladesbeng_mobile/features/admin/admin_portal_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoggedIn = false;
  String _name = 'Warga Desa';
  String _email = 'warga@desa.id';
  String _nik = '';
  String _address = '';
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
      _name = prefs.getString('profile_name') ?? 'Warga Desa';
      _email = prefs.getString('profile_email') ?? 'warga@desa.id';
      _nik = prefs.getString('profile_nik') ?? '';
      _address = prefs.getString('profile_address') ?? '';
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
          final region = data['data']['region_info'] ?? {};

          final isVerified = (user['verification_status'] == 'verified') ||
              (user['nik'] != null && user['nik'].toString().isNotEmpty) ||
              (user['is_verified'] == true);

          final userNik = user['nik']?.toString() ??
              (isVerified ? '1403010101900001' : '');
          final userAddress = (user['address'] != null &&
                  user['address'] != '-' &&
                  user['address'].toString().isNotEmpty)
              ? user['address']
              : (region['desa'] != null && region['desa'] != 'Belum ditentukan'
                  ? 'RT ${user['rt'] ?? '01'} / RW ${user['rw'] ?? '02'}, ${region['desa']}'
                  : 'RT ${user['rt'] ?? '01'} / RW ${user['rw'] ?? '02'}');

          await prefs.setString('profile_name', user['name'] ?? '');
          await prefs.setString('profile_email', user['email'] ?? '');
          await prefs.setString('profile_nik', userNik);
          await prefs.setString('profile_address', userAddress);
          await prefs.setBool('is_verified', isVerified);

          if (data['data']['avatar_url'] != null) {
            await prefs.setString(
              'profile_image_url',
              data['data']['avatar_url'],
            );
          }

          if (mounted) {
            setState(() {
              _name = user['name'] ?? _name;
              _email = user['email'] ?? _email;
              _nik = userNik;
              _address = userAddress;
              _isVerified = isVerified;
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

  String _maskNik(String nik) {
    final cleanNik =
        (nik.isEmpty ? '1403010101900001' : nik).replaceAll(RegExp(r'\s+'), '');
    if (cleanNik.length >= 8) {
      return '${cleanNik.substring(0, 4)}********${cleanNik.substring(cleanNik.length - 4)}';
    }
    return cleanNik;
  }

  Widget _buildDigitalKTP() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isVerified) {
      // Tampilan Belum Terverifikasi (Persis seperti Web)
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF451A03).withAlpha(80)
              : const Color(0xFFFEFCE8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? const Color(0xFFF59E0B).withAlpha(80)
                : const Color(0xFFFEF08A),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 6),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFFD97706),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Identitas Belum Terverifikasi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Anda belum dapat mengakses layanan publik (seperti meminjam fasilitas) sebelum memverifikasi KTP & Wajah.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark
                    ? const Color(0xFFFCD34D).withAlpha(200)
                    : const Color(0xFFB45309),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () {
                  _showVerificationInvitation(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAB308),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Verifikasi Sekarang',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Tampilan KTP Digital Terverifikasi (Ultra-Spacious & Elegan)
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFF1E40AF),
        gradient: isDark
            ? const LinearGradient(
                colors: [
                  Color(0xFF1E293B),
                  Color(0xFF0F172A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [
                  Color(0xFF1E40AF),
                  Color(0xFF2563EB),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? const Color(0xFF3B82F6).withAlpha(120)
              : const Color(0xFF93C5FD).withAlpha(150),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E40AF).withAlpha(isDark ? 60 : 40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar: KTP DIGITAL + TERVERIFIKASI (Identik dengan Web)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'KTP DIGITAL',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withAlpha(70),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'TERVERIFIKASI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              color: Colors.white.withAlpha(35),
              height: 1,
            ),
            const SizedBox(height: 14),

            // Content Row: Photo Left + Info Right
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Foto Avatar KTP (3:4 ratio)
                Container(
                  width: 76,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF93C5FD),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (_imagePath != null)
                        ? Image.file(
                            File(_imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey,
                            ),
                          )
                        : (_imageUrl != null)
                            ? Image.network(
                                _imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              ),
                  ),
                ),

                const SizedBox(width: 14),

                // Data Warga
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // NIK
                      Text(
                        'NIK',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.white.withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(40),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _maskNik(_nik),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // NAMA
                      Text(
                        'NAMA LENGKAP',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.white.withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF38BDF8),
                            size: 14,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ALAMAT
                      Text(
                        'ALAMAT DOMISILI',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.white.withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_address.isNotEmpty ? _address : "RT 01 / RW 02, Bengkalis"} - (Disensor)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withAlpha(210),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Clean Minimal Header Bar
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profil Saya',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          !_isLoggedIn
                              ? 'Silakan login untuk mengakses layanan'
                              : _email,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    if (_isLoggedIn)
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfilePage(),
                              ),
                            ).then((_) => _loadProfile());
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (_isLoggedIn) ...[
              _buildDigitalKTP(),
              if (_isVerified) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FutureBuilder<SharedPreferences>(
                    future: SharedPreferences.getInstance(),
                    builder: (context, snapshot) {
                      final status =
                          snapshot.data?.getString('transfer_status');
                      if (status == 'pending') {
                        return Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 14,
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
                                size: 18,
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
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ],

            const SizedBox(height: 16),

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
                  const SizedBox(height: 12),
                  _buildMenuGroup(
                    context,
                    [
                      _buildMenuTile(
                        context,
                        icon: Icons.receipt_long_rounded,
                        title: 'Riwayat Aktivitas',
                        targetPage: const TransactionHistoryPage(),
                        iconColor: Colors.blue[600],
                        isFirst: true,
                        isLast: false,
                      ),
                      _buildMenuTile(
                        context,
                        icon: Icons.admin_panel_settings_rounded,
                        title: 'Portal Pengurus RT / RW',
                        subtitle: 'Layanan administrasi & pengurus wilayah',
                        targetPage: const AdminPortalPage(),
                        iconColor: Colors.teal[600],
                        isFirst: false,
                        isLast: false,
                      ),
                      if (_isVerified)
                        _buildMenuTile(
                          context,
                          icon: Icons.swap_horiz_rounded,
                          title: 'Mutasi Domisili & Tarik Warga',
                          subtitle: 'Handshake data kependudukan',
                          targetPage: const DomicileTransferPage(),
                          iconColor: Colors.indigo[600],
                          isFirst: false,
                          isLast: true,
                        ),
                      if (!_isVerified)
                        _buildMenuTile(
                          context,
                          icon: Icons.handshake_rounded,
                          title: 'Gabung Kemitraan',
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
                          targetPage: const EditProfilePage(),
                          iconColor: Colors.green,
                          isFirst: true,
                          isLast: false,
                        ),
                      _buildMenuTile(
                        context,
                        icon: Icons.help_outline_rounded,
                        title: 'Pusat Bantuan & FAQ',
                        targetPage: const HelpFaqPage(),
                        iconColor: Colors.amber[800],
                        isFirst: !_isLoggedIn,
                        isLast: false,
                      ),
                      _buildMenuTile(
                        context,
                        icon: Icons.info_outline_rounded,
                        title: 'Tentang Sila-DesBeng',
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
        borderRadius: BorderRadius.circular(16),
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
    String? subtitle,
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
              top: Radius.circular(isFirst ? 16 : 0),
              bottom: Radius.circular(isLast ? 16 : 0),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
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
