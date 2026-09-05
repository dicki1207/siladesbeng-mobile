import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
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
import 'package:siladesbeng_mobile/features/profile/verification/verification_page.dart';
import 'package:siladesbeng_mobile/features/profile/mutation/domicile_transfer_page.dart';
import 'package:siladesbeng_mobile/features/admin/admin_portal_page.dart';
import 'package:siladesbeng_mobile/features/profile/account/change_password_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ShowcaseView _showcaseView;
  final GlobalKey _keyVerification = GlobalKey();
  final GlobalKey _keyActivity = GlobalKey();
  final GlobalKey _keyRtRw = GlobalKey();
  final GlobalKey _keyEditProfile = GlobalKey();

  bool _isLoggedIn = false;
  String _name = 'Warga Desa';
  String _email = 'warga@desa.id';
  String _nik = '';
  String _address = '';
  String? _imagePath;
  String? _imageUrl;
  bool _isVerified = false;
  String _userRole = 'warga';

  @override
  void initState() {
    super.initState();
    _showcaseView = ShowcaseView.register(scope: 'profile');
    _loadProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartShowcase(
);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<GlobalKey> get _activeShowcaseKeys {
    List<GlobalKey> keys = [];
    if (_isLoggedIn) {
      keys.addAll([_keyVerification, _keyActivity]);
      if (_userRole == 'rt' || _userRole == 'rw' || _userRole == 'admin') {
        keys.add(_keyRtRw);
      }
      keys.add(_keyEditProfile);
    } else {
      keys.add(_keyActivity);
      if (_userRole == 'rt' || _userRole == 'rw' || _userRole == 'admin') {
        keys.add(_keyRtRw);
      }
    }
    return keys;
  }

  Future<void> _checkAndStartShowcase(
) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenTour = prefs.getBool('has_seen_profile_tour') ?? false;
      if (!hasSeenTour && mounted) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          _showcaseView.startShowCase(_activeShowcaseKeys);
          await prefs.setBool('has_seen_profile_tour', true);
        }
      }
    } catch (e) {
      debugPrint('Profile showcase error: $e');
    }
  }

  void _replayTour() {
    _showcaseView.startShowCase(_activeShowcaseKeys);
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
      _userRole = prefs.getString('user_role') ?? 'warga';
    });

    // Verifikasi token ke server di latar belakang
    try {
      final response = await http.get(
        Uri.parse('http://10.121.197.148:8000/api/user'),
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

          final isVerified =
              (user['verification_status'] == 'verified') ||
              (user['nik'] != null && user['nik'].toString().isNotEmpty) ||
              (user['is_verified'] == true);

          final userNik =
              user['nik']?.toString() ?? (isVerified ? '1403010101900001' : '');
          final userAddress =
              (user['address'] != null &&
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
          await prefs.setString('user_role', user['role'] ?? 'warga');

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
              _userRole = user['role'] ?? _userRole;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Anda telah berhasil keluar dari akun',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13.5),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF334155),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainWrapper()),
      (route) => false,
    );
  }

  String _maskNik(String nik) {
    final cleanNik = (nik.isEmpty ? '1403010101900001' : nik).replaceAll(
      RegExp(r'\s+'),
      '',
    );
    if (cleanNik.length >= 8) {
      return '${cleanNik.substring(0, 4)}********${cleanNik.substring(cleanNik.length - 4)}';
    }
    return cleanNik;
  }

  void _showDigitalKtpModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 100 : 40),
                blurRadius: 25,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modal Drag Handle
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              SizedBox(height: 18.h),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withAlpha(15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.badge_outlined,
                          color: Color(0xFF2563EB),
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KTP Digital Warga',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Identitas Resmi Kependudukan',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 18.h),

              // The Digital KTP Card
              _buildKtpCardContent(isDark),

              SizedBox(height: 20.h),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    foregroundColor: isDark
                        ? Colors.white
                        : const Color(0xFF334155),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Tutup Kartu',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKtpCardContent(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha(20)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17.r),
        child: Stack(
          children: [
            // ── Watermark: Logo Sila-DesBeng (Top Right) & Background Patterns ──
            Positioned(
              top: 4.h,
              right: 8.w,
              child: Opacity(
                opacity: isDark ? 0.20 : 0.32,
                child: Image.asset(
                  'logodomain.png',
                  width: 64.w,
                  height: 64.w,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              right: -15,
              bottom: -10,
              child: Icon(
                Icons.shield_outlined,
                size: 120.sp,
                color: isDark
                    ? Colors.white.withAlpha(8)
                    : const Color(0xFF2563EB).withAlpha(12),
              ),
            ),
            Positioned(
              left: -20,
              top: -15,
              child: Icon(
                Icons.verified_user_outlined,
                size: 80.sp,
                color: isDark
                    ? Colors.white.withAlpha(6)
                    : const Color(0xFF2563EB).withAlpha(8),
              ),
            ),

            // ── Main Content ──
            Padding(
              padding: EdgeInsets.all(18.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Bar: KTP DIGITAL + TERVERIFIKASI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(5.w),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2563EB).withAlpha(30)
                                  : const Color(0xFF2563EB).withAlpha(15),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.badge_rounded,
                              color: isDark
                                  ? const Color(0xFF60A5FA)
                                  : const Color(0xFF2563EB),
                              size: 16.sp,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'KTP DIGITAL',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withAlpha(20),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: const Color(0xFF10B981).withAlpha(60),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF10B981),
                              size: 12.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'TERVERIFIKASI',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Divider(
                    color: isDark
                        ? Colors.white.withAlpha(15)
                        : const Color(0xFFE2E8F0),
                    height: 1,
                  ),
                  SizedBox(height: 14.h),

                  // Content Row: Photo Left + Info Right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Foto Avatar KTP (3:4 ratio)
                      Container(
                        width: 76,
                        height: 100,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withAlpha(25)
                                : const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11.r),
                          child: (_imagePath != null)
                              ? Image.file(
                                  File(_imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(
                                    Icons.person,
                                    size: 40.sp,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey[400],
                                  ),
                                )
                              : (_imageUrl != null)
                              ? CachedNetworkImage(
                                  imageUrl: _imageUrl!,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 500,
                                  placeholder: (ctx, url) => Container(color: Colors.grey[200]),
                                  errorWidget: (ctx, url, err) => const Icon(Icons.broken_image, color: Colors.grey),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 40.sp,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey[400],
                                ),
                        ),
                      ),

                      SizedBox(width: 14.w),

                      // Data Warga
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // NIK
                            Text(
                              'NIK',
                              style: TextStyle(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                            SizedBox(height: 3.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withAlpha(10)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withAlpha(15)
                                      : const Color(0xFFE2E8F0),
                                  width: 0.8,
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _maskNik(_nik),
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 10.h),

                            // NAMA
                            Text(
                              'NAMA LENGKAP',
                              style: TextStyle(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 4.w),
                                Icon(
                                  Icons.verified,
                                  color: Color(0xFF10B981),
                                  size: 14.sp,
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),

                            // ALAMAT
                            Text(
                              'ALAMAT DOMISILI',
                              style: TextStyle(
                                fontSize: 9.5.sp,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${_address.isNotEmpty ? _address : "RT 01 / RW 02, Bengkalis"} - (Disensor)',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF475569),
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
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard({EdgeInsetsGeometry? margin}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20.r),
          onTap: () {
            if (_isVerified) {
              _showDigitalKtpModal(context);
            } else {
              _showVerificationInvitation(context);
            }
          },
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Avatar with Verified badge overlay
                Stack(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isVerified
                              ? const Color(0xFF2563EB)
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: (_imagePath != null)
                            ? Image.file(
                                File(_imagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    Icon(Icons.person, size: 30.sp),
                              )
                            : (_imageUrl != null)
                            ? CachedNetworkImage(
                                imageUrl: _imageUrl!,
                                fit: BoxFit.cover,
                                memCacheWidth: 500,
                                placeholder: (ctx, url) => Container(color: Colors.grey[200]),
                                errorWidget: (ctx, url, err) => const Icon(Icons.broken_image, color: Colors.grey),
                              )
                            : Icon(Icons.person, size: 30.sp),
                      ),
                    ),
                    if (_isVerified)
                      Positioned(
                        bottom: 0.h,
                        right: 0.w,
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.verified,
                            color: Color(0xFF2563EB),
                            size: 18.sp,
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(width: 14.w),

                // Name, Email, and KTP Pill
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _name,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        _email,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),

                      // Action Badge
                      if (_isVerified)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withAlpha(15),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: const Color(0xFF2563EB).withAlpha(50),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                size: 13.sp,
                                color: Color(0xFF2563EB),
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                'KTP Digital Terverifikasi',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 9.sp,
                                color: Color(0xFF2563EB),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withAlpha(20),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withAlpha(60),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 13.sp,
                                color: Color(0xFFD97706),
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                'Belum Terverifikasi • Klik Disini',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeroHeader(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            const Color(0xFF0284C7), // Deep sky blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Lingkaran dekoratif 1
          Positioned(
            top: -35,
            right: -25,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Lingkaran dekoratif 2
          Positioned(
            bottom: -25,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          // Konten Header
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              topPadding + 16,
              20,
              _isLoggedIn
                  ? 80
                  : 24, // Extra space at bottom so card doesn't cover title
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Profil Saya',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Kabupaten Bengkalis',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.help_outline_rounded,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                      tooltip: 'Panduan Halaman',
                      onPressed: _replayTour,
                    ),
                    SizedBox(width: 4.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isVerified
                                ? Icons.verified_rounded
                                : Icons.person_outline_rounded,
                            color: Colors.white,
                            size: 15.sp,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            _isVerified ? 'Terverifikasi' : 'Warga',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildTopHeroHeader(context),
                if (_isLoggedIn)
                  Positioned(
                    bottom: -45,
                    left: 20.w,
                    right: 20.w,
                    child: Showcase(
                      titleTextStyle: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.2),
                      descTextStyle: TextStyle(fontSize: 12.0.sp, fontWeight: FontWeight.w400, color: Color(0xFF475569), height: 1.35),
                      key: _keyVerification,
                      title: 'Verifikasi & KTP Digital',
                      description:
                          'Lengkapi data NIK untuk verifikasi akun, membuka fitur RT/RW, serta mengakses KTP Digital resmi.',
                      child: _buildProfileHeaderCard(margin: EdgeInsets.zero),
                    ),
                  ),
              ],
            ),

            if (_isLoggedIn) ...[
              const SizedBox(
                height: 55,
              ), // Space compensation for the positioned card
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    if (_isVerified) ...[
                      FutureBuilder<SharedPreferences>(
                        future: SharedPreferences.getInstance(),
                        builder: (context, snapshot) {
                          final status = snapshot.data?.getString(
                            'transfer_status',
                          );
                          if (status == 'pending') {
                            return Container(
                              margin: EdgeInsets.only(top: 10.h),
                              padding: EdgeInsets.symmetric(
                                vertical: 10.h,
                                horizontal: 14.w,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(20),
                                border: Border.all(
                                  color: Colors.orange.withAlpha(50),
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.hourglass_empty,
                                    color: Colors.orange,
                                    size: 18.sp,
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      'Pemindahan Domisili Anda sedang diproses oleh admin.',
                                      style: TextStyle(
                                        color: Colors.orange[800],
                                        fontSize: 12.sp,
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
                    ],
                  ],
                ),
              ),
            ] else ...[
              SizedBox(height: 16.h),
            ],

            // Menus - Modern Grouped Section Cards
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    context,
                    'Aktivitas & Kemitraan',
                  ),
                  SizedBox(height: 12.h),
                  _buildMenuGroup(context, [
                    Showcase(
                      titleTextStyle: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.2),
                      descTextStyle: TextStyle(fontSize: 12.0.sp, fontWeight: FontWeight.w400, color: Color(0xFF475569), height: 1.35),
                      key: _keyActivity,
                      title: 'Riwayat Aktivitas',
                      description:
                          'Cek status pelaporan pengaduan, penyewaan fasilitas/alat BUMDes, serta riwayat belanja Anda.',
                      child: _buildMenuTile(
                        context,
                        icon: Icons.receipt_long_rounded,
                        title: 'Riwayat Aktivitas',
                        targetPage: const TransactionHistoryPage(),
                        isFirst: true,
                        isLast: false,
                      ),
                    ),
                    if (_userRole == 'rt' || _userRole == 'rw' || _userRole == 'admin')
                      Showcase(
                        titleTextStyle: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.2),
                        descTextStyle: TextStyle(fontSize: 12.0.sp, fontWeight: FontWeight.w400, color: Color(0xFF475569), height: 1.35),
                        key: _keyRtRw,
                        title: 'Portal Pengurus RT / RW',
                        description:
                            'Layanan administrasi dan persetujuan permohonan warga bagi pengurus RT dan RW.',
                        child: _buildMenuTile(
                          context,
                          icon: Icons.admin_panel_settings_rounded,
                          title: 'Portal Pengurus RT / RW',
                          subtitle: 'Layanan administrasi & pengurus wilayah',
                          targetPage: const AdminPortalPage(),
                          isFirst: false,
                          isLast: false,
                        ),
                      ),
                    if (_isVerified)
                      _buildMenuTile(
                        context,
                        icon: Icons.swap_horiz_rounded,
                        title: 'Mutasi Domisili',
                        subtitle: 'Handshake data kependudukan',
                        targetPage: const DomicileTransferPage(),
                        isFirst: false,
                        isLast: true,
                      ),
                    if (!_isVerified)
                      _buildMenuTile(
                        context,
                        icon: Icons.handshake_rounded,
                        title: 'Gabung Kemitraan',
                        targetPage: const PartnershipPage(),
                        isFirst: false,
                        isLast: true,
                      ),
                  ]),
                  SizedBox(height: 24.h),
                  _buildSectionHeader(
                    context,
                    'Pengaturan & Informasi',
                  ),
                  SizedBox(height: 14.h),
                  _buildMenuGroup(context, [
                    if (_isLoggedIn) ...[
                      Showcase(
                        titleTextStyle: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.2),
                        descTextStyle: TextStyle(fontSize: 12.0.sp, fontWeight: FontWeight.w400, color: Color(0xFF475569), height: 1.35),
                        key: _keyEditProfile,
                        title: 'Edit Profil & Data Diri',
                        description: 'Ubah informasi identitas dan domisili Anda.',
                        child: _buildMenuTile(
                          context,
                          icon: Icons.manage_accounts_rounded,
                          title: 'Edit Profil & Data Diri',
                          targetPage: const EditProfilePage(),
                          isFirst: true,
                          isLast: false,
                        ),
                      ),
                      _buildMenuTile(
                        context,
                        icon: Icons.shield_rounded,
                        title: 'Keamanan & Kata Sandi',
                        targetPage: const ChangePasswordPage(),
                        isFirst: false,
                        isLast: false,
                      ),
                    ],
                    _buildMenuTile(
                      context,
                      icon: Icons.help_outline_rounded,
                      title: 'Pusat Bantuan & FAQ',
                      targetPage: const HelpFaqPage(),
                      isFirst: !_isLoggedIn,
                      isLast: false,
                    ),
                    _buildMenuTile(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: 'Tentang Sila-DesBeng',
                      targetPage: const AboutPage(),
                      isFirst: false,
                      isLast: true,
                    ),

                  ]),
                  SizedBox(height: 40.h),

                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_isLoggedIn) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _logout(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                    child: const Text('Keluar'),
                                  ),
                                ],
                              ),
                            );
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
                            borderRadius: BorderRadius.circular(25.r),
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
                          size: 20.sp,
                        ),
                        label: Text(
                          _isLoggedIn ? 'Keluar' : 'Login / Daftar Akun',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 100.h), // Spacing for bottom nav
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
    String title, [
    Color? accentColor,
  ]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accentColor ?? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7));
    return Row(
      children: [
        Container(
          width: 5,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6.r),
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 16.sp,
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
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.withAlpha(30), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = iconColor ?? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7));
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
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: activeColor.withAlpha(isDark ? 35 : 22),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(icon, color: activeColor, size: 22.sp),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium!
                              .copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: 2.h),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey,
                      size: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: EdgeInsets.only(left: 64.w, right: 18.w),
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
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.r),
              topRight: Radius.circular(30.r),
            ),
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              SizedBox(height: 30.h),
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  size: 80.sp,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'Buka Akses Penuh!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Yuk lengkapi data diri Anda untuk menikmati dan mengakses seluruh fitur serta unit layanan BUMDes dengan aman dan nyaman.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              SizedBox(height: 32.h),
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
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Mulai Lengkapi Data',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text('Nanti Saja'),
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }
}
