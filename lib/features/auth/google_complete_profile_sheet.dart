import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';
import 'package:siladesbeng_mobile/core/verification_guard.dart';
import 'package:siladesbeng_mobile/services/firebase_messaging_service.dart';

class GoogleCompleteProfileSheet extends StatefulWidget {
  final User firebaseUser;
  final String? locationName;

  const GoogleCompleteProfileSheet({
    super.key,
    required this.firebaseUser,
    this.locationName,
  });

  @override
  State<GoogleCompleteProfileSheet> createState() =>
      _GoogleCompleteProfileSheetState();
}

class _GoogleCompleteProfileSheetState
    extends State<GoogleCompleteProfileSheet> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<dynamic> _kecamatanList = [];
  Map<String, dynamic>? _selectedKecamatan;
  Map<String, dynamic>? _selectedDesa;

  bool _isLoadingRegions = true;
  bool _isSubmitting = false;
  String? _regionError;

  @override
  void initState() {
    super.initState();
    _fetchRegions();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchRegions() async {
    setState(() {
      _isLoadingRegions = true;
      _regionError = null;
    });

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/kemitraan/regions'),
        headers: {'Accept': 'application/json'},
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'success' && data['data'] != null) {
          if (mounted) {
            setState(() {
              _kecamatanList = data['data'];
              _isLoadingRegions = false;
            });
          }
          return;
        }
      }
      throw Exception('Format data wilayah tidak sesuai');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRegions = false;
          _regionError = 'Gagal memuat data wilayah. Ketuk untuk coba lagi.';
        });
      }
    }
  }

  /// Membuka Modal Bottom Sheet pencarian cepat untuk memilih Kecamatan / Desa
  Future<void> _openSearchablePicker({
    required String title,
    required String searchHint,
    required List<dynamic> items,
    required String? currentSelectedId,
    required ValueChanged<Map<String, dynamic>> onSelected,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredItems = items.where((item) {
              final name = item['name']?.toString().toLowerCase() ?? '';
              return name.contains(searchQuery.toLowerCase().trim());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag Handle
                  SizedBox(height: 12.h),
                  Center(
                    child: Container(
                      width: 44.w,
                      height: 4.5.h,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white70 : Colors.grey.shade600,
                          ),
                          splashRadius: 20.r,
                        ),
                      ],
                    ),
                  ),

                  // Kolom Pencarian Cepat
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 12.h),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: TextField(
                        autofocus: false,
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            searchQuery = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: searchHint,
                          hintStyle: TextStyle(
                            fontSize: 13.sp,
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: isDark ? Colors.white54 : const Color(0xFF0EA5E9),
                            size: 20.sp,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 12.h,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Divider(height: 1),

                  // Daftar Item
                  Expanded(
                    child: filteredItems.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.w),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_off_outlined,
                                    size: 40.sp,
                                    color: isDark ? Colors.white24 : Colors.grey.shade400,
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Tidak ditemukan hasil untuk "$searchQuery"',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            itemCount: filteredItems.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (context, index) {
                              final item = filteredItems[index] as Map<String, dynamic>;
                              final isSelected =
                                  item['id'].toString() == currentSelectedId;

                              return InkWell(
                                onTap: () {
                                  onSelected(item);
                                  Navigator.pop(ctx);
                                },
                                borderRadius: BorderRadius.circular(12.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14.w,
                                    vertical: 13.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF0EA5E9).withAlpha(isDark ? 35 : 20)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 18.sp,
                                        color: isSelected
                                            ? const Color(0xFF0EA5E9)
                                            : (isDark
                                                ? Colors.white38
                                                : Colors.grey.shade400),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Text(
                                          item['name']?.toString() ?? '',
                                          style: TextStyle(
                                            fontSize: 13.5.sp,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? const Color(0xFF0EA5E9)
                                                : (isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1E293B)),
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 18.sp,
                                          color: const Color(0xFF0EA5E9),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitCompletion() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedKecamatan == null) {
      _showWarningSnackBar('Silakan pilih Kecamatan terlebih dahulu');
      return;
    }

    if (_selectedDesa == null) {
      _showWarningSnackBar('Silakan pilih Desa / Kelurahan');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/login/google'),
        headers: {'Accept': 'application/json'},
        body: {
          'email': widget.firebaseUser.email ?? '',
          'name': widget.firebaseUser.displayName ?? 'Google User',
          'google_id': widget.firebaseUser.uid,
          'phone': _phoneController.text.trim(),
          'region_id': _selectedDesa!['id'].toString(),
          'location_name': widget.locationName ?? _selectedDesa!['name']?.toString() ?? '',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data['status'] == 'success') {
          // Simpan session profile & auth token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['data']['token']);
          await prefs.setString(
            'profile_name',
            data['data']['user']['name'] ?? widget.firebaseUser.displayName ?? 'Google User',
          );
          await prefs.setString(
            'profile_email',
            data['data']['user']['email'] ?? widget.firebaseUser.email ?? '',
          );
          await prefs.setString(
            'user_role',
            data['data']['user']['role'] ?? 'warga',
          );
          await prefs.setBool(
            'is_verified',
            VerificationGuard.isVerifiedFromApi(data['data']['user']),
          );
          await prefs.remove('profile_image');
          if (widget.firebaseUser.photoURL != null) {
            await prefs.setString(
              'profile_image_url',
              widget.firebaseUser.photoURL!,
            );
          }

          // Sinkronisasi Token FCM Notifikasi
          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await FirebaseMessagingService.updateTokenToServer(fcmToken);
          }

          final desaName = _selectedDesa?['name']?.toString() ?? 'Desa Terkait';
          await prefs.setString('profile_desa', desaName);
          if (_selectedDesa?['id'] != null) {
            await prefs.setString('profile_region_id', _selectedDesa!['id'].toString());
          }

          if (mounted) {
            Navigator.pop(context, desaName); // Kembalikan nama desa
          }
          return;
        }
      }

      final msg = data['message'] ?? 'Gagal melengkapi data akun.';
      _showErrorSnackBar(msg);
    } catch (e) {
      _showErrorSnackBar('Terjadi kesalahan jaringan: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showWarningSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: keyboardHeight),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 25,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Drag Handle
                Center(
                  child: Container(
                    width: 44.w,
                    height: 4.5.h,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),

                // Close Button & Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 28), // balance alignment
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Mohon Isi Terlebih Dahulu',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17.5.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/google_logo.png',
                                width: 15.w,
                                height: 15.w,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Melanjutkan pendaftaran dengan Google',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context, false),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white60 : Colors.grey.shade500,
                      ),
                      splashRadius: 20.r,
                    ),
                  ],
                ),

                SizedBox(height: 14.h),

                // Info Akun Google yang Sedang Terpilih
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A).withAlpha(150)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17.r,
                        backgroundColor: const Color(0xFF0EA5E9).withAlpha(30),
                        backgroundImage: widget.firebaseUser.photoURL != null
                            ? CachedNetworkImageProvider(
                                widget.firebaseUser.photoURL!,
                              )
                            : null,
                        child: widget.firebaseUser.photoURL == null
                            ? Icon(
                                Icons.person,
                                size: 18.sp,
                                color: const Color(0xFF0EA5E9),
                              )
                            : null,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.firebaseUser.displayName ?? 'Pengguna Google',
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.firebaseUser.email ?? '',
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 14.h),

                // Form 1: Kabupaten Bengkalis (Terkunci / Locked)
                _buildLockedKabupatenField(isDark),

                SizedBox(height: 12.h),

                // Form 2 & 3: Kecamatan dan Desa
                if (_isLoadingRegions)
                  Container(
                    height: 95.h,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18.sp,
                            height: 18.sp,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0EA5E9),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Memuat data wilayah Bengkalis...',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_regionError != null)
                  InkWell(
                    onTap: _fetchRegions,
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(isDark ? 30 : 15),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.red.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.refresh_rounded, color: Colors.redAccent, size: 20.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              _regionError!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Column(
                    children: [
                      // Pemilih Kecamatan
                      _buildSelectorTile(
                        label: 'Kecamatan',
                        hint: 'Pilih Kecamatan',
                        selectedText: _selectedKecamatan != null
                            ? _selectedKecamatan!['name']?.toString()
                            : null,
                        icon: Icons.map_outlined,
                        isDark: isDark,
                        onTap: () {
                          _openSearchablePicker(
                            title: 'Pilih Kecamatan',
                            searchHint: 'Ketik nama kecamatan...',
                            items: _kecamatanList,
                            currentSelectedId: _selectedKecamatan?['id']?.toString(),
                            onSelected: (kec) {
                              setState(() {
                                _selectedKecamatan = kec;
                                _selectedDesa = null; // Reset desa saat kecamatan ganti
                              });
                            },
                          );
                        },
                      ),

                      SizedBox(height: 12.h),

                      // Pemilih Desa / Kelurahan
                      _buildSelectorTile(
                        label: 'Desa / Kelurahan',
                        hint: _selectedKecamatan == null
                            ? 'Pilih kecamatan dulu'
                            : 'Pilih Desa/Kelurahan',
                        selectedText: _selectedDesa != null
                            ? _selectedDesa!['name']?.toString()
                            : null,
                        icon: Icons.location_city_outlined,
                        isDark: isDark,
                        isEnabled: _selectedKecamatan != null,
                        onTap: () {
                          if (_selectedKecamatan == null) {
                            _showWarningSnackBar(
                              'Silakan pilih Kecamatan terlebih dahulu',
                            );
                            return;
                          }

                          final desas =
                              _selectedKecamatan!['children'] as List<dynamic>? ?? [];

                          _openSearchablePicker(
                            title: 'Pilih Desa/Kelurahan',
                            searchHint: 'Ketik nama desa atau kelurahan...',
                            items: desas,
                            currentSelectedId: _selectedDesa?['id']?.toString(),
                            onSelected: (desa) {
                              setState(() {
                                _selectedDesa = desa;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),

                SizedBox(height: 12.h),

                // Form 4: Nomor WhatsApp
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nomor WhatsApp',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nomor WhatsApp wajib diisi';
                          }
                          final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
                          if (clean.length < 8) {
                            return 'Nomor WhatsApp minimal 8 digit';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: 'Nomor WhatsApp (Contoh: 0812...)',
                          hintStyle: TextStyle(
                            fontSize: 12.5.sp,
                            color: isDark ? Colors.white38 : Colors.grey.shade400,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Icon(
                            Icons.phone_android_outlined,
                            size: 19.sp,
                            color: const Color(0xFF0EA5E9),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 13.h,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                // Tombol "Lanjutkan"
                SizedBox(
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitCompletion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            width: 22.sp,
                            height: 22.sp,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Lanjutkan',
                            style: TextStyle(
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockedKabupatenField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kabupaten',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F172A).withAlpha(120)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_outlined,
                size: 19.sp,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Kabupaten Bengkalis',
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : const Color(0xFF334155),
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline_rounded,
                size: 17.sp,
                color: isDark ? Colors.white30 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorTile({
    required String label,
    required String hint,
    required String? selectedText,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
    bool isEnabled = true,
  }) {
    final hasValue = selectedText != null && selectedText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
        SizedBox(height: 6.h),
        InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: !isEnabled
                  ? (isDark
                      ? const Color(0xFF0F172A).withAlpha(80)
                      : const Color(0xFFF1F5F9).withAlpha(150))
                  : (isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19.sp,
                  color: !isEnabled
                      ? (isDark ? Colors.white24 : Colors.grey.shade400)
                      : const Color(0xFF0EA5E9),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    hasValue ? selectedText : hint,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: hasValue
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : (isDark ? Colors.white38 : Colors.grey.shade400),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 24.sp,
                  color: !isEnabled
                      ? (isDark ? Colors.white24 : Colors.grey.shade400)
                      : (isDark ? Colors.white54 : Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
