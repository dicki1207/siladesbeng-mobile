import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';
import 'package:siladesbeng_mobile/services/mutasi_service.dart';

class DomicileTransferPage extends StatefulWidget {
  const DomicileTransferPage({super.key});

  @override
  State<DomicileTransferPage> createState() => _DomicileTransferPageState();
}

class _DomicileTransferPageState extends State<DomicileTransferPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'Semua';
  bool _isLoading = false;
  bool _isFetching = true;

  final MutasiService _mutasiService = MutasiService();

  // Form State
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _customDesaTujuanController = TextEditingController();

  String _userName = 'Diki Wahyu';
  String _userNik = '1403010101900001';
  String _userAddress = 'Jalan Haji Usman Zein, Bengkalis';
  final String _desaAsal = 'Desa Sila-DesBeng (Desa Saat Ini)';
  String _selectedDesaTujuan = 'Desa Batin Solapan (Kec. Mandau)';

  final List<String> _desaList = [
    'Desa Batin Solapan (Kec. Mandau)',
    'Desa Makmur Jaya (Kec. Bantan)',
    'Desa Pinggir (Kec. Pinggir)',
    'Desa Senggoro (Kec. Bengkalis)',
    'Desa Kelapapati (Kec. Bengkalis)',
    'Desa Sukamaju (Kec. Rupat)',
    'Desa Sukaasih (Kec. Bukit Batu)',
    'Luar Daerah / Luar Kecamatan (Ketik Manual)',
  ];

  final List<String> _quickReasons = [
    'Pindah Rumah',
    'Ikut Keluarga / Pasangan',
    'Pekerjaan / Dinas Luar',
    'Pendidikan / Studi',
    'Perawatan Orang Tua',
  ];

  List<Map<String, dynamic>> _mutationList = [];

  bool get _hasPendingMutasi {
    return _mutationList.any((m) {
      final s = (m['status'] ?? '').toString().toLowerCase();
      final tab = (m['tabType'] ?? '').toString().toLowerCase();
      return s == 'pending' ||
          s == 'menunggu pelepasan' ||
          s == 'menunggu penerimaan' ||
          tab == 'keluar' ||
          tab == 'masuk';
    });
  }

  Map<String, dynamic>? get _pendingMutasi {
    try {
      return _mutationList.firstWhere((m) {
        final s = (m['status'] ?? '').toString().toLowerCase();
        final tab = (m['tabType'] ?? '').toString().toLowerCase();
        return s == 'pending' ||
            s == 'menunggu pelepasan' ||
            s == 'menunggu penerimaan' ||
            tab == 'keluar' ||
            tab == 'masuk';
      });
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadUserData();
    _loadMutations();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('profile_name') ?? 'Diki Wahyu';
    final nik = prefs.getString('profile_nik') ?? '1403010101900001';
    final address =
        prefs.getString('profile_address') ??
        'Jalan Haji Usman Zein, Bengkalis';

    if (mounted) {
      setState(() {
        _userName = name;
        _userNik = nik;
        _userAddress = address;
      });
    }
  }

  Future<void> _loadMutations() async {
    setState(() => _isFetching = true);
    try {
      final data = await _mutasiService.getMyMutations();
      if (!mounted) return;
      setState(() {
        _mutationList = data.map<Map<String, dynamic>>((item) {
          final String tipe = item['tipe'] ?? 'keluar';
          final String status = item['status'] ?? 'pending';
          String tabType;
          String statusTitle;
          Color badgeCol;
          Color bgCol;
          bool isLocked;
          String lockStatus;
          int stepIndex;

          if (status == 'completed' || status == 'selesai') {
            tabType = 'Selesai';
            statusTitle = 'Mutasi Selesai (Handshake Sukses)';
            badgeCol = const Color(0xFF10B981);
            bgCol = const Color(0xFF10B981).withAlpha(25);
            isLocked = false;
            lockStatus = 'Gembok Terbuka • NIK Resmi Aktif di Desa Tujuan';
            stepIndex = 3;
          } else if (status == 'cancelled' ||
              status == 'batal' ||
              status == 'ditolak') {
            tabType = 'Dibatalkan';
            statusTitle = 'Pengajuan Dibatalkan';
            badgeCol = const Color(0xFFEF4444);
            bgCol = const Color(0xFFEF4444).withAlpha(25);
            isLocked = false;
            lockStatus =
                'Pengajuan ditolak/dibatalkan • NIK tetap di desa asal';
            stepIndex = 0;
          } else if (tipe == 'keluar') {
            tabType = 'Keluar';
            statusTitle = 'Menunggu Pelepasan (Kades Asal)';
            badgeCol = const Color(0xFFF59E0B);
            bgCol = const Color(0xFFF59E0B).withAlpha(25);
            isLocked = true;
            lockStatus =
                'Gembok NIK Terkunci • Menunggu persetujuan Admin Desa Asal';
            stepIndex = 1;
          } else {
            tabType = 'Masuk';
            statusTitle = 'Menunggu Aktivasi (Kades Tujuan)';
            badgeCol = const Color(0xFF3B82F6);
            bgCol = const Color(0xFF3B82F6).withAlpha(25);
            isLocked = true;
            lockStatus =
                'Menunggu Admin Desa Tujuan mengaktifkan data NIK Anda';
            stepIndex = 2;
          }

          return {
            'id': item['id'],
            'name': item['nama'] ?? _userName,
            'nik': item['nik'] ?? _userNik,
            'tabType': tabType,
            'status': status,
            'statusTitle': statusTitle,
            'desaAsal': item['desa_asal'] ?? _desaAsal,
            'desaTujuan': item['desa_tujuan'] ?? _selectedDesaTujuan,
            'pemohon': item['status_pemohon'] ?? 'Mandiri (Diri Sendiri)',
            'alasan': item['alasan'] ?? '-',
            'lockStatus': lockStatus,
            'isLocked': isLocked,
            'stepIndex': stepIndex,
            'date':
                item['created_at']?.toString().substring(0, 10) ??
                DateTime.now().toString().substring(0, 10),
            'color': badgeCol,
            'bgColor': bgCol,
          };
        }).toList();
        _isFetching = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isFetching = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    _customDesaTujuanController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitMutation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alasan pemindahan domisili wajib diisi'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final String finalDesaTujuan = _selectedDesaTujuan.contains('Luar Daerah')
        ? _customDesaTujuanController.text.trim()
        : _selectedDesaTujuan;

    if (finalDesaTujuan.isEmpty) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Detail wilayah luar daerah wajib diisi'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final response = await _mutasiService.store(
      nama: _userName,
      nik: _userNik,
      noKk: '1403010101900055',
      desaAsal: _desaAsal,
      desaTujuan: finalDesaTujuan,
      alamat: _userAddress,
      statusPemohon: 'Mandiri (Diri Sendiri)',
      alasan: _reasonController.text.trim(),
      tipe: 'keluar',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      _reasonController.clear();
      _customDesaTujuanController.clear();
      await _loadMutations();

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AnimatedSuccessDialog(
          message: 'Pengajuan Pindah Desa berhasil dikirim ke Kades',
          isLogout: false,
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Gagal mengirim pengajuan'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCancelDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 28,
            ),
            SizedBox(width: 10),
            Text(
              'Batalkan Pengajuan?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan permohonan pindah domisili ini? Data Anda akan tetap aktif di desa asal.',
          style: TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kembali', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final itemId = item['id'];
              if (itemId != null) {
                final res = await _mutasiService.cancel(itemId);
                if (res['status'] == 'success') {
                  await _loadMutations();
                }
              }
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Permohonan pindah berhasil dibatalkan'),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1120)
          : const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              floating: false,
              elevation: 0,
              scrolledUnderElevation: 2,
              backgroundColor: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF2563EB),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(isDark ? 25 : 35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF0F172A),
                                  const Color(0xFF1E293B),
                                ]
                              : [
                                  const Color(0xFF2563EB),
                                  const Color(0xFF1D4ED8),
                                ],
                        ),
                      ),
                    ),
                    // Ambient light circle
                    Positioned(
                      right: -25,
                      top: -25,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(20),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(15),
                        ),
                      ),
                    ),
                    // Title info in header
                    Positioned(
                      left: 20,
                      right: 20,
                      top: MediaQuery.of(context).padding.top + 50,
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.swap_horiz_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Mutasi Domisili (Handshake)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Pindah desa mandiri dengan integrasi NIK resmi antar Kepala Desa',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF090D16) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white10
                            : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: UnderlineTabIndicator(
                      borderSide: const BorderSide(
                        width: 3.5,
                        color: Color(0xFF2563EB),
                      ),
                      borderRadius: BorderRadius.circular(3),
                      insets: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: const Color(0xFF2563EB),
                    unselectedLabelColor: isDark
                        ? Colors.white60
                        : const Color(0xFF64748B),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        height: 48,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasPendingMutasi
                                  ? Icons.hourglass_top_rounded
                                  : Icons.edit_document,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _hasPendingMutasi
                                  ? 'Status Pengajuan'
                                  : 'Ajukan Pindah',
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        height: 48,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.history_rounded, size: 18),
                            const SizedBox(width: 8),
                            const Text('Riwayat'),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2563EB,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_mutationList.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
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
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCreationFormTab(isDark),
            _buildStatusListTab(isDark),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 1: FORM PENGAJUAN PINDAH ATAU STATUS PENDING (BEAUTIFIED)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildCreationFormTab(bool isDark) {
    if (_isFetching) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      );
    }

    if (_hasPendingMutasi) {
      return _buildPendingStatusView(isDark);
    }

    return _buildActiveFormView(isDark);
  }

  // ── VIEW 1: STATUS SEDANG DIPROSES (HANDSHAKE TIMELINE) ──
  Widget _buildPendingStatusView(bool isDark) {
    final pending = _pendingMutasi;
    final String desaTujuan = pending?['desaTujuan'] ?? _selectedDesaTujuan;
    final String desaAsal = pending?['desaAsal'] ?? _desaAsal;
    final String tanggal = pending?['date'] ?? '-';
    final String alasan = pending?['alasan'] ?? '-';
    final int step = pending?['stepIndex'] ?? 1;

    return RefreshIndicator(
      onRefresh: _loadMutations,
      color: const Color(0xFF2563EB),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          children: [
            // Status Hero Card (Glow Amber)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [Colors.white, const Color(0xFFFFFBEB)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withAlpha(isDark ? 80 : 120),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withAlpha(isDark ? 30 : 25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Animated pulsing icon
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sync_rounded,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withAlpha(35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'STATUS: SEDANG DIPROSES',
                      style: TextStyle(
                        color: Color(0xFFD97706),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Menunggu Persetujuan Handshake',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pengajuan pindah Anda dari $desaAsal ke $desaTujuan sedang menunggu persetujuan dari Kepala Desa saat ini.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Stepper Visual Timeline Card
            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.alt_route_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tahapan Handshake Protocol',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTimelineStep(
                    stepNumber: 1,
                    title: 'Formulir Pindah Dikirim',
                    subtitle:
                        'Warga mandiri mengajukan kepindahan via aplikasi',
                    isDone: true,
                    isActive: false,
                    isDark: isDark,
                  ),
                  _buildTimelineStep(
                    stepNumber: 2,
                    title: 'Pelepasan NIK (Kades Asal)',
                    subtitle:
                        'Kades asal memvalidasi & membuka kunci gembok NIK',
                    isDone: step > 1,
                    isActive: step == 1,
                    isDark: isDark,
                  ),
                  _buildTimelineStep(
                    stepNumber: 3,
                    title: 'Aktivasi Data (Kades Tujuan)',
                    subtitle: 'Data resmi dialihkan dan aktif di desa tujuan',
                    isDone: step >= 3,
                    isActive: step == 2,
                    isLast: true,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Summary Information Card
            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan Data Pengajuan',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Nama Pemohon', _userName, isDark),
                  _buildSummaryRow(
                    'NIK Warga',
                    _userNik,
                    isDark,
                    isMonospace: true,
                  ),
                  _buildSummaryRow('Desa Asal', desaAsal, isDark),
                  _buildSummaryRow(
                    'Desa Tujuan',
                    desaTujuan,
                    isDark,
                    isHighlighted: true,
                  ),
                  _buildSummaryRow('Alasan Pindah', alasan, isDark),
                  _buildSummaryRow('Tanggal Diajukan', tanggal, isDark),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Notice Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(isDark ? 25 : 15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.withAlpha(40)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pemesanan fasilitas di desa asal ditangguhkan sementara hingga proses mutasi ini selesai.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelDialog(pending ?? {}),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Batalkan Pengajuan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadMutations,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Cek Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── VIEW 2: ACTIVE FORMULIR PENGAJUAN PINDAH (CLEAN & MODERN) ──
  Widget _buildActiveFormView(bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 50),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withAlpha(50),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.handshake_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sistem Handshake Digital',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Data NIK Anda akan otomatis dialihkan ke desa tujuan setelah disetujui Kepala Desa.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildSectionHeader(
              title: 'Arah Perpindahan Domisili',
              subtitle: 'Tentukan desa asal pelepasan dan desa tujuan baru',
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            // Route Card
            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Desa Asal
                  _buildReadOnlyField(
                    label: 'Desa Asal (Pelepasan NIK)',
                    value: _desaAsal,
                    icon: Icons.outbox_rounded,
                    isDark: isDark,
                  ),

                  // Directional Connector
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 2,
                          height: 20,
                          color: const Color(0xFF2563EB).withAlpha(80),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2563EB,
                            ).withAlpha(isDark ? 30 : 15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                size: 12,
                                color: Color(0xFF2563EB),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Dialihkan ke',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Desa Tujuan Dropdown
                  _buildDropdownField(
                    label: 'Pilih Desa Tujuan (Aktivasi NIK)',
                    value: _selectedDesaTujuan,
                    items: _desaList,
                    icon: Icons.inbox_rounded,
                    iconColor: const Color(0xFF10B981),
                    isDark: isDark,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDesaTujuan = val);
                      }
                    },
                  ),

                  if (_selectedDesaTujuan.contains('Luar Daerah')) ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _customDesaTujuanController,
                      style: const TextStyle(fontSize: 13),
                      decoration: _inputDecoration(
                        hintText: 'Tuliskan Nama Desa & Kecamatan Tujuan...',
                        isDark: isDark,
                        icon: Icons.edit_location_alt_rounded,
                        iconColor: const Color(0xFF10B981),
                      ),
                      validator: (val) {
                        if (_selectedDesaTujuan.contains('Luar Daerah') &&
                            (val == null || val.isEmpty)) {
                          return 'Desa tujuan wajib diisi';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildSectionHeader(
              title: 'Alasan Kepindahan',
              subtitle: 'Pilih opsi cepat atau tuliskan alasan Anda',
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick suggestion chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _quickReasons.map((reason) {
                      final bool isSelected = _reasonController.text.contains(
                        reason,
                      );
                      return ActionChip(
                        label: Text(reason),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF475569)),
                        ),
                        backgroundColor: isSelected
                            ? const Color(
                                0xFF2563EB,
                              ).withAlpha(isDark ? 40 : 20)
                            : (isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9)),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : (isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFE2E8F0)),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onPressed: () {
                          setState(() {
                            _reasonController.text = reason;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _reasonController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: _inputDecoration(
                      hintText:
                          'Contoh: Ikut suami, pindah domisili kerja, dll',
                      label: 'Tuliskan Alasan Lengkap',
                      isDark: isDark,
                      icon: Icons.chat_bubble_outline_rounded,
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Alasan pindah wajib diisi'
                        : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmitMutation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: const Color(0xFF2563EB).withAlpha(120),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Ajukan Pindah Sekarang',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 2: RIWAYAT MUTASI (BEAUTIFIED LIST)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildStatusListTab(bool isDark) {
    List<Map<String, dynamic>> filteredList = _mutationList;
    if (_selectedFilter != 'Semua') {
      filteredList = _mutationList
          .where((item) => item['tabType'] == _selectedFilter)
          .toList();
    }

    final int cKeluar = _mutationList
        .where((e) => e['tabType'] == 'Keluar')
        .length;
    final int cMasuk = _mutationList
        .where((e) => e['tabType'] == 'Masuk')
        .length;
    final int cSelesai = _mutationList
        .where((e) => e['tabType'] == 'Selesai')
        .length;

    return RefreshIndicator(
      onRefresh: _loadMutations,
      color: const Color(0xFF2563EB),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // Filter Chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFilterChip(
                      'Semua (${_mutationList.length})',
                      'Semua',
                      isDark,
                    ),
                    _buildFilterChip('Pelepasan ($cKeluar)', 'Keluar', isDark),
                    _buildFilterChip('Aktivasi ($cMasuk)', 'Masuk', isDark),
                    _buildFilterChip('Selesai ($cSelesai)', 'Selesai', isDark),
                  ],
                ),
              ),
            ),
          ),

          // List Items
          if (filteredList.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF2563EB,
                          ).withAlpha(isDark ? 25 : 15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          size: 48,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum Ada Riwayat Mutasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Riwayat pemindahan domisili Anda antar desa akan tercatat secara resmi di sini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: () => _tabController.animateTo(0),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Ajukan Pindah Desa'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = filteredList[index];
                  final Color badgeCol = item['color'];
                  final bool isLocked = item['isLocked'];
                  final bool isPending =
                      item['tabType'] == 'Keluar' || item['tabType'] == 'Masuk';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131C2E) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 30 : 6),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Ribbon Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: item['bgColor'],
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(17),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item['tabType'] == 'Selesai'
                                    ? Icons.check_circle_rounded
                                    : item['tabType'] == 'Dibatalkan'
                                    ? Icons.cancel_rounded
                                    : Icons.hourglass_top_rounded,
                                size: 16,
                                color: badgeCol,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item['statusTitle'],
                                  style: TextStyle(
                                    color: badgeCol,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                item['date'],
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF64748B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Route Info
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white10
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Desa Asal',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item['desaAsal'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Color(0xFF2563EB),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Desa Tujuan',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item['desaTujuan'],
                                            textAlign: TextAlign.end,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2563EB),
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

                              const SizedBox(height: 10),

                              // Alasan
                              Text(
                                'Alasan: ${item['alasan']}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Status Lock Banner
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (isLocked
                                              ? const Color(0xFF2563EB)
                                              : const Color(0xFF10B981))
                                          .withAlpha(isDark ? 25 : 12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isLocked
                                          ? Icons.vpn_key_rounded
                                          : Icons.verified_user_rounded,
                                      size: 14,
                                      color: isLocked
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item['lockStatus'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isLocked
                                              ? (isDark
                                                    ? const Color(0xFF60A5FA)
                                                    : const Color(0xFF1E40AF))
                                              : const Color(0xFF10B981),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (isPending) ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _showCancelDialog(item),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                    ),
                                    label: const Text(
                                      'Batalkan Permohonan',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.redAccent,
                                      backgroundColor: Colors.redAccent
                                          .withAlpha(20),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }, childCount: filteredList.length),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // REUSABLE HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildTimelineStep({
    required int stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    bool isLast = false,
    required bool isDark,
  }) {
    Color nodeColor;
    IconData nodeIcon;

    if (isDone) {
      nodeColor = const Color(0xFF10B981);
      nodeIcon = Icons.check_rounded;
    } else if (isActive) {
      nodeColor = const Color(0xFFF59E0B);
      nodeIcon = Icons.sync_rounded;
    } else {
      nodeColor = Colors.grey[400]!;
      nodeIcon = Icons.radio_button_unchecked_rounded;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: nodeColor.withAlpha(isActive ? 35 : (isDone ? 30 : 20)),
                shape: BoxShape.circle,
                border: Border.all(color: nodeColor, width: isActive ? 2 : 1.5),
              ),
              child: Center(child: Icon(nodeIcon, size: 16, color: nodeColor)),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 34,
                color: isDone
                    ? const Color(0xFF10B981)
                    : Colors.grey.withAlpha(60),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? const Color(0xFFD97706)
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                if (!isLast) const SizedBox(height: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    bool isDark, {
    bool isMonospace = false,
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.bold,
                fontFamily: isMonospace ? 'monospace' : null,
                color: isHighlighted
                    ? const Color(0xFF2563EB)
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildCardWrapper({required Widget child, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
    bool isMonospace = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '-',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: isMonospace ? 'monospace' : null,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_rounded,
            size: 15,
            color: isDark ? Colors.white30 : Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : items.first,
      items: items.map((e) {
        return DropdownMenuItem<String>(
          value: e,
          child: Text(
            e,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      decoration: _inputDecoration(
        hintText: label,
        isDark: isDark,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required bool isDark,
    required IconData icon,
    String? label,
    Color iconColor = const Color(0xFF2563EB),
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 12,
        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        color: isDark ? Colors.white60 : const Color(0xFF64748B),
      ),
      prefixIcon: Icon(icon, size: 18, color: iconColor),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterValue, bool isDark) {
    final bool active = _selectedFilter == filterValue;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: active,
        showCheckmark: false,
        avatar: active
            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
            : null,
        labelStyle: TextStyle(
          color: active
              ? Colors.white
              : (isDark ? Colors.white70 : const Color(0xFF475569)),
          fontSize: 12,
          fontWeight: active ? FontWeight.bold : FontWeight.w600,
        ),
        backgroundColor: isDark ? const Color(0xFF131C2E) : Colors.white,
        selectedColor: const Color(0xFF2563EB),
        side: BorderSide(
          color: active
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: active ? 2 : 0,
        shadowColor: const Color(0xFF2563EB).withAlpha(80),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        onSelected: (_) {
          setState(() => _selectedFilter = filterValue);
        },
      ),
    );
  }
}
