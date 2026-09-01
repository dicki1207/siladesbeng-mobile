import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';
import 'package:siladesbeng_mobile/features/profile/verification/verification_page.dart';
import 'package:siladesbeng_mobile/main_wrapper.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const Color _primaryBlue = Color(0xFF2FA2F1);

  File? _imageFile;
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Region controllers
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfileFromApi();
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

  Future<void> _fallbackToLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nameController.text = prefs.getString('profile_name') ?? 'Nama Pengguna';
      _emailController.text = prefs.getString('profile_email') ?? 'email@example.com';
      _usernameController.text = prefs.getString('profile_name') ?? 'Username';
      _avatarUrl = prefs.getString('profile_image_url');
      _isVerified = prefs.getBool('is_verified') ?? false;
      _nik = prefs.getString('profile_nik') ?? (_isVerified ? '1403010101900001' : '');
    });
  }

  Future<void> _loadProfileFromApi() async {
    setState(() => _isLoading = true);

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
        Uri.parse('${ApiConfig.baseUrl}/api/user'),
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

          if (mounted) {
            setState(() {
              _usernameController.text = user['username'] ?? '';
              _nameController.text = user['name'] ?? '';
              _emailController.text = user['email'] ?? '';
              _phoneController.text = user['phone'] ?? '';
              _addressController.text = user['address'] ?? '';
              _selectedGender = user['gender'];

              _kecamatanController.text = region['kecamatan'] ?? 'Belum ditentukan';
              _desaController.text = region['desa'] ?? 'Belum ditentukan';
              _rwController.text = region['rw'] ?? 'Belum ditentukan';
              _rtController.text = region['rt'] ?? 'Belum ditentukan';

              _avatarUrl = data['data']['avatar_url'];
              _nik = user['nik']?.toString() ?? '';
              _isVerified = _nik.isNotEmpty || user['is_verified'] == true;
            });
          }
        }
      } else {
        await _fallbackToLocalData();
      }
    } catch (_) {
      await _fallbackToLocalData();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return;

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/profile/update'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['name'] = _nameController.text.trim();
      request.fields['phone'] = _phoneController.text.trim();
      request.fields['address'] = _addressController.text.trim();
      request.fields['rt'] = _rtController.text.trim();
      request.fields['rw'] = _rwController.text.trim();
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
        // Update local prefs
        await prefs.setString('profile_name', _nameController.text.trim());
        _showSuccess('Profil berhasil diperbarui');
        _loadProfileFromApi();
      } else {
        String errorMsg = data['message'] ?? 'Gagal menyimpan profil';
        if (data['errors'] != null) {
          errorMsg = (data['errors'] as Map<String, dynamic>).values.first[0].toString();
        }
        _showError(errorMsg);
      }
    } catch (e) {
      _showError('Gagal terhubung ke server');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _logout({bool forced = false}) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final token = prefs.getString('auth_token');
      if (token != null) {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/logout'),
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

  void _showImageSourcePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(isDark ? 80 : 100),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Ganti Foto Profil',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Pilih metode pengambilan foto identitas Anda',
              style: TextStyle(
                fontSize: 11.5.sp,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: _buildPickerOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    color: _primaryBlue,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildPickerOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri Foto',
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 30 : 15),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 26.sp, color: color),
            SizedBox(height: 6.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (_) {
      _showError('Gagal mengakses kamera/galeri');
    }
  }

  void _showFullScreenImage(ImageProvider imageProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(16.w),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.w),
                child: IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 26.sp,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18.sp),
            SizedBox(width: 8.w),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  String _maskNik(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return 'Belum terverifikasi';
    if (clean.length >= 8) {
      return '${clean.substring(0, 4)}••••••••${clean.substring(clean.length - 4)}';
    }
    return clean;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFF2FA2F1),
        elevation: 0,
        scrolledUnderElevation: 2,
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
            // Glowing ambient light circle 1 (Top Right)
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(22),
                ),
              ),
            ),
            // Glowing ambient light circle 2 (Bottom Left)
            Positioned(
              bottom: -25,
              left: -15,
              child: Container(
                width: 90.w,
                height: 90.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(14),
                ),
              ),
            ),
          ],
        ),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Profil & Data Diri',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16.5.sp,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Kelola identitas dan data domisili warga',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11.sp,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: _isLoading && _nameController.text.isEmpty
          ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 30.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HERO CARD: KTP DIGITAL & AVATAR PICKER
                  _buildDigitalKtpHeroCard(isDark),

                  SizedBox(height: 20.h),

                  // SECTION 1: INFORMASI PRIBADI
                  _buildSectionHeader(
                    title: 'Informasi Data Pribadi',
                    subtitle: 'Data identitas akun warga pengguna',
                    isDark: isDark,
                  ),
                  SizedBox(height: 12.h),

                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildFormField(
                          label: 'Nama Pengguna (Username)',
                          isLocked: true,
                          isDark: isDark,
                          child: _buildStyledTextField(
                            _usernameController,
                            prefixIcon: Icons.alternate_email_rounded,
                            enabled: false,
                            isDark: isDark,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _buildFormField(
                          label: 'Nama Lengkap',
                          isDark: isDark,
                          child: _buildStyledTextField(
                            _nameController,
                            prefixIcon: Icons.person_outline_rounded,
                            isDark: isDark,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _buildFormField(
                          label: 'Alamat Email',
                          isLocked: true,
                          isDark: isDark,
                          child: _buildStyledTextField(
                            _emailController,
                            prefixIcon: Icons.mail_outline_rounded,
                            enabled: false,
                            isDark: isDark,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _buildFormField(
                          label: 'Nomor Telepon / WhatsApp',
                          isDark: isDark,
                          child: _buildStyledTextField(
                            _phoneController,
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            isDark: isDark,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _buildFormField(
                          label: 'Jenis Kelamin',
                          isDark: isDark,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedGender,
                                isExpanded: true,
                                hint: Row(
                                  children: [
                                    Icon(Icons.wc_rounded, size: 18.sp, color: isDark ? Colors.white38 : Colors.grey.shade400),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Pilih Jenis Kelamin',
                                      style: TextStyle(
                                        fontSize: 12.5.sp,
                                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: _primaryBlue,
                                  size: 20.sp,
                                ),
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                                onChanged: (val) => setState(() => _selectedGender = val),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 22.h),

                  // SECTION 2: DATA DOMISILI & WILAYAH
                  _buildSectionHeader(
                    title: 'Data Domisili & Wilayah',
                    subtitle: 'Alamat tempat tinggal dan pembagian RT/RW',
                    isDark: isDark,
                  ),
                  SizedBox(height: 12.h),

                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildFormField(
                          label: 'Alamat Lengkap (Jalan / No. Rumah)',
                          isDark: isDark,
                          child: _buildStyledTextField(
                            _addressController,
                            prefixIcon: Icons.location_on_outlined,
                            maxLines: 2,
                            isDark: isDark,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                label: 'Kecamatan',
                                isLocked: true,
                                isDark: isDark,
                                child: _buildStyledTextField(
                                  _kecamatanController,
                                  enabled: false,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _buildFormField(
                                label: 'Desa / Kelurahan',
                                isLocked: true,
                                isDark: isDark,
                                child: _buildStyledTextField(
                                  _desaController,
                                  enabled: false,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                label: 'RW (Rukun Warga)',
                                isDark: isDark,
                                child: _buildStyledTextField(
                                  _rwController,
                                  prefixIcon: Icons.groups_outlined,
                                  keyboardType: TextInputType.number,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: _buildFormField(
                                label: 'RT (Rukun Tetangga)',
                                isDark: isDark,
                                child: _buildStyledTextField(
                                  _rtController,
                                  prefixIcon: Icons.home_outlined,
                                  keyboardType: TextInputType.number,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 28.h),

                  // STICKY ACTION BUTTON: SIMPAN PERUBAHAN
                  SizedBox(
                    width: double.infinity,
                    height: 48.h,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveProfile,
                      icon: _isSaving
                          ? SizedBox(
                              width: 16.w,
                              height: 16.h,
                              child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(Icons.save_rounded, size: 18.sp),
                      label: Text(
                        _isSaving ? 'Menyimpan Perubahan...' : 'Simpan Perubahan Profil',
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),
                ],
              ),
            ),
    );
  }

  Widget _buildDigitalKtpHeroCard(bool isDark) {
    final bool isVerified = _isVerified || _nik.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar Hero Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.badge_rounded, size: 18.sp, color: _primaryBlue),
                  SizedBox(width: 6.w),
                  Text(
                    'KTP DIGITAL WARGA',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: isVerified
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VerificationPage(),
                          ),
                        ).then((_) => _loadProfileFromApi());
                      },
                borderRadius: BorderRadius.circular(6.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: isVerified
                          ? const Color(0xFF10B981).withAlpha(80)
                          : const Color(0xFFD97706).withAlpha(80),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVerified ? Icons.verified_rounded : Icons.shield_outlined,
                        size: 11.sp,
                        color: isVerified ? const Color(0xFF059669) : const Color(0xFFD97706),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        isVerified ? 'TERVERIFIKASI' : 'BELUM VERIFIKASI',
                        style: TextStyle(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.bold,
                          color: isVerified ? const Color(0xFF059669) : const Color(0xFFD97706),
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (!isVerified) ...[
                        SizedBox(width: 3.w),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 8.sp,
                          color: const Color(0xFFD97706),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),
          const Divider(height: 1),
          SizedBox(height: 12.h),

          // Body Hero Card
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with camera action button
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
                      width: 68.w,
                      height: 68.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        border: Border.all(
                          color: _primaryBlue.withAlpha(120),
                          width: 2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _imageFile != null
                          ? Image.file(_imageFile!, fit: BoxFit.cover)
                          : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                              ? Image.network(
                                  _avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.person_rounded,
                                    size: 36.sp,
                                    color: _primaryBlue,
                                  ),
                                )
                              : Icon(
                                  Icons.person_rounded,
                                  size: 36.sp,
                                  color: _primaryBlue,
                                ),
                    ),
                  ),
                  InkWell(
                    onTap: _showImageSourcePicker,
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      padding: EdgeInsets.all(5.w),
                      decoration: BoxDecoration(
                        color: _primaryBlue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt_rounded,
                        size: 11.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(width: 14.w),

              // Resident Info preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nameController.text.isNotEmpty
                          ? _nameController.text
                          : 'Warga SiladesBeng',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 11.sp,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          'NIK: ${_maskNik(_nik)}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Ketuk ikon kamera untuk mengubah foto profil',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: _primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Action Banner jika belum terverifikasi
          if (!isVerified) ...[
            SizedBox(height: 12.h),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VerificationPage(),
                  ),
                ).then((_) => _loadProfileFromApi());
              },
              borderRadius: BorderRadius.circular(10.r),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withAlpha(isDark ? 25 : 15),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withAlpha(60),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 16.sp,
                      color: const Color(0xFFD97706),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Verifikasi KTP & Wajah untuk membuka akses penuh',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          color: const Color(0xFFD97706),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14.sp,
                      color: const Color(0xFFD97706),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3.5.w,
              height: 14.h,
              decoration: BoxDecoration(
                color: _primaryBlue,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Padding(
          padding: EdgeInsets.only(left: 11.5.w),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5.sp,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required Widget child,
    bool isLocked = false,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ),
            if (isLocked) ...[
              SizedBox(width: 4.w),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 11.sp,
                    color: isDark ? Colors.white30 : Colors.grey.shade400,
                  ),
                  SizedBox(width: 3.w),
                  Text(
                    'Terkunci',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: isDark ? Colors.white30 : Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        SizedBox(height: 6.h),
        child,
      ],
    );
  }

  Widget _buildStyledTextField(
    TextEditingController controller, {
    bool enabled = true,
    IconData? prefixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: !enabled
            ? (isDark ? const Color(0xFF0F172A).withAlpha(150) : const Color(0xFFF1F5F9))
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 12.5.sp,
          fontWeight: enabled ? FontWeight.w600 : FontWeight.w500,
          color: !enabled
              ? (isDark ? Colors.white38 : Colors.grey.shade500)
              : (isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
          border: InputBorder.none,
          prefixIcon: prefixIcon != null
              ? Icon(
                  prefixIcon,
                  size: 17.sp,
                  color: !enabled
                      ? (isDark ? Colors.white24 : Colors.grey.shade400)
                      : _primaryBlue,
                )
              : null,
        ),
      ),
    );
  }
}
