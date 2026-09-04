import 'dart:convert';
import 'package:siladesbeng_mobile/widgets/custom_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  static const Color _primaryBlue = Color(0xFF2FA2F1);

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

  List<String> _parseBuktiUrls(dynamic buktiRaw) {
    if (buktiRaw == null) return [];
    final raw = buktiRaw.toString().trim();
    if (raw.isEmpty) return [];

    if (raw.startsWith('[')) {
      try {
        final List<dynamic> decoded = jsonDecode(raw);
        return decoded
            .map((e) => _getImageUrl(e.toString()))
            .where((url) => url.isNotEmpty)
            .toList();
      } catch (_) {}
    }

    final url = _getImageUrl(raw);
    return url.isNotEmpty ? [url] : [];
  }

  LatLng? _parseCoordinates() {
    if (widget.report['latitude'] != null && widget.report['longitude'] != null) {
      try {
        final lat = double.parse(widget.report['latitude'].toString());
        final lng = double.parse(widget.report['longitude'].toString());
        return LatLng(lat, lng);
      } catch (_) {}
    }

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
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Status berhasil diperbarui: $actionLabel',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5.sp),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }

  List<Map<String, dynamic>> _getAvailableActions() {
    return [
      {
        'code': widget.role == 'rw' ? 'process_rw' : 'process',
        'title': 'Proses Aduan',
        'subtitle': 'Mulai penanganan laporan',
        'label': 'Tindak Lanjuti (Proses Aduan)',
        'newStatus': widget.role == 'rw' ? 'Diproses RW' : 'Diproses',
        'color': const Color(0xFF2FA2F1),
        'icon': Icons.pending_actions_rounded,
      },
      {
        'code': 'resolve',
        'title': 'Tandai Selesai',
        'subtitle': 'Laporan telah tertangani',
        'label': 'Tandai Laporan Selesai',
        'newStatus': 'Selesai',
        'color': const Color(0xFF10B981),
        'icon': Icons.task_alt_rounded,
      },
      {
        'code': widget.role == 'rt' ? 'forward_rw' : 'forward_desa',
        'title': widget.role == 'rt' ? 'Teruskan ke RW' : 'Teruskan ke Desa',
        'subtitle': 'Eskalasi ke tingkat atas',
        'label': widget.role == 'rt' ? 'Teruskan ke Pengurus RW' : 'Teruskan ke Pemerintah Desa',
        'newStatus': widget.role == 'rt' ? 'Diteruskan ke RW' : 'Diteruskan ke Desa',
        'color': const Color(0xFF6366F1),
        'icon': Icons.forward_to_inbox_rounded,
      },
      {
        'code': 'reject',
        'title': 'Tolak Aduan',
        'subtitle': 'Laporan tidak valid',
        'label': 'Tolak / Batalkan Aduan',
        'newStatus': 'Ditolak',
        'color': const Color(0xFFEF4444),
        'icon': Icons.block_rounded,
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
    final List<String> buktiUrls = _parseBuktiUrls(widget.report['bukti'] ?? widget.report['foto'] ?? widget.report['foto_bukti']);
    final LatLng? coords = _parseCoordinates();
    
    String lokasiText = widget.report['lokasi_text'] ?? (widget.report['lokasi'] != null ? widget.report['lokasi'].toString() : 'Lingkungan RT 02 / RW 01');
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
            // Ambient light circle 1 (Top Right)
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
            // Ambient light circle 2 (Bottom Left)
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
              'Detail Laporan #$reportId',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16.5.sp,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Informasi & Tindak Lanjut Aduan Warga',
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 40.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ringkasan & Status
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14.r),
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
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      _buildStatusBadge(_currentStatus),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  const Divider(height: 1),
                  SizedBox(height: 10.h),
                  _buildMetaRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Pelapor',
                    value: pelapor,
                    isDark: isDark,
                  ),
                  SizedBox(height: 8.h),
                  _buildMetaRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Tanggal Masuk',
                    value: tanggal,
                    isDark: isDark,
                  ),
                  SizedBox(height: 8.h),
                  _buildMetaRow(
                    icon: Icons.location_on_outlined,
                    label: 'Wilayah / Lokasi',
                    value: lokasiText,
                    isDark: isDark,
                  ),
                  if (coords != null) ...[
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        SizedBox(width: 15.w + 8.w + 95.w + 10.w),
                        InkWell(
                          onTap: () {
                            final url = 'https://www.google.com/maps/search/?api=1&query=${coords.latitude},${coords.longitude}';
                            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                          },
                          borderRadius: BorderRadius.circular(6.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(color: _primaryBlue.withAlpha(76)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_rounded, size: 12.sp, color: _primaryBlue),
                                SizedBox(width: 4.w),
                                Text(
                                  'Buka di Google Maps',
                                  style: TextStyle(
                                    fontSize: 10.sp,
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

            SizedBox(height: 16.h),

            // 2. Isi Uraian Pengaduan Warga
            Text(
              'Uraian Pengaduan Warga',
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                deskripsi,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  height: 1.5,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // 3. Foto Bukti Lapangan
            Text(
              'Foto Bukti Lapangan',
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 6.h),
            if (buktiUrls.isNotEmpty)
              ...buktiUrls.map((url) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: CustomCachedImage(
                    url,
                    height: 180.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('Image load error for $url: $error');
                      return _buildNoPhotoBox(isDark);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 160.h,
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _primaryBlue)),
                      );
                    },
                  ),
                ),
              ))
            else
              _buildNoPhotoBox(isDark),

            // 4. Peta Lokasi Kejadian
            if (coords != null) ...[
              SizedBox(height: 16.h),
              Text(
                'Titik Lokasi Kejadian (GPS)',
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 6.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: SizedBox(
                  height: 160.h,
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
                            width: 36.w,
                            height: 36.h,
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

            SizedBox(height: 18.h),

            // 5. Tindak Lanjut Pengurus (MODERN SELECTION CARDS - NO EMOJIS)
            Row(
              children: [
                Container(
                  width: 3.5.w,
                  height: 15.h,
                  decoration: BoxDecoration(
                    color: _primaryBlue,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Tindak Lanjut Pengurus',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // Grid of 4 Action Cards
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
                childAspectRatio: 1.7,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final act = actions[index];
                final bool isSelected = _selectedActionCode == act['code'];
                final Color actColor = act['color'] as Color;
                final IconData actIcon = act['icon'] as IconData;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedActionCode = isSelected ? null : act['code'];
                    });
                  },
                  borderRadius: BorderRadius.circular(12.r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? actColor.withAlpha(isDark ? 40 : 20)
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected
                            ? actColor
                            : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: actColor.withAlpha(50),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(7.w),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? actColor
                                : actColor.withAlpha(isDark ? 30 : 18),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            actIcon,
                            size: 18.sp,
                            color: isSelected ? Colors.white : actColor,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                act['title'],
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? (isDark ? Colors.white : actColor)
                                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                act['subtitle'],
                                style: TextStyle(
                                  fontSize: 9.5.sp,
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
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
                );
              },
            ),

            // Note field & Submit button
            if (selectedAction != null) ...[
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: (selectedAction['color'] as Color).withAlpha(100),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tindakan Terpilih: ${selectedAction['title']}',
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.bold,
                        color: selectedAction['color'] as Color,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tuliskan catatan tindak lanjut untuk warga (opsional)...',
                        hintStyle: TextStyle(
                          fontSize: 11.5.sp,
                          color: isDark ? Colors.white38 : Colors.grey.shade400,
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: selectedAction['color'] as Color),
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      width: double.infinity,
                      height: 42.h,
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
                            ? SizedBox(
                                width: 14.w,
                                height: 14.h,
                                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(selectedAction['icon'] as IconData, size: 16.sp),
                        label: Text(
                          _isProcessing ? 'Memproses...' : 'Terapkan Status: ${selectedAction['newStatus']}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5.sp),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedAction['color'] as Color,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoPhotoBox(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 30.sp,
            color: isDark ? Colors.white38 : Colors.grey[400],
          ),
          SizedBox(height: 6.h),
          Text(
            'Tidak ada lampiran foto bukti',
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.white54 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15.sp, color: _primaryBlue),
        SizedBox(width: 8.w),
        SizedBox(
          width: 95.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5.sp,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: text,
          fontSize: 10.5.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
