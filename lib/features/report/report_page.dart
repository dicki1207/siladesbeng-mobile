import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:http/http.dart' as http;
import 'package:siladesbeng_mobile/core/api_config.dart';
import 'package:siladesbeng_mobile/features/report/report_camera_page.dart';
import 'package:siladesbeng_mobile/features/report/report_map_picker_page.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late final ShowcaseView _showcaseView;

  // Showcase Tour Keys
  final GlobalKey _keyTujuan = GlobalKey();
  final GlobalKey _keyKategori = GlobalKey();
  final GlobalKey _keyLokasi = GlobalKey();
  final GlobalKey _keyFoto = GlobalKey();

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
    _showcaseView = ShowcaseView.register();
    _loadProfileData();
    _namaController.addListener(_calculateProgress);
    _deskripsiController.addListener(_calculateProgress);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartShowcase(
);
    });
  }

  Future<void> _checkAndStartShowcase(
) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenTour = prefs.getBool('has_seen_report_tour') ?? false;
      if (!hasSeenTour && mounted) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          _showcaseView.startShowCase([
            _keyTujuan,
            _keyKategori,
            _keyLokasi,
            _keyFoto,
          ]);
          await prefs.setBool('has_seen_report_tour', true);
        }
      }
    } catch (e) {
      debugPrint('Showcase error: $e');
    }
  }

  void _replayTour() {
    _showcaseView.startShowCase([
      _keyTujuan,
      _keyKategori,
      _keyLokasi,
      _keyFoto,
    ]);
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
    _showcaseView.unregister();
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
        Uri.parse('${ApiConfig.baseUrl}/api/user'),
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

  Future<void> _openCamera() async {
    try {
      final File? result = await Navigator.push<File>(
        context,
        MaterialPageRoute(
          builder: (context) => const ReportCameraPage(),
        ),
      );
      if (result != null) {
        setState(() {
          _imageFile = result;
        });
        _calculateProgress();
      }
    } catch (e) {
      _showError('Gagal membuka kamera: $e');
    }
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
        Uri.parse('${ApiConfig.baseUrl}/api/laporan'),
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
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _openCamera,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 28,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tambah Foto Bukti Kejadian',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ambil foto langsung atau pilih dari Album / Galeri',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_library_outlined, size: 12, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'Kamera & Album Galeri',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              _imageFile!,
              width: 52,
              height: 52,
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
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
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
            icon: Icon(Icons.refresh_rounded, color: primaryColor, size: 22),
            tooltip: 'Ganti Foto',
            onPressed: _openCamera,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
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

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportMapPickerPage(
          initialLocation: _selectedLocation,
          hasInitialLocation: _hasSelectedLocation,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLocation = result;
        _hasSelectedLocation = true;
      });
      _mapController.move(result, 16.0);
      _calculateProgress();
    }
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
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFF2FA2F1), const Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipRRect(
            child: Stack(
              children: [
                Positioned(
                  top: -30,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(22),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -15,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'Panduan Halaman',
            onPressed: _replayTour,
          ),
        ],
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
          // 1. Form Input Fields
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
                    Showcase(
                      titleTextStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.2),
                      descTextStyle: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w400, color: Color(0xFF475569), height: 1.35),
                      key: _keyKategori,
                      title: 'Pilih Kategori Laporan',
                      description: 'Pilih jenis masalah (Infrastruktur, Kebersihan, Keamanan, dll) agar langsung ditangani petugas yang tepat.',
            targetBorderRadius: BorderRadius.circular(12),
                      child: _buildDropdown(
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
                    ),
                  ],
                ),
              ),
            ],
          ),

          _buildLabel('Tujuan Pelaporan *', icon: Icons.send_outlined),
          Showcase(
            titleTextStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.2),
            descTextStyle: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w400, color: Color(0xFF475569), height: 1.35),
            key: _keyTujuan,
            title: 'Tentukan Tujuan Laporan',
            description: 'Tujukan laporan ke RT (lingkungan tetangga), RW (lingkup kampung), atau Pemerintah Desa (fasilitas umum desa).',
            targetBorderRadius: BorderRadius.circular(12),
            child: _buildDropdown(
              value: _selectedTujuan,
              hint: 'Pilih tujuan laporan',
              items: ['rt', 'rw', 'desa'],
              onChanged: (val) {
                setState(() => _selectedTujuan = val);
                _calculateProgress();
              },
              displayNames: const {
                'rt': 'Pengurus RT Setempat',
                'rw': 'Pengurus RW Setempat',
                'desa': 'Pemerintah Desa',
              },
            ),
          ),

          // 2. Interactive Full-Screen Capable Map Section
          _buildLabel('Lokasi Kejadian *', icon: Icons.map_outlined),
          Showcase(
            titleTextStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.2),
            descTextStyle: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w400, color: Color(0xFF475569), height: 1.35),
            key: _keyLokasi,
            title: 'Tandai Titik Lokasi Kejadian',
            description: 'Ketuk peta untuk menentukan koordinat lokasi secara presisi agar petugas mudah menuju tempat kejadian.',
            targetBorderRadius: BorderRadius.circular(16),
            child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hasSelectedLocation
                    ? primaryColor.withValues(alpha: isDark ? 0.6 : 0.4)
                    : (isDark ? Colors.white12 : Colors.grey.shade300),
                width: _hasSelectedLocation ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Clickable Map Preview Area (Clean without redundant text overlays)
                GestureDetector(
                  onTap: _openMapPicker,
                  child: SizedBox(
                    height: 140,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: _selectedLocation,
                              initialZoom: 15.5,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                              onTap: (tapPosition, point) => _openMapPicker(),
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
                                      width: 40,
                                      height: 40,
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: Colors.redAccent,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),

                          // Clean Floating Fullscreen Indicator Button
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                                    : Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.fullscreen_rounded,
                                color: isDark ? Colors.white : const Color(0xFF334155),
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Location Bottom Info & Action Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _hasSelectedLocation
                              ? Colors.redAccent.withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: _hasSelectedLocation ? Colors.redAccent : Colors.grey,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _hasSelectedLocation ? 'Titik Lokasi Terkunci' : 'Belum ada lokasi dipilih',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white60 : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _hasSelectedLocation
                                  ? "${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}"
                                  : "Ketuk tombol untuk buka peta",
                              style: TextStyle(
                                color: _hasSelectedLocation
                                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                    : (isDark ? Colors.white38 : Colors.grey[500]),
                                fontSize: 12.5,
                                fontWeight: _hasSelectedLocation ? FontWeight.bold : FontWeight.normal,
                                fontFamily: _hasSelectedLocation ? 'monospace' : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tombol Buka / Ubah Peta
                      OutlinedButton.icon(
                        onPressed: _openMapPicker,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(
                          _hasSelectedLocation ? Icons.edit_location_alt_rounded : Icons.map_rounded,
                          size: 15,
                        ),
                        label: Text(
                          _hasSelectedLocation ? 'Ubah Titik' : 'Pilih di Peta',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
          Showcase(
            titleTextStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.2),
            descTextStyle: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w400, color: Color(0xFF475569), height: 1.35),
            key: _keyFoto,
            title: 'Unggah Bukti Foto',
            description: 'Lampirkan foto bukti kejadian langsung dari kamera atau galeri untuk memperjelas dan memperkuat laporan Anda.',
            targetBorderRadius: BorderRadius.circular(16),
            child: _buildPhotoUploadSection(isDark, primaryColor),
          ),

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
          // 7. Submit Action Button (Full Width)
          SizedBox(
            width: double.infinity,
            height: 50,
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
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
