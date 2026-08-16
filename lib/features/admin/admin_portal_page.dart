import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/features/admin/admin_report_page.dart';
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
  int _laporanDiproses = 0;
  int _laporanSelesai = 0;
  List<Map<String, dynamic>> _laporanTerbaru = [];

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
    _loadDashboardStats();
  }

  @override
  void dispose() {
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
      final laporanList = data['laporan_terbaru'] as List? ?? [];

      setState(() {
        _totalLaporan = statistik['total_laporan'] ?? 0;
        _laporanBaru = statistik['laporan_baru'] ?? 0;
        _laporanSelesai = statistik['laporan_selesai'] ?? 0;
        _laporanDiproses = (_totalLaporan - _laporanBaru - _laporanSelesai).clamp(0, 999);

        _laporanTerbaru = laporanList.map<Map<String, dynamic>>((item) {
          return Map<String, dynamic>.from(item);
        }).toList();
      });
    }
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
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
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
                            fontSize: 13,
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
                      color: primaryColor.withAlpha(18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryColor.withAlpha(35)),
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

              const SizedBox(height: 16),

              // 2. ALERT BANNER JIKA ADA ADUAN BARU
              if (_laporanBaru > 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withAlpha(isDark ? 30 : 15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF2563EB).withAlpha(isDark ? 60 : 35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.priority_high_rounded, color: Colors.white, size: 12),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ada $_laporanBaru aduan warga baru yang menunggu verifikasi Anda.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminReportPage()),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                          child: Text(
                            'Tinjau ›',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 18),

              // 3. STATISTIK ADUAN (3 RINGKASAN: MASUK, DIPROSES, SELESAI)
              Row(
                children: [
                  Expanded(
                    child: _buildUnifiedStatCard(
                      context: context,
                      title: 'Aduan Masuk',
                      count: _totalLaporan,
                      subtext: '$_laporanBaru Baru',
                      icon: Icons.inbox_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildUnifiedStatCard(
                      context: context,
                      title: 'Dalam Proses',
                      count: _laporanDiproses,
                      subtext: 'Ditangani',
                      icon: Icons.pending_actions_rounded,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildUnifiedStatCard(
                      context: context,
                      title: 'Terselesaikan',
                      count: _laporanSelesai,
                      subtext: 'Selesai',
                      icon: Icons.check_circle_outline_rounded,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // 4. MENU UTAMA OPERASIONAL (FOKUS: LAPORAN & PENGUMUMAN)
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
                    'Layanan Wilayah',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // KARTU 1: KELOLA PENGADUAN WARGA
              _buildOperationalActionCard(
                context: context,
                isDark: isDark,
                title: 'Kelola Pengaduan Warga',
                description: 'Verifikasi, tindak lanjuti, dan teruskan aspirasi serta aduan dari warga lingkungan Anda.',
                icon: Icons.assignment_turned_in_outlined,
                badge: _laporanBaru > 0 ? '$_laporanBaru Aduan Baru' : null,
                buttonText: 'Buka Pengaduan',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminReportPage()),
                  );
                },
              ),

              const SizedBox(height: 12),

              // KARTU 2: PENGUMUMAN & GOTONG ROYONG
              _buildOperationalActionCard(
                context: context,
                isDark: isDark,
                title: 'Pengumuman & Gotong Royong',
                description: 'Publikasikan kegiatan gotong royong, agenda rapat, dan pengumuman resmi lingkungan.',
                icon: Icons.campaign_rounded,
                badge: null,
                buttonText: 'Buka Pengumuman',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EventGotongRoyongPage()),
                  );
                },
              ),

              const SizedBox(height: 24),

              // 5. LOG AKTIVITAS TERKINI
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
                          'Aktivitas Aduan Terkini',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
                              fontSize: 10,
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
                            if (!isLast) const Divider(height: 18),
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

  // WIDGET: Role Switcher Pill
  Widget _buildRolePill(String roleKey, String label, bool isDark) {
    final bool isSelected = _role == roleKey;
    return GestureDetector(
      onTap: () => setState(() => _role = roleKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
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

  // WIDGET: Unified Stat Card
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

  // WIDGET: Spacious Operational Action Card
  Widget _buildOperationalActionCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required String description,
    required IconData icon,
    required String? badge,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withAlpha(18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 22, color: const Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              if (badge != null) ...[
                                const SizedBox(width: 6),
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
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: Color(0xFF2563EB),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
