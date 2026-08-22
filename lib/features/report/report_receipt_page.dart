import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportReceiptPage extends StatefulWidget {
  final String reportId;
  final String category;
  final String date;
  final String description;
  final String status;
  final Color statusColor;
  final Map<String, dynamic>? rawData;

  const ReportReceiptPage({
    super.key,
    required this.reportId,
    required this.category,
    required this.date,
    required this.description,
    required this.status,
    required this.statusColor,
    this.rawData,
  });

  @override
  State<ReportReceiptPage> createState() => _ReportReceiptPageState();
}

class _ReportReceiptPageState extends State<ReportReceiptPage> {
  bool _isDownloadingPdf = false;
  Map<String, dynamic>? _detailData;

  @override
  void initState() {
    super.initState();
    _detailData = widget.rawData != null
        ? Map<String, dynamic>.from(widget.rawData!)
        : null;
    _fetchDetailIfNeeded();
  }

  String get _cleanId {
    return widget.reportId.replaceAll(RegExp(r'[^0-9]'), '');
  }

  String get _referenceNumber {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    final cleanId = _cleanId;
    final paddedId = cleanId.isNotEmpty ? cleanId.padLeft(5, '0') : '00001';
    return 'SDB/$year/$month/$paddedId';
  }

  Future<void> _fetchDetailIfNeeded() async {
    final id = _cleanId;
    if (id.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/laporan/$id'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final jsonResponse = jsonDecode(res.body);
        if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
          if (mounted) {
            setState(() {
              _detailData = Map<String, dynamic>.from(jsonResponse['data']);
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _downloadPdf() async {
    setState(() => _isDownloadingPdf = true);

    try {
      final id = _cleanId;
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      final downloadUrl = token != null && token.isNotEmpty
          ? '${ApiConfig.baseUrl}/user/laporan/export/$id?token=$token'
          : '${ApiConfig.baseUrl}/user/laporan/export/$id';

      final uri = Uri.parse(downloadUrl);

      // Download file secara native (tanpa browser)
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Ambil direktori sementara (cache)
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/Bukti_Laporan_$id.pdf');
        
        // Simpan file
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          // Buka fitur Share / Simpan native device
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path)],
              text: 'Bukti Pelaporan Resmi: $id',
              subject: 'Bukti Laporan - SilaDesBeng',
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengunduh dokumen PDF dari server'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingPdf = false);
      }
    }
  }

  void _shareReceipt() {
    final ref = _referenceNumber;
    final shareText = '''📄 BUKTI REGISTRASI PELAPORAN WARGA
Platform E-Government Sila-DesBeng

• No. Registrasi : $ref
• ID Laporan     : #${widget.reportId}
• Kategori       : ${widget.category}
• Tanggal        : ${widget.date}
• Status         : ${widget.status.toUpperCase()}

Isi Laporan:
"${widget.description}"

Dokumen ini diterbitkan secara sah oleh Sistem E-Government Sila-DesBeng Kabupaten Bengkalis.''';

    SharePlus.instance.share(ShareParams(text: shareText));
  }

  List<String> _extractBuktiImages() {
    if (_detailData == null) return [];

    // Check bukti_urls from show API
    if (_detailData!['bukti_urls'] is List) {
      return List<String>.from(_detailData!['bukti_urls']);
    }

    final rawBukti = _detailData!['bukti'] ?? _detailData!['foto_bukti'];
    if (rawBukti == null) return [];

    final str = rawBukti.toString().trim();
    if (str.isEmpty) return [];

    if (str.startsWith('[')) {
      try {
        final List<dynamic> decoded = jsonDecode(str);
        return decoded.map((e) => _formatImageUrl(e.toString())).toList();
      } catch (_) {}
    }

    return [_formatImageUrl(str)];
  }

  String _formatImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final clean = path.startsWith('/') ? path.substring(1) : path;
    if (clean.startsWith('storage/')) {
      return '${ApiConfig.baseUrl}/$clean';
    }
    return '${ApiConfig.baseUrl}/storage/$clean';
  }

  void _openImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              clipBehavior: Clip.none,
              minScale: 0.8,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (c, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 250,
                      child: Center(child: CircularProgressIndicator(color: Colors.white)),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(24),
                    color: Colors.black87,
                    child: const Text('Gagal memuat gambar bukti', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
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
    final primaryTeal = const Color(0xFF0284C7);
    final statusColor = widget.statusColor;

    final namaPelapor = _detailData?['user']?['name'] ??
        _detailData?['nama'] ??
        'Warga Terdaftar';
    final isKycVerified = _detailData?['user']?['is_verified'] == true;
    final rt = _detailData?['rt_number'] ?? _detailData?['rt'] ?? '-';
    final rw = _detailData?['rw_number'] ?? _detailData?['rw'] ?? '-';
    final lokasi = _detailData?['lokasi']?.toString() ?? '';
    final lat = _detailData?['latitude']?.toString();
    final lng = _detailData?['longitude']?.toString();
    final catatanAdmin = _detailData?['catatan_admin'] ??
        _detailData?['catatan_rw'] ??
        _detailData?['catatan_rt'];
    final handlerName = _detailData?['handler_name'] ?? 'Pemerintah Desa Bengkalis';
    final escalation = _detailData?['escalation_level']?.toString().toUpperCase() ?? 'DESA';

    final buktiImages = _extractBuktiImages();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Bukti Registrasi Laporan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Bagikan Bukti',
            onPressed: _shareReceipt,
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Unduh PDF',
            onPressed: _downloadPdf,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          children: [
            // Main Certificate Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Certificate Top Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                            : [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(19),
                        topRight: Radius.circular(19),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_user_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'PEMERINTAH KABUPATEN BENGKALIS',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Text(
                                  'SILA-DESBENG E-GOVERNMENT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            'BUKTI REGISTRASI PELAPORAN WARGA',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ref: $_referenceNumber',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status Banner Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    color: statusColor.withValues(alpha: isDark ? 0.18 : 0.08),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 18, color: statusColor),
                            const SizedBox(width: 8),
                            Text(
                              'Status Terkini:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Section I: Identitas Pelapor
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(
                          context,
                          title: 'I. Identitas Pelapor & Wilayah',
                          icon: Icons.person_pin_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoTile(
                          context,
                          label: 'Nama Pelapor',
                          valueWidget: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  namaPelapor,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              if (isKycVerified) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                  ),
                                  child: const Text(
                                    'e-KTP Valid',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        _buildInfoTile(
                          context,
                          label: 'Tanggal Pengajuan',
                          valueText: widget.date,
                        ),
                        _buildInfoTile(
                          context,
                          label: 'Kategori Laporan',
                          valueWidget: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primaryTeal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.category,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: primaryTeal,
                              ),
                            ),
                          ),
                        ),
                        _buildInfoTile(
                          context,
                          label: 'Wilayah Domisili',
                          valueText: 'RT $rt / RW $rw',
                        ),
                        _buildInfoTile(
                          context,
                          label: 'Tingkat Penanganan',
                          valueText: 'Tingkat $escalation',
                        ),

                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),

                        // Section II: Isi Aduan
                        _buildSectionHeader(
                          context,
                          title: 'II. Rincian & Deskripsi Laporan',
                          icon: Icons.article_outlined,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            widget.description,
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.5,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          ),
                        ),

                        // Section III: Lokasi (jika ada)
                        if (lokasi.isNotEmpty || (lat != null && lng != null)) ...[
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 20),
                          _buildSectionHeader(
                            context,
                            title: 'III. Lokasi Kejadian',
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white12 : const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (lokasi.isNotEmpty) ...[
                                  Text(
                                    lokasi,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF166534),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                if (lat != null && lng != null) ...[
                                  Row(
                                    children: [
                                      const Icon(Icons.satellite_alt_rounded, size: 14, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Text(
                                        'GPS: $lat, $lng',
                                        style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                                      ),
                                      const Spacer(),
                                      InkWell(
                                        onTap: () async {
                                          final mapUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                                          if (await canLaunchUrl(mapUri)) {
                                            await launchUrl(mapUri, mode: LaunchMode.externalApplication);
                                          }
                                        },
                                        child: Row(
                                          children: [
                                            Text(
                                              'Buka Maps',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: primaryTeal,
                                              ),
                                            ),
                                            Icon(Icons.arrow_forward_ios_rounded, size: 11, color: primaryTeal),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        // Section IV: Foto Bukti Visual (jika ada)
                        if (buktiImages.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 20),
                          _buildSectionHeader(
                            context,
                            title: 'IV. Lampiran Bukti Foto (${buktiImages.length})',
                            icon: Icons.photo_library_outlined,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 110,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: buktiImages.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 10),
                              itemBuilder: (ctx, idx) {
                                final imgUrl = buktiImages[idx];
                                return GestureDetector(
                                  onTap: () => _openImagePreview(imgUrl),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          width: 130,
                                          height: 110,
                                          color: isDark ? Colors.black26 : Colors.grey[200],
                                          child: Image.network(
                                            imgUrl,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (c, child, progress) {
                                              if (progress == null) return child;
                                              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                            },
                                            errorBuilder: (context, error, stackTrace) => const Center(
                                              child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 6,
                                        right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '💡 Ketuk foto untuk melihat pratinjau penuh',
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        ],

                        // Section V: Catatan Admin (jika ada)
                        if (catatanAdmin != null && catatanAdmin.toString().isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Divider(height: 1),
                          const SizedBox(height: 20),
                          _buildSectionHeader(
                            context,
                            title: 'V. Catatan Penanganan Resmi',
                            icon: Icons.rate_review_outlined,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.white12 : const Color(0xFFBFDBFE),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.account_balance_rounded, size: 16, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Oleh: $handlerName',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  catatanAdmin.toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: isDark ? Colors.white70 : const Color(0xFF1E3A8A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        const Divider(height: 1),
                        const SizedBox(height: 20),

                        // Section VI: Keabsahan & TTD Elektronik
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              // QR Code
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: QrImageView(
                                  data: '${ApiConfig.baseUrl}/validasi/laporan/$_cleanId',
                                  version: QrVersions.auto,
                                  size: 76,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TANDA TANGAN ELEKTRONIK',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      handlerName,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: primaryTeal,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Dokumen ini sah & diterbitkan oleh Platform Resmi E-Government Sila-DesBeng.',
                                      style: TextStyle(fontSize: 10.5, color: Colors.grey, height: 1.3),
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
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Download PDF Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isDownloadingPdf ? null : _downloadPdf,
                icon: _isDownloadingPdf
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                label: Text(
                  _isDownloadingPdf ? 'Menyiapkan PDF...' : 'Unduh PDF Bukti Laporan Resmi',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0EA5E9)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required String label,
    String? valueText,
    Widget? valueWidget,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ),
          const Text(' : ', style: TextStyle(color: Colors.grey, fontSize: 12.5)),
          Expanded(
            child: valueWidget ??
                Text(
                  valueText ?? '-',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

