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
  static const Color _primaryBlue = Color(0xFF2563EB);

  String _role = 'rt';
  String _adminName = 'Pengurus Wilayah';

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
          'Portal Pengurus',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
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
        color: _primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Sleek Compact Identity Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _primaryBlue.withAlpha(isDark ? 40 : 15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.shield_rounded, size: 20, color: _primaryBlue),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _adminName,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _role == 'rw'
                                ? 'Koordinator Wilayah RW 01'
                                : 'Ketua Wilayah RT 02 / RW 01',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _primaryBlue.withAlpha(isDark ? 30 : 12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Desa Pematang',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: _primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2. Alert Banner (jika ada aduan baru)
              if (_laporanBaru > 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withAlpha(isDark ? 30 : 12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _primaryBlue.withAlpha(isDark ? 60 : 30),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: _primaryBlue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$_laporanBaru aduan warga baru menunggu verifikasi.',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AdminReportPage()),
                          );
                        },
                        child: const Text(
                          'Tinjau ›',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: _primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 3. Compact 3-Metrik Statistik Row
              Row(
                children: [
                  Expanded(
                    child: _buildCompactStatCard(
                      title: 'Aduan Masuk',
                      count: _totalLaporan,
                      subtext: '$_laporanBaru Baru',
                      icon: Icons.inbox_rounded,
                      isDark: isDark,
                      color: _primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactStatCard(
                      title: 'Dalam Proses',
                      count: _laporanDiproses,
                      subtext: 'Ditangani',
                      icon: Icons.pending_actions_rounded,
                      isDark: isDark,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactStatCard(
                      title: 'Selesai',
                      count: _laporanSelesai,
                      subtext: 'Selesai',
                      icon: Icons.check_circle_outline_rounded,
                      isDark: isDark,
                      color: const Color(0xFF059669),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 4. Header Layanan Wilayah
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
                    'Layanan Wilayah',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 5. Minimalist Compact Action Tiles (Hemat Ruang & Rapi)
              _buildSlimActionTile(
                isDark: isDark,
                icon: Icons.assignment_turned_in_outlined,
                title: 'Kelola Pengaduan Warga',
                subtitle: 'Tindak lanjuti dan teruskan aspirasi/aduan warga',
                badge: _laporanBaru > 0 ? '$_laporanBaru Baru' : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminReportPage()),
                  );
                },
              ),
              const SizedBox(height: 6),

              _buildSlimActionTile(
                isDark: isDark,
                icon: Icons.campaign_outlined,
                title: 'Pengumuman & Gotong Royong',
                subtitle: 'Publikasi kegiatan dan agenda resmi lingkungan',
                badge: null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EventGotongRoyongPage()),
                  );
                },
              ),
              const SizedBox(height: 6),

              _buildSlimActionTile(
                isDark: isDark,
                icon: Icons.folder_shared_outlined,
                title: 'Buku Induk & Daftar Warga',
                subtitle: 'Data kependudukan, domisili, dan verifikasi KYC',
                badge: null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminWargaListPage(role: _role),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // 6. Aktivitas Terkini (Compact)
              Container(
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
                        Text(
                          'Aktivitas Aduan Terkini',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _primaryBlue.withAlpha(15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Realtime',
                            style: TextStyle(
                              color: _primaryBlue,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_laporanTerbaru.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'Belum ada aktivitas aduan terbaru',
                            style: TextStyle(
                              fontSize: 12,
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

                        return Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _primaryBlue.withAlpha(15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_outlined,
                                    color: _primaryBlue,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['kategori'] ?? item['deskripsi'] ?? 'Laporan Warga',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'Pelapor: ${item['pelapor'] ?? 'Warga'} • $status',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (!isLast) const Divider(height: 12),
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

  Widget _buildRolePill(String roleKey, String label, bool isDark) {
    final bool isSelected = _role == roleKey;
    return GestureDetector(
      onTap: () => setState(() => _role = roleKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? _primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatCard({
    required String title,
    required int count,
    required String subtext,
    required IconData icon,
    required bool isDark,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              Icon(icon, color: color, size: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withAlpha(isDark ? 30 : 12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  subtext,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSlimActionTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required String? badge,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withAlpha(isDark ? 35 : 12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 17, color: _primaryBlue),
                ),
                const SizedBox(width: 10),
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
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withAlpha(15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badge,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
