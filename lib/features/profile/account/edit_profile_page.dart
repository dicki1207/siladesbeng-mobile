import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:siladesbeng_mobile/main_wrapper.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';
import 'package:siladesbeng_mobile/features/profile/account/change_password_page.dart';
import 'package:siladesbeng_mobile/features/profile/verification/verification_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  File? _imageFile;
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Read-only controllers for regions
  final TextEditingController _kecamatanController = TextEditingController(
    text: 'Belum ditentukan',
  );
  final TextEditingController _desaController = TextEditingController(
    text: 'Belum ditentukan',
  );
  final TextEditingController _rwController = TextEditingController(
    text: 'Belum ditentukan',
  );
  final TextEditingController _rtController = TextEditingController(
    text: 'Belum ditentukan',
  );

  String? _selectedGender;
  String _nik = '';
  bool _isVerified = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileFromApi();
  }

  Future<void> _fallbackToLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('profile_name') ?? 'Nama Pengguna';
      _emailController.text =
          prefs.getString('profile_email') ?? 'email@example.com';
      _usernameController.text = prefs.getString('profile_name') ?? 'Username';
      _avatarUrl = prefs.getString('profile_image_url');
      _isVerified = prefs.getBool('is_verified') ?? false;
      _nik = _isVerified ? '1403010101900001' : '';
    });
  }

  Future<void> _loadProfileFromApi() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (mounted) {
          _showError('Sesi Anda telah berakhir. Silakan login kembali.');
          _logout(forced: true);
        }
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.121.197.148:8000/api/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 401) {
        if (mounted) {
          _showError('Sesi Anda telah berakhir. Silakan login kembali.');
          _logout(forced: true);
        }
        return;
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final user = data['data']['user'];
          final region = data['data']['region_info'] ?? {};

          setState(() {
            _usernameController.text = user['username'] ?? '';
            _nameController.text = user['name'] ?? '';
            _emailController.text = user['email'] ?? '';
            _phoneController.text = user['phone'] ?? '';
            _addressController.text = user['address'] ?? '';
            _selectedGender = user['gender'];

            _kecamatanController.text =
                region['kecamatan'] ?? 'Belum ditentukan';
            _desaController.text = region['desa'] ?? 'Belum ditentukan';
            _rwController.text = region['rw'] ?? 'Belum ditentukan';
            _rtController.text = region['rt'] ?? 'Belum ditentukan';

            _avatarUrl = data['data']['avatar_url'];
            _nik = user['nik']?.toString() ?? '';
            _isVerified = _nik.isNotEmpty || user['is_verified'] == true;
          });
        }
      } else {
        await _fallbackToLocalData();
      }
    } catch (e) {
      await _fallbackToLocalData();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.121.197.148:8000/api/profile/update'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['name'] = _nameController.text;
      request.fields['phone'] = _phoneController.text;
      request.fields['address'] = _addressController.text;
      request.fields['rt'] = _rtController.text;
      request.fields['rw'] = _rwController.text;
      if (_selectedGender != null) {
        request.fields['gender'] = _selectedGender!;
      }

      if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('profile', _imageFile!.path),
        );
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = json.decode(responseData);

      if (response.statusCode == 401) {
        if (mounted) {
          _showError('Sesi Anda telah berakhir. Silakan login kembali.');
          _logout(forced: true);
        }
        return;
      }

      if (response.statusCode == 200 && data['status'] == 'success') {
        _showSuccess('Profil berhasil diperbarui');
        _loadProfileFromApi();
      } else {
        String errorMsg = data['message'] ?? 'Gagal menyimpan profil';
        if (data['errors'] != null) {
          errorMsg = (data['errors'] as Map<String, dynamic>).values.first[0]
              .toString();
        }
        _showError(errorMsg);
      }
    } catch (e) {
      _showError('Gagal terhubung ke server');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout({bool forced = false}) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final token = prefs.getString('auth_token');
      if (token != null) {
        await http.post(
          Uri.parse('http://10.121.197.148:8000/api/logout'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }
    } catch (_) {}

    await prefs.remove('auth_token');

    if (mounted) {
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
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainWrapper()),
        (route) => false,
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      _showError('Gagal memilih foto: $e');
    }
  }

  void _showFullScreenImage(ImageProvider imageProvider) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(10.w),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                panEnabled: true,
                boundaryMargin: EdgeInsets.all(20.w),
                minScale: 0.5,
                maxScale: 3.0,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10.h,
                right: 10.w,
                child: IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 30.sp,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildField({
    required String label,
    required Widget child,
    bool isLocked = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: 18.0.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isLocked)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 13.sp,
                      color: isDark ? Colors.white30 : Colors.grey[400],
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'Terkunci',
                      style: TextStyle(
                        fontSize: 10.5.sp,
                        color: isDark ? Colors.white30 : Colors.grey[400],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 8.h),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    bool enabled = true,
    IconData? prefixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isLocked = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: !enabled
            ? (isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : const Color(0xFFF1F5F9))
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark
              ? Colors.white10
              : (!enabled ? Colors.transparent : Colors.grey.shade300),
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: !enabled ? FontWeight.w600 : FontWeight.normal,
          color: isDark
              ? (!enabled ? Colors.white54 : Colors.white)
              : (!enabled ? const Color(0xFF64748B) : const Color(0xFF1E293B)),
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  size: 20.sp,
                  color: isDark ? Colors.white38 : Colors.grey[400],
                )
              : null,
          suffixIcon: isLocked
              ? Icon(
                  Icons.lock_outline_rounded,
                  size: 16.sp,
                  color: isDark ? Colors.white24 : Colors.grey[400],
                )
              : null,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 13.h,
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalKtpCard(bool isDark, Color primaryColor) {
    final hasNik = _nik.isNotEmpty;
    final isVerified = _isVerified || hasNik;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17.r),
        child: Stack(
          children: [
            // Watermark Logo
            Positioned(
              right: -10,
              bottom: isVerified ? -10 : 35,
              child: Opacity(
                opacity: isDark ? 0.04 : 0.06,
                child: Icon(
                  Icons.account_balance_rounded,
                  size: 130.sp,
                  color: primaryColor,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header KTP DIGITAL & BADGE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.credit_card_rounded,
                            size: 18.sp,
                            color: primaryColor,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'KTP DIGITAL',
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      // Status Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? primaryColor.withValues(alpha: 0.12)
                              : Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isVerified
                                ? primaryColor.withValues(alpha: 0.4)
                                : Colors.amber.shade600.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVerified
                                  ? Icons.verified_rounded
                                  : Icons.shield_outlined,
                              size: 13.sp,
                              color: isVerified
                                  ? primaryColor
                                  : Colors.amber.shade800,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              isVerified ? 'TERVERIFIKASI' : 'BELUM VERIFIKASI',
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.bold,
                                color: isVerified
                                    ? primaryColor
                                    : Colors.amber.shade900,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                  SizedBox(height: 14.h),

                  // 2. Data Card Body
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Foto Profil dengan Action Ganti Foto
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_imageFile != null) {
                                _showFullScreenImage(FileImage(_imageFile!));
                              } else if (_avatarUrl != null) {
                                _showFullScreenImage(NetworkImage(_avatarUrl!));
                              }
                            },
                            child: Container(
                              width: 78,
                              height: 98,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9.r),
                                child: _imageFile != null
                                    ? Image.file(
                                        _imageFile!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Icon(
                                          Icons.person_rounded,
                                          size: 40.sp,
                                          color: Colors.grey[400],
                                        ),
                                      )
                                    : (_avatarUrl != null
                                          ? Image.network(
                                              _avatarUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) => Icon(
                                                Icons.person_rounded,
                                                size: 40.sp,
                                                color: Colors.grey[400],
                                              ),
                                            )
                                          : Icon(
                                              Icons.person_rounded,
                                              size: 40.sp,
                                              color: Colors.grey[400],
                                            )),
                              ),
                            ),
                          ),
                          // Mini Floating Camera Button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16.r),
                              onTap: _pickImage,
                              child: Container(
                                padding: EdgeInsets.all(5.w),
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).cardColor,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.25,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 13.sp,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(width: 14.w),

                      // Informasi NIK, Nama, Alamat
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // NIK
                            Text(
                              'NIK',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: isVerified
                                    ? primaryColor.withValues(alpha: 0.08)
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                hasNik ? _nik : 'Belum diisi',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: hasNik ? 'monospace' : null,
                                  letterSpacing: hasNik ? 0.8 : 0,
                                  color: hasNik
                                      ? (isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B))
                                      : (isDark
                                            ? Colors.white38
                                            : Colors.grey[500]),
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),

                            // NAMA
                            Text(
                              'NAMA',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _nameController.text.isNotEmpty
                                        ? _nameController.text.toUpperCase()
                                        : 'WARGA DESA',
                                    style: TextStyle(
                                      fontSize: 12.5.sp,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isVerified) ...[
                                  SizedBox(width: 4.w),
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 14.sp,
                                    color: primaryColor,
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 8.h),

                            // ALAMAT
                            Text(
                              'ALAMAT',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'RT ${_rtController.text.isNotEmpty ? _rtController.text : '00'} / RW ${_rwController.text.isNotEmpty ? _rwController.text : '00'} - (Disensor)',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white60
                                    : Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // 3. Action Button (Jika Belum Verifikasi)
                  if (!isVerified) ...[
                    SizedBox(height: 14.h),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VerificationPage(),
                          ),
                        ).then((_) => _loadProfileFromApi());
                      },
                      borderRadius: BorderRadius.circular(10.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  size: 15.sp,
                                  color: primaryColor,
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  'Verifikasi KTP & Wajah Sekarang',
                                  style: TextStyle(
                                    fontSize: 11.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12.sp,
                              color: primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: isDark
              ? const Color(0xFF0F172A)
              : const Color(0xFF2563EB),
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                        : [const Color(0xFF2FA2F1), const Color(0xFF0284C7)],
                  ),
                ),
              ),
              // Glowing circle 1 (Top Right)
              Positioned(
                top: -30,
                right: -20,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(22),
                  ),
                ),
              ),
              // Glowing circle 2 (Bottom Left)
              Positioned(
                bottom: -25,
                left: -15,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(14),
                  ),
                ),
              ),
            ],
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18.sp,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profil & Data Diri',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17.sp,
                ),
              ),
              Text(
                'Kelola identitas, domisili & keamanan akun',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF090D16) : Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24.r),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
              ),
              child: TabBar(
                indicator: UnderlineTabIndicator(
                  borderSide: const BorderSide(
                    width: 3.5,
                    color: Color(0xFF2563EB),
                  ),
                  borderRadius: BorderRadius.circular(3.r),
                  insets: EdgeInsets.symmetric(horizontal: 16.w),
                ),
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: isDark
                    ? Colors.white60
                    : const Color(0xFF64748B),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5.sp,
                  letterSpacing: 0.2,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_rounded, size: 16.sp),
                        SizedBox(width: 6.w),
                        Text('Pribadi'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_rounded, size: 16.sp),
                        SizedBox(width: 6.w),
                        Text('Wilayah'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_rounded, size: 16.sp),
                        SizedBox(width: 6.w),
                        Text('Keamanan'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: _isLoading && _nameController.text.isEmpty
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : TabBarView(
                physics: const BouncingScrollPhysics(),
                children: [
                  // TAB 1: PRIBADI
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // KTP Digital Hero Card (dengan foto profil & ganti foto)
                        _buildDigitalKtpCard(isDark, primaryColor),

                        SizedBox(height: 24.h),

                        _buildField(
                          label: 'Nama Pengguna',
                          isLocked: true,
                          child: _buildTextField(
                            _usernameController,
                            enabled: false,
                            prefixIcon: Icons.alternate_email_rounded,
                            isLocked: true,
                          ),
                        ),
                        _buildField(
                          label: 'Nama Lengkap',
                          child: _buildTextField(
                            _nameController,
                            prefixIcon: Icons.person_outline_rounded,
                          ),
                        ),
                        _buildField(
                          label: 'Alamat Email',
                          isLocked: true,
                          child: _buildTextField(
                            _emailController,
                            enabled: false,
                            prefixIcon: Icons.mail_outline_rounded,
                            isLocked: true,
                          ),
                        ),
                        _buildField(
                          label: 'Nomor Telepon / WhatsApp',
                          child: _buildTextField(
                            _phoneController,
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        _buildField(
                          label: 'Jenis Kelamin',
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedGender,
                                isExpanded: true,
                                hint: Text(
                                  'Pilih Jenis Kelamin',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.grey[500],
                                  ),
                                ),
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: primaryColor,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'laki-laki',
                                    child: Text('Laki-laki'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'perempuan',
                                    child: Text('Perempuan'),
                                  ),
                                ],
                                onChanged: (val) =>
                                    setState(() => _selectedGender = val),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 80.h),
                      ],
                    ),
                  ),

                  // TAB 2: WILAYAH
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Domisili & Wilayah',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 20.h),

                        _buildField(
                          label: 'Alamat Lengkap (Jalan / Nomor Rumah)',
                          child: _buildTextField(
                            _addressController,
                            prefixIcon: Icons.location_on_outlined,
                            maxLines: 2,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                label: 'Kecamatan',
                                isLocked: true,
                                child: _buildTextField(
                                  _kecamatanController,
                                  enabled: false,
                                  isLocked: true,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildField(
                                label: 'Desa / Kelurahan',
                                isLocked: true,
                                child: _buildTextField(
                                  _desaController,
                                  enabled: false,
                                  isLocked: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                label: 'RW',
                                child: _buildTextField(
                                  _rwController,
                                  enabled: true,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildField(
                                label: 'RT',
                                child: _buildTextField(
                                  _rtController,
                                  enabled: true,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 80.h),
                      ],
                    ),
                  ),

                  // TAB 3: KEAMANAN
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Keamanan & Akses Akun',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Kelola kata sandi dan keamanan akun Anda untuk melindungi data pribadi.',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 20.h),

                        // Card 1: Kata Sandi
                        _buildSecurityCard(
                          context,
                          icon: Icons.lock_rounded,
                          iconColor: primaryColor,
                          title: 'Kata Sandi Login',
                          subtitle: 'Diperbarui secara berkala untuk keamanan',
                          actionLabel: 'Ubah Sandi',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChangePasswordPage(),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 80.h),
                      ],
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _isLoading
                ? SizedBox(
                    height: 50,
                    child: Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onTap,
    Widget? trailingWidget,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: iconColor, size: 22.sp),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailingWidget != null)
                  trailingWidget
                else if (actionLabel != null)
                  Row(
                    children: [
                      Text(
                        actionLabel,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12.sp,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _kecamatanController.dispose();
    _desaController.dispose();
    _rwController.dispose();
    _rtController.dispose();
    super.dispose();
  }
}
