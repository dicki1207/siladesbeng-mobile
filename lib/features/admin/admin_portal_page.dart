import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/features/admin/admin_report_page.dart';
import 'package:siladesbeng_mobile/features/admin/admin_warga_list_page.dart';
import 'package:siladesbeng_mobile/features/profile/event_gotong_royong_page.dart';

class AdminPortalPage extends StatefulWidget {
  const AdminPortalPage({super.key});

  @override
  State<AdminPortalPage> createState() => _AdminPortalPageState();
}

class _AdminPortalPageState extends State<AdminPortalPage>
    with SingleTickerProviderStateMixin {
  String _role = 'rt';
  String _adminName = 'Aparat Desa';

  // Live Countdown Timer for Report Service Level Agreement (SLA)
  late Timer _timer;
  int _remainingSeconds = 7485; // 2 Jam : 4 Menit : 45 Detik
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();

    // Setup animated live pulsing indicator
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Setup live countdown timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _remainingSeconds = 10800; // Reset siklus countdown
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        String loadedRole = prefs.getString('user_role') ?? 'rt';
        if (loadedRole != 'rt' && loadedRole != 'rw') {
          loadedRole = 'rt'; // Set default ke 'rt' untuk tampilan tes pengurus
        }
        _role = loadedRole;
        _adminName = prefs.getString('profile_name') ?? 'Admin Pengurus';
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

  void _showInfoDialog(String title, String content, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.6,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Tutup & Mengerti',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final String roleText = _role.toUpperCase();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // PREMIUM ULTRA-HERO HEADER
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E3A8A),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF021B3A), const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
                        : [const Color(0xFF1D4ED8), const Color(0xFF2563EB), const Color(0xFF1E40AF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      top: -30,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(15),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: 10,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF59E0B).withAlpha(25),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.amber.withAlpha(60),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.shield_rounded,
                                        color: Colors.black87,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(110),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: const Color(0xFFF59E0B).withAlpha(200),
                                          width: 1.4,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FadeTransition(
                                            opacity: _pulseAnimation,
                                            child: const Icon(
                                              Icons.radio_button_checked_rounded,
                                              color: Color(0xFF10B981),
                                              size: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'PENGURUS • $roleText',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'SILA-DESBENG',
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(150),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11.5,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Pusat Kendali Pengurus',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Halo, $_adminName • Semua layanan aktif dalam pengawasan Anda',
                              style: TextStyle(
                                color: Colors.white.withAlpha(220),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // BODY CONTENT WITH LIVE COUNTDOWN & KPI DASHBOARD
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 0. INTERACTIVE HIERARCHY SWITCHER BAR (SIMULATOR TESTING)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 22),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withAlpha(80),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 20 : 10),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.layers_rounded,
                              color: Color(0xFF3B82F6),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'HIERARKI TAMPILAN (SIMULATOR MULTI-LEVEL)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.blueAccent
                                      : Colors.blue.shade800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRoleSegmentButton(
                                context: context,
                                title: 'Mode Ketua RT 02',
                                subtitle: 'Fokus Wilayah RT',
                                isSelected: _role == 'rt',
                                onTap: () {
                                  setState(() => _role = 'rt');
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildRoleSegmentButton(
                                context: context,
                                title: 'Mode Koordinator RW 01',
                                subtitle: 'Rekap Multi-RT (01-04)',
                                isSelected: _role == 'rw',
                                onTap: () {
                                  setState(() => _role = 'rw');
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 1. EKSKLUSIF: LIVE ACTION COUNTDOWN MONITOR (ZERO OVERFLOW PROTECTED)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF450A0A), const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                            : [const Color(0xFFFEF3C7), const Color(0xFFFCE7F3), const Color(0xFFEFF6FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.redAccent.withAlpha(100) : Colors.orange.withAlpha(150),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withAlpha(80) : Colors.orange.withAlpha(35),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            FadeTransition(
                              opacity: _pulseAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(40),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.timer_rounded,
                                  color: Colors.redAccent,
                                  size: 24,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TARGET RESPON LAPORAN (SLA)',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      color: isDark ? Colors.orangeAccent : Colors.orange.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '3 Laporan Masuk Menunggu Tindak Lanjut!',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : Colors.grey.shade900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Animated Digital Countdown Box - Zero Overflow
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black.withAlpha(140) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withAlpha(40)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_alarms_rounded, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sisa Waktu Respon:',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withAlpha(25),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.redAccent),
                                ),
                                child: Text(
                                  _formatTime(_remainingSeconds),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.redAccent,
                                    fontFamily: 'Courier',
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const AdminReportPage()),
                              );
                            },
                            icon: const Icon(Icons.flash_on_rounded, size: 19),
                            label: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'VERIFIKASI LAPORAN SEKARANG',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.4),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.black87,
                              elevation: 4,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  // 2. ANIMATED COUNT-UP KPI STATS ROW (PERFECT FIT - ZERO OVERFLOW)
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnimatedStatCard(
                          context: context,
                          title: 'Laporan',
                          targetCount: _role == 'rw' ? 28 : 12,
                          badge: _role == 'rw' ? '8 Baru' : '3 Baru',
                          icon: Icons.assignment_turned_in_rounded,
                          color: const Color(0xFFF59E0B),
                          progressText: '75% Selesai',
                          progressValue: 0.75,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAnimatedStatCard(
                          context: context,
                          title: _role == 'rw' ? 'Wilayah' : 'Agenda',
                          targetCount: _role == 'rw' ? 4 : 5,
                          badge: _role == 'rw' ? 'RT Aktif' : 'Aktif',
                          icon: _role == 'rw'
                              ? Icons.account_tree_rounded
                              : Icons.campaign_rounded,
                          color: const Color(0xFF10B981),
                          progressText: _role == 'rw' ? '100% Terpantau' : '100% Siap',
                          progressValue: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAnimatedStatCard(
                          context: context,
                          title: _role == 'rw' ? 'Warga RW' : 'Warga RT',
                          targetCount: _role == 'rw' ? 148 : 42,
                          badge: 'KK Valid',
                          icon: Icons.groups_rounded,
                          color: const Color(0xFF3B82F6),
                          progressText: '98% Sync',
                          progressValue: 0.98,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 2.5 HIERARCHY REKAP MULTI-RT SECTION (EKSKLUSIF KOORDINATOR RW)
                  if (_role == 'rw') ...[
                    _buildRwMultiRtMonitor(context, isDark),
                    const SizedBox(height: 32),
                  ],

                  // 3. SECTION TITLE: KENDALI OPERASIONAL
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0284C7), Color(0xFF3B82F6)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Menu Kendali Operasional',
                            style: TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Akses Cepat',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kelola verifikasi aduan dan pengumuman desa dengan instan',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(160),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 4. LUXURIOUS COMMAND CARDS (GRID 2x2)
                  Row(
                    children: [
                      Expanded(
                        child: _buildCommandCard(
                          context: context,
                          title: 'Kelola Laporan\nWarga',
                          subtitle: 'Verifikasi status,\ngeotagging & keputusan',
                          icon: Icons.assignment_turned_in_rounded,
                          accentColor: const Color(0xFFF59E0B),
                          badgeText: '3 Menunggu',
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
                        child: _buildCommandCard(
                          context: context,
                          title: 'Buat Pengumuman\n& Event Desa',
                          subtitle: 'Publikasi kerja bakti\n& agenda gotong royong',
                          icon: Icons.campaign_rounded,
                          accentColor: const Color(0xFF10B981),
                          badgeText: 'Live Feed',
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
                        child: _buildCommandCard(
                          context: context,
                          title: 'Data Warga &\nDomisili',
                          subtitle: 'Daftar kepala keluarga\n& validasi surat desa',
                          icon: Icons.folder_shared_rounded,
                          accentColor: const Color(0xFF3B82F6),
                          badgeText: '148 KK',
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
                        child: _buildCommandCard(
                          context: context,
                          title: 'Laporan Statistik\n& Analitik',
                          subtitle: 'Analisa grafik aduan\n& pencapaian kinerja',
                          icon: Icons.analytics_rounded,
                          accentColor: const Color(0xFF8B5CF6),
                          badgeText: 'Optimal',
                          onTap: () {
                            _showInfoDialog(
                              'Statistik Pelayanan Bulan Ini',
                              '• Laporan Aduan Masuk: 12\n• Ditindaklanjuti & Selesai: 9 (75%)\n• Dalam Proses Verifikasi: 3 (25%)\n• Agenda Gotong Royong: 2 Kegiatan Sukses.\n\nKinerja pengurusan wilayah Anda tergolong SANGAT OPTIMAL!',
                              Icons.analytics_rounded,
                              const Color(0xFF8B5CF6),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 34),

                  // 5. RECENT LOG ACTIVITY
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.withAlpha(40)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 30 : 15),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
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
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.history_rounded,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Log Aktivitas Terkini',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.fiber_manual_record, color: Colors.green, size: 10),
                                  SizedBox(width: 4),
                                  Text(
                                    'Realtime',
                                    style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildActivityLogItem(
                          context,
                          'Laporan Lampu Jalan Mati di Gang II',
                          'Pelapor: I Nyoman Suartha • Menunggu Verifikasi',
                          '10 Mnt lalu',
                          Icons.warning_amber_rounded,
                          Colors.amber.shade700,
                        ),
                        const Divider(height: 26),
                        _buildActivityLogItem(
                          context,
                          'Banjir Ringan di Pertigaan Pasar',
                          'Pelapor: Bpk. Hendrawan • Dalam Penanganan',
                          '28 Mnt lalu',
                          Icons.engineering_rounded,
                          Colors.blue.shade600,
                        ),
                        const Divider(height: 26),
                        _buildActivityLogItem(
                          context,
                          'Pengumuman Gotong Royong Bali Banjar',
                          'Diterbitkan oleh Admin $roleText • Dibaca 84 Warga',
                          '1 Hari lalu',
                          Icons.check_circle_outline_rounded,
                          Colors.green.shade600,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Animated Count-up Stat Card with Zero Text Clipping & Perfectly Fitted Layout
  Widget _buildAnimatedStatCard({
    required BuildContext context,
    required String title,
    required int targetCount,
    required String badge,
    required IconData icon,
    required Color color,
    required String progressText,
    required double progressValue,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(18),
            blurRadius: 10,
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
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(left: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: color,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: targetCount),
            duration: const Duration(milliseconds: 1800),
            curve: Curves.easeOutExpo,
            builder: (context, val, child) {
              return Text(
                '$val',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              );
            },
          ),
          const SizedBox(height: 3),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(180),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 9),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 4.0,
                  backgroundColor: color.withAlpha(35),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  progressText,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper: Luxurious Executive Command Cards
  Widget _buildCommandCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      elevation: 4,
      shadowColor: accentColor.withAlpha(35),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accentColor.withAlpha(70), width: 1.4),
            gradient: LinearGradient(
              colors: [
                isDark ? const Color(0xFF1E293B) : Colors.white,
                accentColor.withAlpha(12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -6,
                bottom: -6,
                child: Icon(
                  icon,
                  size: 58,
                  color: accentColor.withAlpha(20),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: accentColor.withAlpha(90), width: 1.2),
                        ),
                        child: Icon(icon, color: accentColor, size: 24),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accentColor.withAlpha(80)),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(175),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Activity Log Item
  Widget _buildActivityLogItem(
    BuildContext context,
    String title,
    String subtitle,
    String time,
    IconData icon,
    Color iconColor,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: iconColor.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(160),
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            time,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  // WIDGET HELPERS UNTUK HIERARKI MULTI-LEVEL (RW vs RT)
  Widget _buildRoleSegmentButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFF2563EB))
            : (isDark ? const Color(0xFF0F172A) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF3B82F6)
              : (isDark ? Colors.white12 : Colors.grey.shade300),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade800),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, size: 16, color: Colors.white)
                  else
                    Icon(Icons.radio_button_unchecked_rounded, size: 16, color: Colors.grey.shade500),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white.withAlpha(200) : Colors.grey.shade500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildRwMultiRtMonitor(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_tree_rounded, size: 20, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'MONITORING REKAP WILAYAH (RW 01)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.grey.shade900,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Pengawasan eksternal atas 4 RT terkoordinasi',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(180),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withAlpha(80)),
              ),
              child: const Text(
                '4 RT SYNCED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildRtSummaryCard(
          context: context,
          isDark: isDark,
          rtTitle: 'RT 01 / RW 01 • Banjar Kelod',
          chairman: 'Ketua: Bpk. Wayan Darma',
          kkCount: '36 KK',
          statusText: '99% Tervalidasi AI',
          isAllClear: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminWargaListPage(role: 'rw', filterRt: 'RT 01 / RW 01'),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildRtSummaryCard(
          context: context,
          isDark: isDark,
          rtTitle: 'RT 02 / RW 01 • Banjar Tengah',
          chairman: 'Ketua: I Nyoman Suartha',
          kkCount: '42 KK',
          statusText: '2 Butuh Validasi',
          isAllClear: false,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminWargaListPage(role: 'rw', filterRt: 'RT 02 / RW 01'),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildRtSummaryCard(
          context: context,
          isDark: isDark,
          rtTitle: 'RT 03 / RW 01 • Banjar Kaja',
          chairman: 'Ketua: Bpk. Ketut Santika',
          kkCount: '35 KK',
          statusText: '100% Tervalidasi AI',
          isAllClear: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminWargaListPage(role: 'rw', filterRt: 'RT 03 / RW 01'),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildRtSummaryCard(
          context: context,
          isDark: isDark,
          rtTitle: 'RT 04 / RW 01 • Banjar Kangin',
          chairman: 'Ketua: Bpk. Gede Arini',
          kkCount: '35 KK',
          statusText: '1 Butuh Validasi',
          isAllClear: false,
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

  Widget _buildRtSummaryCard({
    required BuildContext context,
    required bool isDark,
    required String rtTitle,
    required String chairman,
    required String kkCount,
    required String statusText,
    required bool isAllClear,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAllClear ? (isDark ? Colors.white12 : Colors.grey.withAlpha(40)) : const Color(0xFFF59E0B).withAlpha(150),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isAllClear ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isAllClear ? Icons.verified_rounded : Icons.pending_actions_rounded,
                    color: isAllClear ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rtTitle,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$chairman • $kkCount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (isAllClear ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isAllClear ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: isAllClear ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
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
}

