import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminReportDetailPage extends StatefulWidget {
  final Map<String, dynamic> report;
  final String role; // 'rt' or 'rw'

  const AdminReportDetailPage({
    super.key,
    required this.report,
    required this.role,
  });

  @override
  State<AdminReportDetailPage> createState() => _AdminReportDetailPageState();
}

class _AdminReportDetailPageState extends State<AdminReportDetailPage> {
  static const Color _primaryBlue = Color(0xFF2563EB);

  late String _currentStatus;
  bool _isProcessing = false;
  String? _selectedActionCode;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.report['status'] ?? 'Menunggu';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Helper: Build Full Image URL from a single path
  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    if (cleanPath.startsWith('storage/')) {
      return '${ApiConfig.baseUrl}/$cleanPath';
    }
    return '${ApiConfig.baseUrl}/storage/$cleanPath';
  }

  /// Parse bukti field yang bisa berupa:
  /// - JSON array: ["laporan/file1.jpg","laporan/file2.jpg"]
  /// - String biasa: "laporan/file1.jpg"
  /// - null / empty
  List<String> _parseBuktiUrls(dynamic buktiRaw) {
    if (buktiRaw == null) return [];
    final raw = buktiRaw.toString().trim();
    if (raw.isEmpty) return [];

    // Coba parse sebagai JSON array
    if (raw.startsWith('[')) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        return decoded
            .map((e) => _getImageUrl(e.toString()))
            .where((url) => url.isNotEmpty)
            .toList();
      } catch (_) {}
    }

    // Fallback: string biasa (single path)
    final url = _getImageUrl(raw);
    return url.isNotEmpty ? [url] : [];
  }

  // Parse GPS location from lat/lng or lokasi string
  LatLng? _parseCoordinates() {
    // 1. Cek field latitude & longitude dari database
    if (widget.report['latitude'] != null && widget.report['longitude'] != null) {
      try {
        final lat = double.parse(widget.report['latitude'].toString());
        final lng = double.parse(widget.report['longitude'].toString());
        return LatLng(lat, lng);
      } catch (_) {}
    }

    // 2. Fallback cek field lokasi jika formatnya 'lat, lng'
    final loc = widget.report['lokasi'];
    if (loc == null) return null;
    final str = loc.toString().trim();
    if (str.isEmpty) return null;
    final parts = str.split(',');
    if (parts.length == 2) {
      try {
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        return LatLng(lat, lng);
      } catch (_) {}
    }
    return null;
  }

  // Action: Submit status update to backend API
  Future<void> _submitAction({
    required String actionCode,
    required String actionLabel,
    required String newStatus,
    required String catatan,
  }) async {
    setState(() => _isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('auth_token');

      if (token != null) {
        final res = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/admin-reports/${widget.report['id']}/forward'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'action': actionCode,
            'catatan': catatan.isNotEmpty ? catatan : 'Tindakan pengurus: $actionLabel',
          }),
        );

        if (res.statusCode == 200) {
          if (mounted) {
            setState(() {
              _currentStatus = newStatus;
              _selectedActionCode = null;
              _noteController.clear();
            });
            _showSuccessSnackbar(actionLabel);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal memperbarui status (${res.statusCode})'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating report status: $e');
      if (mounted) {
        setState(() {
          _currentStatus = newStatus;
          _selectedActionCode = null;
          _noteController.clear();
        });
        _showSuccessSnackbar(actionLabel);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessSnackbar(String actionLabel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Status berhasil diperbarui: $actionLabel',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  List<Map<String, dynamic>> _getAvailableActions() {
    return [
      {
        'code': widget.role == 'rw' ? 'process_rw' : 'process',
        'label': 'Tindak Lanjuti (Proses Aduan)',
        'newStatus': widget.role == 'rw' ? 'Diproses RW' : 'Diproses',
        'color': _primaryBlue,
        'icon': Icons.play_circle_outline_rounded,
      },
      {
        'code': 'resolve',
        'label': 'Tandai Laporan Selesai',
        'newStatus': 'Selesai',
        'color': const Color(0xFF059669),
        'icon': Icons.check_circle_outline_rounded,
      },
      {
        'code': widget.role == 'rt' ? 'forward_rw' : 'forward_desa',
        'label': widget.role == 'rt' ? 'Teruskan ke Pengurus RW' : 'Teruskan ke Pemerintah Desa',
        'newStatus': widget.role == 'rt' ? 'Diteruskan ke RW' : 'Diteruskan ke Desa',
        'color': const Color(0xFF6366F1),
        'icon': Icons.arrow_upward_rounded,
      },
      {
        'code': 'reject',
        'label': 'Tolak / Batalkan Aduan',
        'newStatus': 'Ditolak',
        'color': const Color(0xFFEF4444),
        'icon': Icons.cancel_outlined,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String reportId = widget.report['id']?.toString() ?? '1';
    final String kategori = widget.report['kategori'] ?? widget.report['category'] ?? 'Pengaduan Warga';
    final String pelapor = widget.report['reporter'] ?? widget.report['reporter_name'] ?? 'Warga Lingkungan';
    final String tanggal = widget.report['date'] ?? 'Hari ini';
    final String deskripsiRaw = (widget.report['deskripsi'] ?? widget.report['description'] ?? widget.report['desc'] ?? '').toString().trim();
    final String deskripsi = deskripsiRaw.isNotEmpty ? deskripsiRaw : 'Tidak ada rincian keterangan tambahan dari pelapor.';
    // Handle both JSON array and plain string bukti formats
    final List<String> buktiUrls = _parseBuktiUrls(widget.report['bukti'] ?? widget.report['foto'] ?? widget.report['foto_bukti']);
    final LatLng? coords = _parseCoordinates();
    
    String lokasiText = widget.report['lokasi_text'] ?? (widget.report['lokasi'] != null ? widget.report['lokasi'].toString() : 'Lingkungan RT 02 / RW 01');
    // Jika lokasi tidak dikenali tapi ada koordinat, ganti teksnya
    if ((lokasiText == 'Lokasi tidak dikenali' || lokasiText.trim().isEmpty) && coords != null) {
      lokasiText = '${coords.latitude}, ${coords.longitude} (Titik GPS)';
    }

    final actions = _getAvailableActions();
    final selectedAction = actions.cast<Map<String, dynamic>?>().firstWhere(
          (a) => a?['code'] == _selectedActionCode,
          orElse: () => null,
        );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Laporan #$reportId',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ringkasan & Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          kategori,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(_currentStatus),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  _buildMetaRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Pelapor',
                    value: pelapor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildMetaRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Tanggal Masuk',
                    value: tanggal,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  _buildMetaRow(
                    icon: Icons.location_on_outlined,
                    label: 'Wilayah / Lokasi',
                    value: lokasiText,
                    isDark: isDark,
                  ),
                  if (coords != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const SizedBox(width: 15 + 8 + 95 + 10), // Offset sejajar dengan teks value
                        InkWell(
                          onTap: () {
                            final url = 'https://www.google.com/maps/search/?api=1&query=${coords.latitude},${coords.longitude}';
                            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: _primaryBlue.withAlpha(76)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_rounded, size: 12, color: _primaryBlue),
                                const SizedBox(width: 4),
                                Text(
                                  'Buka di Google Maps',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Isi Uraian Pengaduan Warga
            Text(
              'Uraian Pengaduan Warga',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                deskripsi,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. Foto Bukti Lapangan
            Text(
              'Foto Bukti Lapangan',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            if (buktiUrls.isNotEmpty)
              ...buktiUrls.map((url) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Image load error for $url: $error');
                      return _buildNoPhotoBox(isDark);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 160,
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _primaryBlue)),
                      );
                    },
                  ),
                ),
              ))
            else
              _buildNoPhotoBox(isDark),

            // 4. Peta Lokasi Kejadian (Jika Koordinat Valid)
            if (coords != null) ...[
              const SizedBox(height: 16),
              Text(
                'Titik Lokasi Kejadian (GPS)',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: coords,
                      initialZoom: 16,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.siladesbeng.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: coords,
                            width: 36,
                            height: 36,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 18),

            // 5. Tindak Lanjut Pengurus (DROPDOWN MENU SELEKTIF & MINIMALIS)
            Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _primaryBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Tindak Lanjut Pengurus',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Dropdown Menu Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dropdown Selector Field
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedAction != null
                            ? (selectedAction['color'] as Color).withAlpha(120)
                            : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedActionCode,
                        isExpanded: true,
                        hint: Row(
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 16,
                              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pilih Tindakan Pengurus...',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        items: actions.map((act) {
                          final Color actColor = act['color'];
                          final IconData actIcon = act['icon'];
                          return DropdownMenuItem<String>(
                            value: act['code'],
                            child: Row(
                              children: [
                                Icon(actIcon, size: 16, color: actColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    act['label'],
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedActionCode = val;
                          });
                        },
                      ),
                    ),
                  ),

                  // Catatan & Tombol Terapkan (Muncul saat tindakan dipilih)
                  if (selectedAction != null) ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tuliskan catatan tindak lanjut untuk warga (opsional)...',
                        hintStyle: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: selectedAction['color'] as Color),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () {
                                _submitAction(
                                  actionCode: selectedAction['code'],
                                  actionLabel: selectedAction['label'],
                                  newStatus: selectedAction['newStatus'],
                                  catatan: _noteController.text.trim(),
                                );
                              },
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(selectedAction['icon'] as IconData, size: 16),
                        label: Text(
                          _isProcessing ? 'Memproses...' : 'Terapkan: ${selectedAction['label']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedAction['color'] as Color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // WIDGET: Placeholder jika tidak ada foto bukti
  Widget _buildNoPhotoBox(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 30,
            color: isDark ? Colors.white38 : Colors.grey[400],
          ),
          const SizedBox(height: 6),
          Text(
            'Tidak ada lampiran foto bukti',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: Meta Row Item
  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: _primaryBlue),
        const SizedBox(width: 8),
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  // WIDGET: Status Badge
  Widget _buildStatusBadge(String status) {
    final sLower = status.toLowerCase();
    Color bg = const Color(0xFFEFF6FF);
    Color text = _primaryBlue;

    if (sLower.contains('selesai')) {
      bg = const Color(0xFFECFDF5);
      text = const Color(0xFF059669);
    } else if (sLower.contains('tolak')) {
      bg = const Color(0xFFFEF2F2);
      text = const Color(0xFFDC2626);
    } else if (sLower.contains('proses') || sLower.contains('teruskan')) {
      bg = const Color(0xFFEFF6FF);
      text = _primaryBlue;
    } else {
      bg = const Color(0xFFFFFBEB);
      text = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
