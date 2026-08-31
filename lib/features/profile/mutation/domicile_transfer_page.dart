import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';
import 'package:siladesbeng_mobile/services/mutasi_service.dart';

class DomicileTransferPage extends StatefulWidget {
  const DomicileTransferPage({super.key});

  @override
  State<DomicileTransferPage> createState() => _DomicileTransferPageState();
}

class _DomicileTransferPageState extends State<DomicileTransferPage> {
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

  Map<String, dynamic>? get _lastCompletedMutasi {
    try {
      return _mutationList.firstWhere((m) {
        final s = (m['status'] ?? '').toString().toLowerCase();
        final tab = (m['tabType'] ?? '').toString().toLowerCase();
        return s == 'completed' || s == 'selesai' || tab == 'selesai';
      });
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
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
            lockStatus = 'Status NIK Resmi Aktif di Desa Tujuan';
            stepIndex = 3;
          } else if (status == 'cancelled' ||
              status == 'batal' ||
              status == 'ditolak') {
            tabType = 'Dibatalkan';
            statusTitle = 'Pengajuan Dibatalkan';
            badgeCol = const Color(0xFFEF4444);
            bgCol = const Color(0xFFEF4444).withAlpha(25);
            isLocked = false;
            lockStatus = 'Pengajuan dibatalkan. NIK tetap aktif di desa asal.';
            stepIndex = 0;
          } else if (tipe == 'keluar') {
            tabType = 'Keluar';
            statusTitle = 'Menunggu Pelepasan (Kades Asal)';
            badgeCol = const Color(0xFFF59E0B);
            bgCol = const Color(0xFFF59E0B).withAlpha(25);
            isLocked = true;
            lockStatus = 'Menunggu persetujuan dan pelepasan Kades Asal';
            stepIndex = 1;
          } else {
            tabType = 'Masuk';
            statusTitle = 'Menunggu Aktivasi (Kades Tujuan)';
            badgeCol = const Color(0xFF0EA5E9);
            bgCol = const Color(0xFF0EA5E9).withAlpha(25);
            isLocked = true;
            lockStatus = 'Menunggu aktivasi data NIK oleh Kades Tujuan';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.redAccent,
              size: 26.sp,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Batalkan Pengajuan?',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin membatalkan permohonan pindah domisili ini? Data Anda akan tetap aktif di desa asal.',
          style: TextStyle(fontSize: 13.sp, height: 1.4),
        ),
        actionsPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
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
                borderRadius: BorderRadius.circular(10.r),
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
              expandedHeight: 145.h,
              pinned: true,
              floating: false,
              elevation: 0,
              scrolledUnderElevation: 2,
              backgroundColor: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF2FA2F1),
              leading: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(7.w),
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
                                  const Color(0xFF2FA2F1),
                                  const Color(0xFF0284C7),
                                ],
                        ),
                      ),
                    ),
                    // Ambient light circles
                    Positioned(
                      right: -25,
                      top: -25,
                      child: Container(
                        width: 130.w,
                        height: 130.w,
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
                        width: 80.w,
                        height: 80.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(15),
                        ),
                      ),
                    ),
                    // Title info in header
                    Positioned(
                      left: 20.w,
                      right: 20.w,
                      bottom: 20.h,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.swap_horiz_rounded,
                                color: Colors.white,
                                size: 22.sp,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'Mutasi Domisili (Handshake)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17.5.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'Pindah desa mandiri dengan integrasi NIK resmi antar Kepala Desa',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: _buildBodyContent(isDark),
      ),
    );
  }

  Widget _buildBodyContent(bool isDark) {
    if (_isFetching) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0EA5E9)),
      );
    }

    if (_hasPendingMutasi) {
      return _buildPendingStatusView(isDark);
    }

    return _buildActiveFormView(isDark);
  }

  // ═══════════════════════════════════════════════════════════════════
  // 1. STATUS SEDANG DIPROSES (HANDSHAKE TIMELINE TRACKER)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildPendingStatusView(bool isDark) {
    final pending = _pendingMutasi;
    final String desaTujuan = pending?['desaTujuan'] ?? _selectedDesaTujuan;
    final String desaAsal = pending?['desaAsal'] ?? _desaAsal;
    final String tanggal = pending?['date'] ?? '-';
    final String alasan = pending?['alasan'] ?? '-';
    final int step = pending?['stepIndex'] ?? 1;

    return RefreshIndicator(
      onRefresh: _loadMutations,
      color: const Color(0xFF0EA5E9),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 40.h),
        child: Column(
          children: [
            // Status Hero Card (Glow Amber)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [Colors.white, const Color(0xFFFFFBEB)],
                ),
                borderRadius: BorderRadius.circular(22.r),
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
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 46.w,
                        height: 46.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.sync_rounded,
                          size: 26.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withAlpha(35),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'STATUS: SEDANG DIPROSES',
                      style: TextStyle(
                        color: const Color(0xFFD97706),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Menunggu Persetujuan Handshake',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Pengajuan pindah Anda dari $desaAsal ke $desaTujuan sedang diproses dalam tahapan Handshake.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      height: 1.4,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Stepper Visual Timeline Card
            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.alt_route_rounded,
                        color: const Color(0xFF0EA5E9),
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Tahapan Handshake Protocol',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  _buildTimelineStep(
                    stepNumber: 1,
                    title: 'Formulir Pindah Dikirim',
                    subtitle: 'Permohonan berhasil dicatat di sistem',
                    isDone: true,
                    isActive: false,
                    isDark: isDark,
                  ),
                  _buildTimelineStep(
                    stepNumber: 2,
                    title: 'Pelepasan NIK (Kades Asal)',
                    subtitle: 'Kades asal memvalidasi dan melepaskan data NIK',
                    isDone: step > 1,
                    isActive: step == 1,
                    isDark: isDark,
                  ),
                  _buildTimelineStep(
                    stepNumber: 3,
                    title: 'Aktivasi Data (Kades Tujuan)',
                    subtitle: 'Kades tujuan mengaktifkan NIK di wilayah baru',
                    isDone: step >= 3,
                    isActive: step == 2,
                    isLast: true,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Summary Information Card
            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan Data Pengajuan',
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 12.h),
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

            SizedBox(height: 16.h),

            // Notice Box
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withAlpha(isDark ? 25 : 15),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: const Color(0xFF0EA5E9).withAlpha(40),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: const Color(0xFF0EA5E9),
                    size: 20.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Pemesanan fasilitas di desa asal ditangguhkan sementara hingga proses mutasi ini selesai disetujui.',
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: const Color(0xFF0284C7),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 22.h),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showCancelDialog(pending ?? {}),
                    icon: Icon(Icons.close_rounded, size: 16.sp),
                    label: const Text('Batalkan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loadMutations,
                    icon: Icon(Icons.refresh_rounded, size: 16.sp),
                    label: const Text('Perbarui Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
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

  // ═══════════════════════════════════════════════════════════════════
  // 2. ACTIVE FORMULIR PENGAJUAN PINDAH (CLEAN & MODERN)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildActiveFormView(bool isDark) {
    final completed = _lastCompletedMutasi;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 50.h),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Banner
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2FA2F1), Color(0xFF0284C7)],
                ),
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withAlpha(40),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sync_alt_rounded,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sistem Handshake Digital',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Data NIK Anda akan otomatis dialihkan ke desa tujuan setelah disetujui Kepala Desa.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11.sp,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (completed != null) ...[
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withAlpha(isDark ? 25 : 15),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: const Color(0xFF10B981).withAlpha(50),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: const Color(0xFF10B981),
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Kependudukan Resmi',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Mutasi sebelumnya telah selesai. Anda tercatat aktif di ${completed['desaTujuan']}.',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 20.h),

            // Identitas Pemohon Section
            _buildSectionHeader(
              title: 'Data Identitas Pemohon',
              subtitle: 'Data resmi terverifikasi dari profil Anda',
              isDark: isDark,
            ),
            SizedBox(height: 10.h),

            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                children: [
                  _buildReadOnlyField(
                    label: 'Nama Lengkap Warga',
                    value: _userName,
                    icon: Icons.person_outline_rounded,
                    isDark: isDark,
                  ),
                  SizedBox(height: 10.h),
                  _buildReadOnlyField(
                    label: 'Nomor Induk Kependudukan (NIK)',
                    value: _userNik,
                    icon: Icons.badge_outlined,
                    isMonospace: true,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            _buildSectionHeader(
              title: 'Arah Perpindahan Domisili',
              subtitle: 'Tentukan desa asal pelepasan dan desa tujuan baru',
              isDark: isDark,
            ),
            SizedBox(height: 10.h),

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
                    padding: EdgeInsets.symmetric(
                      vertical: 6.h,
                      horizontal: 16.w,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 2,
                          height: 18.h,
                          color: const Color(0xFF0EA5E9).withAlpha(80),
                        ),
                        SizedBox(width: 12.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EA5E9).withAlpha(isDark ? 30 : 15),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                size: 12.sp,
                                color: const Color(0xFF0EA5E9),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Dialihkan ke',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0EA5E9),
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
                    SizedBox(height: 10.h),
                    TextFormField(
                      controller: _customDesaTujuanController,
                      style: TextStyle(fontSize: 13.sp),
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

            SizedBox(height: 20.h),

            _buildSectionHeader(
              title: 'Alasan Kepindahan',
              subtitle: 'Pilih opsi cepat atau tuliskan alasan Anda',
              isDark: isDark,
            ),
            SizedBox(height: 10.h),

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
                          fontSize: 11.sp,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF0EA5E9)
                              : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF475569)),
                        ),
                        backgroundColor: isSelected
                            ? const Color(0xFF0EA5E9).withAlpha(isDark ? 40 : 20)
                            : (isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9)),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF0EA5E9)
                              : (isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFE2E8F0)),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        onPressed: () {
                          setState(() {
                            _reasonController.text = reason;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 12.h),

                  TextFormField(
                    controller: _reasonController,
                    maxLines: 3,
                    style: TextStyle(fontSize: 13.sp),
                    decoration: _inputDecoration(
                      hintText: 'Contoh: Ikut suami, pindah domisili kerja, dll',
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

            SizedBox(height: 26.h),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmitMutation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: const Color(0xFF0EA5E9).withAlpha(120),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 17.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Ajukan Pindah Sekarang',
                            style: TextStyle(
                              fontSize: 14.sp,
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
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: nodeColor.withAlpha(isActive ? 35 : (isDone ? 30 : 20)),
                shape: BoxShape.circle,
                border: Border.all(color: nodeColor, width: isActive ? 2 : 1.5),
              ),
              child: Center(child: Icon(nodeIcon, size: 15.sp, color: nodeColor)),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32.h,
                color: isDone
                    ? const Color(0xFF10B981)
                    : Colors.grey.withAlpha(60),
              ),
          ],
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? const Color(0xFFD97706)
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                if (!isLast) SizedBox(height: 12.h),
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
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          SizedBox(width: 16.w),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.bold,
                fontFamily: isMonospace ? 'monospace' : null,
                color: isHighlighted
                    ? const Color(0xFF0EA5E9)
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
            fontSize: 13.5.sp,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.sp,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildCardWrapper({required Widget child, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
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
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: const Color(0xFF0EA5E9)),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value.isNotEmpty ? value : '-',
                  style: TextStyle(
                    fontSize: 12.5.sp,
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
            size: 15.sp,
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
              fontSize: 12.5.sp,
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
    Color iconColor = const Color(0xFF0EA5E9),
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 12.sp,
        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
      ),
      labelStyle: TextStyle(
        fontSize: 12.sp,
        color: isDark ? Colors.white60 : const Color(0xFF64748B),
      ),
      prefixIcon: Icon(icon, size: 18.sp, color: iconColor),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.8),
      ),
    );
  }
}
