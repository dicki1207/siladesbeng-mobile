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
  final _lokasiDisplayController =
      TextEditingController(); // For the display string

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  bool _isSubmitting = false;

  // Map related
  final MapController _mapController = MapController();
  LatLng _selectedLocation = const LatLng(
    -0.959,
    100.353,
  ); // Default location (e.g. Padang)
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
    _lokasiDisplayController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://10.193.206.148:8000/api/user'),
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
        _calculateProgress();
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

  Future<void> _submitReport() async {
    if (_namaController.text.isEmpty ||
        _deskripsiController.text.isEmpty ||
        _selectedCategory == null ||
        _selectedTujuan == null ||
        !_hasSelectedLocation) {
      _showError('Mohon lengkapi semua field dan pilih lokasi di peta!');
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
        Uri.parse('http://10.193.206.148:8000/api/laporan'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['nama'] = _namaController.text;
      request.fields['kategori'] = _selectedCategory!;
      request.fields['tujuan_laporan'] = _selectedTujuan!;
      request.fields['deskripsi'] = _deskripsiController.text;

      // Sending coordinate string as 'lokasi'
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
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
            content: const Text(
              'Laporan Anda berhasil dikirim dan akan segera diproses oleh pihak terkait.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Go back to previous screen
                },
                child: const Text('Tutup', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      } else {
        String errorMsg = data['message'] ?? 'Gagal mengirim laporan';
        if (data['errors'] != null) {
          errorMsg = (data['errors'] as Map<String, dynamic>).values.first[0]
              .toString();
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: RichText(
              text: TextSpan(
                text: text.replaceAll('*', ''),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      const Color(0xFF1E3A5F),
                ),
                children: text.contains('*')
                    ? const [
                        TextSpan(
                          text: ' *',
                          style: TextStyle(color: Colors.red),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Theme.of(context).primaryColor,
          ),
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                displayNames != null ? displayNames[item] ?? item : item,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120, // Lebih pendek
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            iconTheme: IconThemeData(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _progress == 1.0
                      ? Colors.green
                      : Theme.of(context).primaryColor,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Laporan Warga',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              centerTitle: true,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withAlpha(20),
                          Theme.of(context).primaryColor.withAlpha(5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withAlpha(50),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sampaikan keluhan atau saran Anda dengan sopan dan jujur untuk kemajuan desa bersama.',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(
                              'Nama Lengkap *',
                              icon: Icons.person_outline,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).dividerColor.withAlpha(50),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _namaController,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Masukkan nama Anda',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel(
                              'Kategori *',
                              icon: Icons.category_outlined,
                            ),
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

                  _buildLabel('Lokasi Kejadian *', icon: Icons.map_outlined),
                  const Text(
                    'Klik pada peta untuk menentukan lokasi kejadian secara tepat.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // Bikin lebih bulat
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withAlpha(50),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: FlutterMap(
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
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                                    Icons.location_on,
                                    color: Colors.redAccent,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withAlpha(50),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: _hasSelectedLocation
                              ? Colors.redAccent
                              : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _hasSelectedLocation
                                ? "${_selectedLocation.latitude.toStringAsFixed(6)}, ${_selectedLocation.longitude.toStringAsFixed(6)}"
                                : "Belum ada lokasi dipilih. Klik peta di atas.",
                            style: TextStyle(
                              color: _hasSelectedLocation
                                  ? Theme.of(context).textTheme.bodyLarge?.color
                                  : Colors.grey[500],
                              fontStyle: _hasSelectedLocation
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildLabel(
                    'Deskripsi Laporan *',
                    icon: Icons.description_outlined,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withAlpha(50),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _deskripsiController,
                      maxLines: 5,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Jelaskan keluhan Anda dengan detail...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 6.0),
                    child: Text(
                      'Minimal 20 karakter',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),

                  _buildLabel(
                    'Unggah Bukti (Opsional)',
                    icon: Icons.photo_library_outlined,
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).dividerColor.withAlpha(80),
                          style: BorderStyle.solid,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (_imageFile == null) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.cloud_upload_outlined,
                                color: Theme.of(context).primaryColor,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Klik untuk mengunggah gambar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Format: JPG, JPEG, PNG | Maksimal 2MB',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ] else ...[
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              transitionBuilder: (child, animation) =>
                                  ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                              child: ClipRRect(
                                key: ValueKey(_imageFile!.path),
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _imageFile!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: _pickImage,
                              icon: Icon(
                                Icons.edit,
                                color: Theme.of(context).primaryColor,
                              ),
                              label: Text(
                                'Ganti Gambar',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // User Info Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withAlpha(15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withAlpha(30),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).primaryColor,
                          child: ClipOval(
                            child: _userAvatarUrl != null
                                ? Image.network(
                                    _userAvatarUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Text(
                                      _userName.isNotEmpty
                                          ? _userName[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                : Text(
                                    _userName.isNotEmpty
                                        ? _userName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withAlpha(180),
                                    fontSize: 13,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'Laporan akan dikirim atas nama: ',
                                    ),
                                    TextSpan(
                                      text: _userName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withAlpha(180),
                                    fontSize: 13,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Email: '),
                                    TextSpan(
                                      text: _userEmail,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withAlpha(180),
                                    fontSize: 13,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Wilayah Anda: '),
                                    TextSpan(
                                      text: 'RW $_userRw / RT $_userRt',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
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

                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).dividerColor.withAlpha(100),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).primaryColor.withAlpha(200),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withAlpha(80),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Kirim Laporan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
