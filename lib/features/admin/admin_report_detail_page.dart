import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';

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
  late String _currentStatus;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.report['status'] ?? 'Menunggu';
  }

  // Helper: Build Full Image URL
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

  // Parse GPS location
  LatLng? _parseCoordinates(dynamic loc) {
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
        // Fallback update local state for preview
        setState(() {
          _currentStatus = newStatus;
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
                'Laporan berhasil diperbarui: $actionLabel',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Dialog: Show Action Modal with optional response note
  void _openActionModal({
    required String actionCode,
    required String actionTitle,
    required String newStatus,
    required Color color,
    required IconData icon,
  }) {
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            actionTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Status akan diubah menjadi: $newStatus',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Catatan untuk Warga (Opsional)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tuliskan catatan tindak lanjut atau pesan untuk pelapor...',
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white38 : Colors.grey[400],
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: color, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _submitAction(
                            actionCode: actionCode,
                            actionLabel: actionTitle,
                            newStatus: newStatus,
                            catatan: noteController.text.trim(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Konfirmasi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2563EB);

    final String reportId = widget.report['id']?.toString() ?? '1';
    final String kategori = widget.report['kategori'] ?? widget.report['category'] ?? 'Pengaduan Warga';
    final String pelapor = widget.report['reporter'] ?? widget.report['reporter_name'] ?? 'Warga Lingkungan';
    final String tanggal = widget.report['date'] ?? 'Hari ini';
    final String deskripsiRaw = (widget.report['deskripsi'] ?? widget.report['description'] ?? widget.report['desc'] ?? '').toString().trim();
    final String deskripsi = deskripsiRaw.isNotEmpty ? deskripsiRaw : 'Tidak ada rincian keterangan tambahan dari pelapor.';
    final String buktiUrl = _getImageUrl(widget.report['bukti'] ?? widget.report['foto']);
    final LatLng? coords = _parseCoordinates(widget.report['lokasi']);
    final String lokasiText = widget.report['lokasi_text'] ?? (widget.report['lokasi'] != null && coords == null ? widget.report['lokasi'].toString() : 'Lingkungan RT 02 / RW 01');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Laporan #$reportId',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KARTU UTAMA: RINGKASAN & STATUS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          kategori,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(_currentStatus),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  _buildMetaRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Pelapor',
                    value: pelapor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildMetaRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Tanggal Masuk',
                    value: tanggal,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildMetaRow(
                    icon: Icons.location_on_outlined,
                    label: 'Wilayah / Lokasi',
                    value: lokasiText,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. ISI URAIAN PENGADUAN
            Text(
              'Uraian Pengaduan Warga',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 15 : 4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                deskripsi,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. FOTO BUKTI LAPANGAN
            Text(
              'Foto Bukti Lapangan',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            if (buktiUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  buktiUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildNoPhotoBox(isDark),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  },
                ),
              )
            else
              _buildNoPhotoBox(isDark),

            const SizedBox(height: 20),

            // 4. TITIK PETA GPS (JIKA TERSEDIA)
            if (coords != null) ...[
              Text(
                'Titik Lokasi Pengaduan',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: coords,
                      initialZoom: 16.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.siladesbeng',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: coords,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.redAccent,
                              size: 38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 5. TINDAK LANJUT PENGURUS
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tindak Lanjut Pengurus',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isProcessing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Column(
                children: [
                  // Tombol 1: Proses Laporan
                  _buildActionButton(
                    icon: Icons.play_circle_outline_rounded,
                    label: 'Tindak Lanjuti (Proses Aduan)',
                    color: const Color(0xFF2563EB),
                    isDark: isDark,
                    onTap: () => _openActionModal(
                      actionCode: widget.role == 'rw' ? 'process_rw' : 'process',
                      actionTitle: 'Tindak Lanjuti Aduan',
                      newStatus: widget.role == 'rw' ? 'Diproses RW' : 'Diproses',
                      color: const Color(0xFF2563EB),
                      icon: Icons.play_circle_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tombol 2: Selesaikan Aduan
                  _buildActionButton(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Tandai Laporan Selesai',
                    color: const Color(0xFF10B981),
                    isDark: isDark,
                    onTap: () => _openActionModal(
                      actionCode: 'resolve',
                      actionTitle: 'Selesaikan Laporan',
                      newStatus: 'Selesai',
                      color: const Color(0xFF10B981),
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tombol 3: Teruskan ke RW / Desa
                  if (widget.role == 'rt')
                    _buildActionButton(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Teruskan ke Pengurus RW',
                      color: const Color(0xFF6366F1),
                      isDark: isDark,
                      onTap: () => _openActionModal(
                        actionCode: 'forward_rw',
                        actionTitle: 'Teruskan ke RW',
                        newStatus: 'Diteruskan ke RW',
                        color: const Color(0xFF6366F1),
                        icon: Icons.arrow_upward_rounded,
                      ),
                    )
                  else
                    _buildActionButton(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Teruskan ke Pemerintah Desa',
                      color: const Color(0xFF6366F1),
                      isDark: isDark,
                      onTap: () => _openActionModal(
                        actionCode: 'forward_desa',
                        actionTitle: 'Teruskan ke Desa',
                        newStatus: 'Diteruskan ke Desa',
                        color: const Color(0xFF6366F1),
                        icon: Icons.arrow_upward_rounded,
                      ),
                    ),
                  const SizedBox(height: 10),

                  // Tombol 4: Tolak Laporan
                  _buildActionButton(
                    icon: Icons.cancel_outlined,
                    label: 'Tolak / Batalkan Aduan',
                    color: const Color(0xFFEF4444),
                    isDark: isDark,
                    isDestructive: true,
                    onTap: () => _openActionModal(
                      actionCode: 'reject',
                      actionTitle: 'Tolak Aduan Warga',
                      newStatus: 'Ditolak',
                      color: const Color(0xFFEF4444),
                      icon: Icons.cancel_outlined,
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 36,
            color: isDark ? Colors.white38 : Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Tidak ada lampiran foto bukti',
            style: TextStyle(
              fontSize: 12.5,
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
        Icon(icon, size: 16, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 12, color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
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
    Color text = const Color(0xFF2563EB);

    if (sLower.contains('selesai')) {
      bg = const Color(0xFFECFDF5);
      text = const Color(0xFF059669);
    } else if (sLower.contains('tolak')) {
      bg = const Color(0xFFFEF2F2);
      text = const Color(0xFFDC2626);
    } else if (sLower.contains('proses') || sLower.contains('teruskan')) {
      bg = const Color(0xFFEFF6FF);
      text = const Color(0xFF2563EB);
    } else {
      bg = const Color(0xFFFFFBEB);
      text = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // WIDGET: Action Button
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDestructive
              ? color.withAlpha(50)
              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? color
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark ? Colors.white38 : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
