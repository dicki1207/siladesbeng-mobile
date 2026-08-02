import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:siladesbeng_mobile/main_wrapper.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';
import 'package:siladesbeng_mobile/features/profile/account/change_password_page.dart';

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

  final TextEditingController _passwordDisplayController =
      TextEditingController(text: '••••••••');

  String? _selectedGender;
  bool _isLoading = false;
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _loadProfileFromApi();
  }

  bool _isFetchingLocation = false;

  Future<void> _fetchLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layanan lokasi (GPS) tidak aktif')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak')));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak permanen')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            _kecamatanController.text =
                place.locality ?? place.subAdministrativeArea ?? 'Bengkalis';
            _desaController.text =
                place.subLocality ?? place.thoroughfare ?? 'Air Putih';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lokasi berhasil diverifikasi!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mendapatkan lokasi GPS')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _fallbackToLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('profile_name') ?? 'Nama Pengguna';
      _emailController.text =
          prefs.getString('profile_email') ?? 'email@example.com';
      _usernameController.text = prefs.getString('profile_name') ?? 'Username';
      _avatarUrl = prefs.getString('profile_image_url');
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
        Uri.parse('http://10.250.3.148:8000/api/user'),
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
          final region = data['data']['region_info'];

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
            _isBlocked = prefs.getBool('is_blocked') ?? false;
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
        Uri.parse('http://10.250.3.148:8000/api/profile/update'),
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
        _loadProfileFromApi(); // Reload to get new avatar URL if changed
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
          Uri.parse('http://10.250.3.148:8000/api/logout'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }
    } catch (e) {
      // Ignore network errors on logout
    }

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
        imageQuality: 50,
      );
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      _showError('Gagal membuka galeri: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Widget _buildField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    bool enabled = true,
    int maxLines = 1,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? Theme.of(context).cardColor
            : (isLight ? Colors.grey.shade200 : Colors.white.withAlpha(15)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLight ? Colors.grey.shade300 : Colors.white24,
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        style: TextStyle(
          color: enabled
              ? Theme.of(context).textTheme.bodyLarge?.color
              : (isLight ? Colors.grey.shade700 : Colors.grey.shade400),
          fontWeight: enabled ? FontWeight.w500 : FontWeight.normal,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profil SiladesBeng',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: isLight
                ? Theme.of(context).primaryColor
                : Colors.blueAccent.shade200,
            indicatorWeight: 3.5,
            labelColor: isLight ? Theme.of(context).primaryColor : Colors.white,
            unselectedLabelColor: isLight
                ? Colors.grey.shade600
                : Colors.white60,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Pribadi', icon: Icon(Icons.person_rounded)),
              Tab(text: 'Wilayah', icon: Icon(Icons.map_rounded)),
              Tab(text: 'Akun', icon: Icon(Icons.security_rounded)),
            ],
          ),
        ),
        body: _isLoading && _nameController.text.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  // TAB 1: PRIBADI
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Center(
                          child: Stack(
                            children: [
                              ClipOval(
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).primaryColor,
                                      width: 3,
                                    ),
                                  ),
                                  child: _imageFile != null
                                      ? Image.file(
                                          _imageFile!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.grey[400],
                                          ),
                                        )
                                      : (_avatarUrl != null
                                          ? Image.network(
                                              _avatarUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) => Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.grey[400],
                                              ),
                                            )
                                          : Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.grey[400],
                                            )),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: const Text('Ubah Foto'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'JPG, PNG (Max 8MB)',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 32),

                        _buildField(
                          label: 'Nama Pengguna',
                          child: _buildTextField(
                            _usernameController,
                            enabled: false,
                          ),
                        ),
                        _buildField(
                          label: 'Nama Lengkap',
                          child: _buildTextField(_nameController),
                        ),
                        _buildField(
                          label: 'Email',
                          child: _buildTextField(
                            _emailController,
                            enabled: false,
                          ),
                        ),
                        _buildField(
                          label: 'Nomor Telepon',
                          child: _buildTextField(_phoneController),
                        ),
                        _buildField(
                          label: 'Jenis Kelamin',
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedGender,
                                isExpanded: true,
                                hint: const Text('Pilih Jenis Kelamin'),
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
                      ],
                    ),
                  ),

                  // TAB 2: WILAYAH
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Data Wilayah',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _isFetchingLocation
                                  ? null
                                  : _fetchLocation,
                              icon: _isFetchingLocation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.my_location, size: 18),
                              label: const Text(
                                'Verifikasi GPS',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Theme.of(context).primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        _buildField(
                          label: 'Alamat Detail',
                          child: _buildTextField(
                            _addressController,
                            maxLines: 2,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                label: 'Kecamatan',
                                child: _buildTextField(
                                  _kecamatanController,
                                  enabled: false,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                label: 'Desa / Kelurahan',
                                child: _buildTextField(
                                  _desaController,
                                  enabled: false,
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
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                label: 'RT',
                                child: _buildTextField(
                                  _rtController,
                                  enabled: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // TAB 3: AKUN
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Keamanan Akun',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildField(
                          label: 'Kata Sandi',
                          child: _buildTextField(
                            _passwordDisplayController,
                            enabled: false,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ChangePasswordPage(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.lock_reset, size: 18),
                            label: const Text(
                              'Ubah Sandi',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).primaryColor,
                              side: BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Debug Toggle
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(15),
                            border: Border.all(color: Colors.red.withAlpha(40)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tandai Keluar (Debug)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                  Text(
                                    'Simulasi pindah domisili',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                              Switch(
                                value: _isBlocked,
                                activeThumbColor: Colors.red,
                                onChanged: (val) async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool('is_blocked', val);
                                  setState(() {
                                    _isBlocked = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Keluar Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout),
                            label: const Text(
                              'Keluar dari Aplikasi',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _isLoading
                ? const SizedBox(
                    height: 52,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
    _passwordDisplayController.dispose();
    super.dispose();
  }
}
