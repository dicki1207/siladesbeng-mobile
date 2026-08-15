import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  // User profile data
  String _userName = '';
  String _userEmail = '';
  String _userRw = '';
  String _userRt = '';
  String? _userAvatarUrl;

  String? _selectedCategory;
  String? _selectedTujuan;

  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isSubmitting = false;

  // Map related
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(-0.959, 100.353); // Default location
  bool _hasSelectedLocation = false;

  // Progress
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _namaController.addListener(_calculateProgress);
    _deskripsiController.addListener(_calculateProgress);
  }

  void _calculateProgress() {
    int score = 0;
    if (_namaController.text.isNotEmpty) score++;
    if (_deskripsiController.text.isNotEmpty) score++;
    if (_selectedCategory != null) score++;
    if (_selectedTujuan != null) score++;
    if (_hasSelectedLocation) score++;
    if (_imageFile != null) score++;
    setState(() {
      _progress = score / 6.0;
    });
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://10.250.3.148:8000/api/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final user = data['data']['user'];

          setState(() {
            _userName = user['name'] ?? '';
            _userEmail = user['email'] ?? '';
            _userRw = user['rw'] ?? '-';
            _userRt = user['rt'] ?? '-';
            _userAvatarUrl = data['data']['avatar_url'];

            _namaController.text = _userName;
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal mengambil data profil: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 60,
      );
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
        _calculateProgress();
      }
    } catch (e) {
      _showError('Gagal memilih foto: $e');
    }
  }

  void _showImageSourceDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pilih Sumber Foto',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.camera_alt_rounded, color: primaryColor, size: 22),
              ),
              title: const Text('Ambil Foto (Kamera)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Ambil foto langsung dengan kamera', style: TextStyle(fontSize: 11.5)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.photo_library_rounded, color: primaryColor, size: 22),
              ),
              title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Pilih file gambar dari penyimpanan perangkat', style: TextStyle(fontSize: 11.5)),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
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

  Future<void> _submitReport() async {
    if (_namaController.text.isEmpty ||
        _deskripsiController.text.isEmpty ||
        _selectedCategory == null ||
        _selectedTujuan == null ||
        !_hasSelectedLocation) {
      _showError('Mohon lengkapi semua data dan tandai lokasi kejadian di peta!');
      return;
    }

    if (_deskripsiController.text.length < 20) {
      _showError('Deskripsi laporan minimal 20 karakter.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _showError('Sesi berakhir, silakan login kembali.');
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.250.3.148:8000/api/laporan'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['nama'] = _namaController.text;
      request.fields['kategori'] = _selectedCategory!;
      request.fields['tujuan_laporan'] = _selectedTujuan!;
      request.fields['deskripsi'] = _deskripsiController.text;

      String locationStr =
          "${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}";
      request.fields['lokasi'] = locationStr;

      if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('bukti', _imageFile!.path),
        );
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = json.decode(responseData);

      if (response.statusCode == 200 && data['status'] == 'success') {
        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 56,
            ),
            content: const Text(
              'Laporan Anda berhasil dikirim dan akan segera ditindaklanjuti oleh pihak terkait.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  ),
                  child: const Text('Tutup', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      } else {
        String errorMsg = data['message'] ?? 'Gagal mengirim laporan';
        if (data['errors'] != null) {
          errorMsg = (data['errors'] as Map<String, dynamic>).values.first[0].toString();
        }
        _showError(errorMsg);
      }
    } catch (e) {
      _showError('Gagal terhubung ke server');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildLabel(String text, {IconData? icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, top: 12.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Theme.of(context).primaryColor),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: RichText(
              text: TextSpan(
                text: text.replaceAll('*', ''),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                ),
                children: text.contains('*')
                    ? const [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ]
                    : [],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
    Map<String, String>? displayNames,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade300,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: primaryColor,
          ),
          hint: Text(
            hint,
            style: TextStyle(
              color: isDark ? Colors.white24 : Colors.grey[400],
              fontSize: 13,
            ),
          ),
          dropdownColor: Theme.of(context).cardColor,
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                displayNames != null ? displayNames[item] ?? item : item,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildPhotoUploadSection(bool isDark, Color primaryColor) {
    if (_imageFile == null) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera_alt_rounded, size: 16, color: primaryColor),
                    label: Text(
                      'Kamera (Foto)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library_rounded, size: 16, color: primaryColor),
                    label: Text(
                      'Pilih Galeri',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Format: JPG, JPEG, PNG (Maksimal 5MB)',
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey[500],
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _imageFile!,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Foto Bukti Terlampir',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Siap dikirimkan bersama laporan',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: primaryColor, size: 20),
            tooltip: 'Ganti Foto',
            onPressed: _showImageSourceDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            tooltip: 'Hapus Foto',
            onPressed: () {
              setState(() => _imageFile = null);
              _calculateProgress();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Buat Laporan Warga',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.black.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(
              _progress == 1.0 ? const Color(0xFF10B981) : Colors.white,
            ),
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. Compact Header Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          'http://10.250.3.148:8000/Admin/img/illustrations/logokab.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Icon(Icons.account_balance, color: primaryColor, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          'http://10.250.3.148:8000/Admin/img/illustrations/logodomain.webp',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Icon(Icons.campaign_outlined, color: primaryColor, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Form Pengaduan & Aspirasi',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sampaikan keluhan secara transparan dan beretika',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Form Input Fields
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Nama Pelapor *', icon: Icons.person_outline_rounded),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.grey.shade300,
                        ),
                      ),
                      child: TextField(
                        controller: _namaController,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Nama Anda',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white24 : Colors.grey[400],
                            fontSize: 13,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Kategori *', icon: Icons.category_outlined),
                    _buildDropdown(
                      value: _selectedCategory,
                      hint: 'Pilih kategori',
                      items: [
                        'Infrastruktur',
                        'Kesehatan',
                        'Keamanan',
                        'Kebersihan',
                        'Lainnya',
                      ],
                      onChanged: (val) {
                        setState(() => _selectedCategory = val);
                        _calculateProgress();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          _buildLabel('Tujuan Pelaporan *', icon: Icons.send_outlined),
          _buildDropdown(
            value: _selectedTujuan,
            hint: 'Pilih tujuan laporan',
            items: ['rt', 'rw', 'desa'],
            onChanged: (val) {
              setState(() => _selectedTujuan = val);
              _calculateProgress();
            },
            displayNames: const {
              'rt': 'Laporkan kepada RT dan Pemerintah Desa',
              'rw': 'Laporkan kepada RW dan Pemerintah Desa',
              'desa': 'Laporkan kepada Pemerintah Desa Saja',
            },
          ),

          // 3. Compact Mini-Map Section (Height 130px)
          _buildLabel('Lokasi Kejadian *', icon: Icons.map_outlined),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Mini Map Box (130px)
                SizedBox(
                  height: 130,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _selectedLocation,
                            initialZoom: 15.0,
                            onTap: (tapPosition, point) {
                              setState(() {
                                _selectedLocation = point;
                                _hasSelectedLocation = true;
                              });
                              _calculateProgress();
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.siladesbeng',
                            ),
                            if (_hasSelectedLocation)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _selectedLocation,
                                    width: 36,
                                    height: 36,
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.redAccent,
                                      size: 36,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        // Quick Map Hint Overlay
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Ketuk peta untuk menandai titik',
                              style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Location Status Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: _hasSelectedLocation ? Colors.redAccent : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _hasSelectedLocation
                              ? "${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)} (Lokasi Terkunci)"
                              : "Belum ada lokasi dipilih. Ketuk titik pada peta di atas.",
                          style: TextStyle(
                            color: _hasSelectedLocation
                                ? (isDark ? Colors.white : const Color(0xFF1E293B))
                                : (isDark ? Colors.white38 : Colors.grey[500]),
                            fontSize: 11.5,
                            fontWeight: _hasSelectedLocation ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Deskripsi
          _buildLabel('Deskripsi Laporan *', icon: Icons.description_outlined),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade300,
              ),
            ),
            child: TextField(
              controller: _deskripsiController,
              maxLines: 3,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                hintText: 'Jelaskan keluhan atau kejadian dengan detail...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white24 : Colors.grey[400],
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Minimal 20 karakter',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey[500],
              fontSize: 11,
            ),
          ),

          // 5. Dual-Action Compact Photo Upload Section
          _buildLabel('Unggah Bukti Foto (Opsional)', icon: Icons.photo_camera_back_outlined),
          _buildPhotoUploadSection(isDark, primaryColor),

          const SizedBox(height: 18),

          // 6. User Info Summary Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: primaryColor,
                  child: ClipOval(
                    child: _userAvatarUrl != null
                        ? Image.network(
                            _userAvatarUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Text(
                              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          )
                        : Text(
                            _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pelapor: $_userName',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Wilayah: RW $_userRw / RT $_userRt • $_userEmail',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.grey[600],
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

          const SizedBox(height: 24),

          // 7. Action Buttons
          Row(
            children: [
              Expanded(
                flex: 35,
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 65,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitReport,
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _isSubmitting ? 'Mengirim...' : 'Kirim Laporan',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
