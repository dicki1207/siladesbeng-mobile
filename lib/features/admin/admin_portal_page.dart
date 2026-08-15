import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/features/admin/admin_report_page.dart';
import 'package:siladesbeng_mobile/features/admin/admin_warga_list_page.dart';
import 'package:siladesbeng_mobile/features/profile/event_gotong_royong_page.dart';
import 'package:siladesbeng_mobile/services/admin_wilayah_service.dart';

class AdminPortalPage extends StatefulWidget {
  const AdminPortalPage({super.key});

  @override
  State<AdminPortalPage> createState() => _AdminPortalPageState();
}

class _AdminPortalPageState extends State<AdminPortalPage> {
  String _role = 'rt';
  String _adminName = 'Pengurus Wilayah';

  // API Service & Data
  final AdminWilayahService _wilayahService = AdminWilayahService();
  int _totalLaporan = 0;
  int _laporanBaru = 0;
  int _laporanSelesai = 0;
  int _totalWarga = 0;
  String _slaStatus = 'aman';
  bool _hasPending = false;
  List<Map<String, dynamic>> _laporanTerbaru = [];

  // Live Countdown Timer for Report Service Level Agreement (SLA)
  late Timer _timer;
  int _remainingSeconds = 10800; // Default 3 Jam

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
    _loadDashboardStats();

    // Setup live countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _remainingSeconds = 10800;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadAdminProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        String loadedRole = prefs.getString('user_role') ?? 'rt';
        if (loadedRole != 'rt' && loadedRole != 'rw') {
          loadedRole = 'rt';
        }
        _role = loadedRole;
        _adminName = prefs.getString('profile_name') ?? 'Pengurus Wilayah';
      });
    }
  }

  Future<void> _loadDashboardStats() async {
    final result = await _wilayahService.getDashboardStats();
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'];
      final statistik = data['statistik'] ?? {};
      final sla = data['sla'] ?? {};
      final laporanList = data['laporan_terbaru'] as List? ?? [];

      setState(() {
        _totalLaporan = statistik['total_laporan'] ?? 0;
        _laporanBaru = statistik['laporan_baru'] ?? 0;
        _laporanSelesai = statistik['laporan_selesai'] ?? 0;
        _totalWarga = statistik['total_warga'] ?? 0;
        _slaStatus = sla['status'] ?? 'aman';
        _hasPending = sla['has_pending'] ?? false;

        final int oldestMinutes = sla['oldest_pending_minutes'] ?? 0;
        final int elapsedSeconds = oldestMinutes * 60;
        _remainingSeconds = (10800 - elapsedSeconds).clamp(0, 10800);

        _laporanTerbaru = laporanList.map<Map<String, dynamic>>((item) {
          return Map<String, dynamic>.from(item);
        }).toList();
      });
    }
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    String hStr = hours.toString().padLeft(2, '0');
    String mStr = minutes.toString().padLeft(2, '0');
    String sStr = seconds.toString().padLeft(2, '0');
    return '$hStr : $mStr : $sStr';
  }

  void _showInfoDialog(String title, String content, IconData icon) {
    final primaryColor = Theme.of(context).primaryColor;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: const TextStyle(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

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
          'Portal Pengurus',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        centerTitle: false,
        actions: [
          // Sleek Compact Role Switcher Pill
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRolePill('rt', 'RT 02', isDark),
                _buildRolePill('rw', 'RW 01', isDark),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardStats,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. GREETING & WILAYAH IDENTITY
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, $_adminName',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _role == 'rw'
                              ? 'Koordinator Wilayah RW 01'
                              : 'Ketua Wilayah RT 02 / RW 01',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryColor.withAlpha(40)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user_rounded, size: 13, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'Desa Pematang',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 2. STATUS RESPON ADUAN & SLA (CLEAN UNIFIED BLUE STYLE)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3B82F6).withAlpha(80)
                        : const Color(0xFFBFDBFE),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withAlpha(isDark ? 30 : 15),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.timer_outlined,
                                color: Color(0xFF2563EB),
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Target Respon Aduan (SLA)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E3A8A).withAlpha(80)
                                : const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _hasPending ? 'Perlu Ditinjau' : 'Terkendali',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFBFDBFE) : const Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _hasPending
                          ? 'Ada $_laporanBaru aduan warga baru yang menunggu verifikasi Anda.'
                          : 'Semua aduan warga di wilayah Anda telah ditindaklanjuti.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black.withAlpha(60) : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: isDark ? Colors.white60 : Colors.grey[600],
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _formatTime(_remainingSeconds),
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AdminReportPage()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Buka Aduan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. STATISTIK UTAMA (3 UNIFIED CARDS)
              Row(
                children: [
                  Expanded(
                    child: _buildUnifiedStatCard(
                      context: context,
                      title: 'Aduan Masuk',
                      count: _totalLaporan,
                      subtext: '$_laporanBaru Baru',
                      icon: Icons.assignment_outlined,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildUnifiedStatCard(
                      context: context,
                      title: _role == 'rw' ? 'Wilayah RT' : 'Terselesaikan',
                      count: _role == 'rw' ? 4 : _laporanSelesai,
                      subtext: _role == 'rw' ? 'RT Aktif' : 'Diproses',
                      icon: _role == 'rw' ? Icons.account_tree_outlined : Icons.check_circle_outline,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildUnifiedStatCard(
                      context: context,
                      title: 'Warga Wilayah',
                      count: _totalWarga,
                      subtext: 'KK Terdata',
                      icon: Icons.groups_outlined,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 4. MULTI-RT MONITOR (KHUSUS KOORDINATOR RW)
              if (_role == 'rw') ...[
                _buildRwMultiRtSection(context, isDark),
                const SizedBox(height: 24),
              ],

              // 5. MENU KENDALI OPERASIONAL (UNIFIED 2x2 GRID)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Menu Operasional',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Layanan Wilayah',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white54 : Colors.grey[500],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildCleanCommandCard(
                      context: context,
                      title: 'Kelola Laporan',
                      subtitle: 'Verifikasi aduan warga',
                      icon: Icons.assignment_outlined,
                      badge: _laporanBaru > 0 ? '$_laporanBaru Baru' : null,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminReportPage()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCleanCommandCard(
                      context: context,
                      title: 'Agenda & Event',
                      subtitle: 'Gotong royong & kegiatan',
                      icon: Icons.campaign_outlined,
                      badge: null,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EventGotongRoyongPage()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildCleanCommandCard(
                      context: context,
                      title: 'Data Warga',
                      subtitle: 'Daftar kepala keluarga',
                      icon: Icons.folder_shared_outlined,
                      badge: null,
                      isDark: isDark,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminWargaListPage(
                              role: _role,
                              filterRt: _role == 'rw' ? 'Seluruh RW 01' : 'RT 02 / RW 01',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCleanCommandCard(
                      context: context,
                      title: 'Statistik Wilayah',
                      subtitle: 'Analisa grafik & rekap',
                      icon: Icons.analytics_outlined,
                      badge: null,
                      isDark: isDark,
                      onTap: () {
                        final pctSelesai = _totalLaporan > 0
                            ? ((_laporanSelesai / _totalLaporan) * 100).round()
                            : 0;
                        _showInfoDialog(
                          'Statistik Pelayanan Wilayah',
                          '• Total Aduan Masuk: $_totalLaporan\n• Ditindaklanjuti Selesai: $_laporanSelesai ($pctSelesai%)\n• Menunggu Respon: $_laporanBaru\n• Total KK Terdaftar: $_totalWarga KK\n\nStatus SLA Respon: ${_slaStatus.toUpperCase()}',
                          Icons.analytics_outlined,
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 6. LOG AKTIVITAS TERKINI
              Container(
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
                      children: [
                        Text(
                          'Log Aktivitas Terkini',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withAlpha(15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Realtime',
                            style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_laporanTerbaru.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Belum ada aktivitas aduan terbaru',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: isDark ? Colors.white54 : Colors.grey[500],
                            ),
                          ),
                        ),
                      )
                    else
                      ..._laporanTerbaru.asMap().entries.map((entry) {
                        final item = entry.value;
                        final isLast = entry.key == _laporanTerbaru.length - 1;
                        final status = item['status'] ?? 'Pending';

                        final createdAt = item['created_at'] ?? '';
                        String timeAgo = createdAt;
                        try {
                          final dt = DateTime.parse(createdAt);
                          final diff = DateTime.now().difference(dt);
                          if (diff.inMinutes < 60) {
                            timeAgo = '${diff.inMinutes} mnt lalu';
                          } else if (diff.inHours < 24) {
                            timeAgo = '${diff.inHours} jam lalu';
                          } else {
                            timeAgo = '${diff.inDays} hr lalu';
                          }
                        } catch (_) {}

                        return Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withAlpha(18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_outlined,
                                    color: Color(0xFF2563EB),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['kategori'] ?? item['deskripsi'] ?? 'Laporan Warga',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Pelapor: ${item['pelapor'] ?? 'Warga'} • $status',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  timeAgo,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark ? Colors.white38 : Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                            if (!isLast) const Divider(height: 20),
                          ],
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET: Compact Role Switcher Pill
  Widget _buildRolePill(String roleKey, String label, bool isDark) {
    final bool isSelected = _role == roleKey;
    return GestureDetector(
      onTap: () => setState(() => _role = roleKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // WIDGET: Unified Clean Stat Card
  Widget _buildUnifiedStatCard({
    required BuildContext context,
    required String title,
    required int count,
    required String subtext,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: const Color(0xFF2563EB), size: 17),
              const SizedBox(width: 4),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withAlpha(15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      subtext,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // WIDGET: Clean Command Card (Unified Blue Accent)
  Widget _buildCleanCommandCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String? badge,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 20 : 6),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withAlpha(18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET: Multi-RT Summary Section for RW
  Widget _buildRwMultiRtSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Monitoring Wilayah RW 01',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withAlpha(15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '4 RT Terhubung',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCleanRtCard(
          context: context,
          isDark: isDark,
          rtName: 'RT 01 / RW 01',
          chairman: 'Bpk. Wayan Darma',
          kkCount: '36 KK',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminWargaListPage(role: 'rw', filterRt: 'RT 01 / RW 01'),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _buildCleanRtCard(
          context: context,
          isDark: isDark,
          rtName: 'RT 02 / RW 01',
          chairman: 'I Nyoman Suartha',
          kkCount: '42 KK',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminWargaListPage(role: 'rw', filterRt: 'RT 02 / RW 01'),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _buildCleanRtCard(
          context: context,
          isDark: isDark,
          rtName: 'RT 03 / RW 01',
          chairman: 'Bpk. Ketut Santika',
          kkCount: '35 KK',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminWargaListPage(role: 'rw', filterRt: 'RT 03 / RW 01'),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        _buildCleanRtCard(
          context: context,
          isDark: isDark,
          rtName: 'RT 04 / RW 01',
          chairman: 'Bpk. Gede Arini',
          kkCount: '35 KK',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminWargaListPage(role: 'rw', filterRt: 'RT 04 / RW 01'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCleanRtCard({
    required BuildContext context,
    required bool isDark,
    required String rtName,
    required String chairman,
    required String kkCount,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withAlpha(18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.home_work_outlined,
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rtName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '$chairman • $kkCount',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white38 : Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
