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
  final MutasiService _mutasiService = MutasiService();

  // Form State
  final _formKey = GlobalKey<FormState>();
  String _tipePermohonan = 'Pindah Keluar (Akun Saya)';
  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _kkController = TextEditingController();
  final _reasonController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedDesaAsal = 'Desa Sila-DesBeng (Desa Kita)';
  String _selectedDesaTujuan = 'Desa Batin Solapan (Kec. Mandau)';
  String _selectedPemohonStatus = 'Mandiri (Diri Sendiri)';

  final List<String> _desaList = [
    'Desa Sila-DesBeng (Desa Kita)',
    'Desa Batin Solapan (Kec. Mandau)',
    'Desa Makmur Jaya (Kec. Bantan)',
    'Desa Pinggir (Kec. Pinggir)',
    'Desa Senggoro (Kec. Bengkalis)',
    'Desa Kelapapati (Kec. Bengkalis)',
    'Desa Sukamaju (Kec. Rupat)',
    'Desa Sukaasih (Kec. Bukit Batu)',
  ];

  final List<String> _statusPemohonList = [
    'Mandiri (Diri Sendiri)',
    'Kepala Keluarga / Pasangan',
    'Tarik Data Orang Tua / Lansia',
    'Wali / Kerabat yang Dirawat',
    'Admin RT/RW (Mewakili Warga)',
  ];

  String _selectedReasonCategory = 'Pindah Rumah / Tempat Tinggal';
  final List<String> _reasonSuggestions = [
    'Pindah Rumah / Tempat Tinggal',
    'Mengikuti Keluarga / Pasangan',
    'Pekerjaan / Dinas Luar Daerah',
    'Pendidikan / Sekolah',
    'Perawatan Keluarga / Lansia',
    'Lainnya (Tulis Manual)',
  ];

  List<Map<String, dynamic>> _mutationList = [];

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
    final address = prefs.getString('profile_address') ?? 'Jalan Haji Usman Zein, Bengkalis';

    if (mounted) {
      setState(() {
        if (_tipePermohonan == 'Pindah Keluar (Akun Saya)') {
          _nameController.text = name;
          _nikController.text = nik;
          _kkController.text = '1403010101900055';
          _addressController.text = address;
        }
      });
    }
  }

  Future<void> _loadMutations() async {
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

        if (status == 'completed') {
          tabType = 'Riwayat';
          statusTitle = 'Mutasi Selesai (Handshake Sukses)';
          badgeCol = const Color(0xFF10B981);
          bgCol = const Color(0xFF10B981).withAlpha(25);
          isLocked = false;
          lockStatus = 'Gembok Terbuka • NIK Resmi Aktif di Desa Tujuan';
          stepIndex = 3;
        } else if (tipe == 'keluar') {
          tabType = 'Keluar';
          statusTitle = 'Menunggu Pelepasan (Desa Asal)';
          badgeCol = const Color(0xFF2563EB);
          bgCol = const Color(0xFF2563EB).withAlpha(25);
          isLocked = true;
          lockStatus = 'Gembok NIK Terkunci • Menunggu persetujuan Admin Desa Asal';
          stepIndex = 1;
        } else {
          tabType = 'Masuk';
          statusTitle = 'Menunggu Persetujuan Desa Lama';
          badgeCol = const Color(0xFF8B5CF6);
          bgCol = const Color(0xFF8B5CF6).withAlpha(25);
          isLocked = true;
          lockStatus = 'Menunggu Admin Desa Asal membuka kunci pelepasan NIK';
          stepIndex = 2;
        }

        return {
          'id': item['id'],
          'name': item['nama'] ?? '',
          'nik': item['nik'] ?? '',
          'tabType': tabType,
          'statusTitle': statusTitle,
          'desaAsal': item['desa_asal'] ?? '',
          'desaTujuan': item['desa_tujuan'] ?? '',
          'pemohon': item['status_pemohon'] ?? '',
          'alasan': item['alasan'] ?? '',
          'lockStatus': lockStatus,
          'isLocked': isLocked,
          'stepIndex': stepIndex,
          'date': item['created_at']?.toString().substring(0, 10) ?? '',
          'color': badgeCol,
          'bgColor': bgCol,
        };
      }).toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _nikController.dispose();
    _kkController.dispose();
    _reasonController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onTipeChanged(String val) {
    setState(() {
      _tipePermohonan = val;
      if (_tipePermohonan == 'Pindah Keluar (Akun Saya)') {
        _loadUserData();
        _selectedDesaAsal = 'Desa Sila-DesBeng (Desa Kita)';
        _selectedDesaTujuan = 'Desa Batin Solapan (Kec. Mandau)';
        _selectedPemohonStatus = 'Mandiri (Diri Sendiri)';
      } else {
        _nameController.text = '';
        _nikController.text = '';
        _kkController.text = '';
        _addressController.text = '';
        _selectedDesaAsal = 'Desa Makmur Jaya (Kec. Bantan)';
        _selectedDesaTujuan = 'Desa Sila-DesBeng (Desa Kita)';
        _selectedPemohonStatus = 'Tarik Data Orang Tua / Lansia';
      }
    });
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

    final bool isKeluar = _tipePermohonan.contains('Keluar');

    final response = await _mutasiService.store(
      nama: _nameController.text.trim(),
      nik: _nikController.text.trim(),
      noKk: _kkController.text.trim(),
      desaAsal: _selectedDesaAsal,
      desaTujuan: _selectedDesaTujuan,
      alamat: _addressController.text.trim(),
      statusPemohon: _selectedPemohonStatus,
      alasan: _reasonController.text.trim(),
      tipe: isKeluar ? 'keluar' : 'masuk',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      _reasonController.clear();
      _tabController.animateTo(1);
      await _loadMutations();

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AnimatedSuccessDialog(
          message: isKeluar
              ? 'Pengajuan Pindah Keluar berhasil dikirim'
              : 'Permohonan Tarik Warga (Handshake) berhasil dikirim',
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

  void _handleActionClick(int index) {
    final item = _mutationList[index];
    final type = item['tabType'];

    if (type == 'Keluar') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Batalkan Pengajuan?'),
          content: Text(
            'Apakah Anda ingin membatalkan permohonan pindah domisili untuk NIK: ${item['nik']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
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
    } else if (type == 'Masuk') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengingat Handshake telah dikirim ke Admin ${item['desaAsal']}',
          ),
          backgroundColor: const Color(0xFF2563EB),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mengunduh Surat Bukti Mutasi Domisili & Berkas...',
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF4F6FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 175,
              pinned: true,
              floating: false,
              elevation: 0,
              scrolledUnderElevation: 2,
              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E3A8A),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
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
                                  const Color(0xFF1E3A8A).withAlpha(120),
                                ]
                              : [
                                  const Color(0xFF1E3A8A),
                                  const Color(0xFF2563EB),
                                  const Color(0xFF3B82F6),
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
                    // Title info in header (positioned with generous breathing room below back button)
                    Positioned(
                      left: 20,
                      right: 20,
                      top: MediaQuery.of(context).padding.top + 52,
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mutasi Domisili (Handshake)',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Integrasi perpindahan NIK & data antar-desa digital',
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
                preferredSize: const Size.fromHeight(54),
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF090D16) : const Color(0xFFF4F6FA),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withAlpha(80),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit_document, size: 16),
                              SizedBox(width: 6),
                              Text('Ajukan Mutasi'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.track_changes_rounded, size: 16),
                              SizedBox(width: 6),
                              Text('Status & Riwayat'),
                            ],
                          ),
                        ),
                      ],
                    ),
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
  // TAB 1: FORMULIR PENGAJUAN MUTASI (HIGH-END REDESIGN)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildCreationFormTab(bool isDark) {
    final bool isAkunSaya = _tipePermohonan == 'Pindah Keluar (Akun Saya)';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 50),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── EXPLANATION BANNER (HANDSHAKE INFO) ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withAlpha(isDark ? 30 : 15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF2563EB).withAlpha(40),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sistem Handshake memastikan NIK dilepas oleh desa asal dan langsung aktif di desa tujuan secara otomatis.',
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

            const SizedBox(height: 18),

            // ── 1. SELECTOR JENIS PERMOHONAN (INTERACTIVE HERO CARDS) ──
            _buildSectionHeader(
              title: '1. Pilih Jenis Permohonan',
              subtitle: 'Tentukan jenis mutasi kependudukan yang diajukan',
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildPermohonanCard(
                    title: 'Pindah Keluar',
                    subtitle: 'Akun Saya Sendiri',
                    badge: 'Otomatis',
                    icon: Icons.logout_rounded,
                    color: const Color(0xFF2563EB),
                    isSelected: isAkunSaya,
                    isDark: isDark,
                    onTap: () => _onTipeChanged('Pindah Keluar (Akun Saya)'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildPermohonanCard(
                    title: 'Tarik Warga',
                    subtitle: 'Lansia / Keluarga',
                    badge: 'Bantu Kerabat',
                    icon: Icons.group_add_rounded,
                    color: const Color(0xFF8B5CF6),
                    isSelected: !isAkunSaya,
                    isDark: isDark,
                    onTap: () => _onTipeChanged('Tarik Warga / Lansia'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ── 2. IDENTITAS WARGA (DIGITAL KTP CARD PREVIEW OR FORM) ──
            _buildSectionHeader(
              title: '2. Identitas Warga yang Dimutasi',
              subtitle: isAkunSaya
                  ? 'Data resmi akun terverifikasi yang akan dipindahkan'
                  : 'Lengkapi data identitas warga yang ingin ditarik',
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            _buildCardWrapper(
              isDark: isDark,
              child: isAkunSaya
                  ? _buildDigitalKtpCardPreview(isDark)
                  : _buildManualFamilyForm(isDark),
            ),

            const SizedBox(height: 22),

            // ── 3. VISUAL MIGRATION ROUTE CONNECTOR (DESA ASAL -> DESA TUJUAN) ──
            _buildSectionHeader(
              title: '3. Arah Perpindahan Domisili',
              subtitle: 'Tentukan desa asal pelepasan dan desa tujuan aktivasi',
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                children: [
                  // Desa Asal
                  _buildDropdownField(
                    label: 'Desa Asal (Pelepasan NIK)',
                    value: _selectedDesaAsal,
                    items: _desaList,
                    icon: Icons.outbox_rounded,
                    iconColor: const Color(0xFFEF4444),
                    isDark: isDark,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDesaAsal = val);
                    },
                  ),

                  // Animated Direction Connector
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withAlpha(isDark ? 40 : 20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF2563EB).withAlpha(50)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFF2563EB)),
                              SizedBox(width: 4),
                              Text(
                                'Mutasi Digital',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),

                  // Desa Tujuan
                  _buildDropdownField(
                    label: 'Desa Tujuan (Aktivasi NIK)',
                    value: _selectedDesaTujuan,
                    items: _desaList,
                    icon: Icons.inbox_rounded,
                    iconColor: const Color(0xFF10B981),
                    isDark: isDark,
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDesaTujuan = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ── 4. ALASAN PEMINDAHAN (WITH QUICK SUGGESTIONS) ──
            _buildSectionHeader(
              title: '4. Alasan Pemindahan Domisili',
              subtitle: 'Pilih atau tuliskan alasan kepindahan warga',
              isDark: isDark,
            ),
            const SizedBox(height: 10),

            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDropdownField(
                    label: 'Kategori Alasan',
                    value: _selectedReasonCategory,
                    items: _reasonSuggestions,
                    icon: Icons.category_rounded,
                    iconColor: const Color(0xFF2563EB),
                    isDark: isDark,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedReasonCategory = val;
                          if (val != 'Lainnya (Tulis Manual)') {
                            _reasonController.text = val;
                          } else {
                            _reasonController.clear();
                          }
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _reasonController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13),
                    decoration: _inputDecoration(
                      hintText: 'Tuliskan rincian atau keterangan alasan pemindahan...',
                      isDark: isDark,
                      icon: Icons.notes_rounded,
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty)
                        ? 'Alasan mutasi wajib diisi'
                        : null,
                  ),

                  // Quick reason chips
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      'Ikut Keluarga',
                      'Pindah Rumah',
                      'Pekerjaan',
                      'Sekolah',
                    ].map((reason) {
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _reasonController.text = reason;
                            _selectedReasonCategory = 'Lainnya (Tulis Manual)';
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            '+ $reason',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ── 5. SUBMIT BUTTON ──
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withAlpha(100),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmitMutation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Kirim Pengajuan Handshake',
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

  // Digital KTP Card Preview for "Pindah Keluar"
  Widget _buildDigitalKtpCardPreview(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(isDark ? 40 : 20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF10B981)),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Data Terverifikasi dari Akun Anda',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
            const Icon(Icons.lock_rounded, size: 16, color: Colors.grey),
          ],
        ),
        const SizedBox(height: 14),

        _buildReadOnlyField(
          label: 'Nama Lengkap',
          value: _nameController.text,
          icon: Icons.person_rounded,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildReadOnlyField(
          label: 'Nomor Induk Kependudukan (NIK)',
          value: _nikController.text,
          icon: Icons.badge_rounded,
          isDark: isDark,
          isMonospace: true,
        ),
        const SizedBox(height: 10),
        _buildReadOnlyField(
          label: 'Alamat Domisili Saat Ini',
          value: _addressController.text,
          icon: Icons.home_rounded,
          isDark: isDark,
        ),
      ],
    );
  }

  // Manual Form for "Tarik Warga"
  Widget _buildManualFamilyForm(bool isDark) {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          decoration: _inputDecoration(
            hintText: 'Contoh: Ahmad Fadilah',
            isDark: isDark,
            icon: Icons.person_outline_rounded,
            label: 'Nama Lengkap Warga yang Ditarik',
          ),
          validator: (val) => (val == null || val.trim().isEmpty) ? 'Nama wajib diisi' : null,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _nikController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          decoration: _inputDecoration(
            hintText: '1403xxxxxxxxxxxx (16 Digit)',
            isDark: isDark,
            icon: Icons.badge_outlined,
            label: 'Nomor Induk Kependudukan (NIK)',
          ),
          validator: (val) => (val == null || val.trim().length < 16)
              ? 'NIK harus 16 digit angka'
              : null,
        ),
        const SizedBox(height: 12),

        _buildDropdownField(
          label: 'Hubungan / Status dengan Pemohon',
          value: _selectedPemohonStatus,
          items: _statusPemohonList,
          icon: Icons.family_restroom_rounded,
          iconColor: const Color(0xFF8B5CF6),
          isDark: isDark,
          onChanged: (val) {
            if (val != null) setState(() => _selectedPemohonStatus = val);
          },
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _addressController,
          style: const TextStyle(fontSize: 13),
          decoration: _inputDecoration(
            hintText: 'RT/RW, Dusun, atau Jalan',
            isDark: isDark,
            icon: Icons.home_outlined,
            label: 'Alamat Domisili Asal',
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 2: STATUS & RIWAYAT (STEPPER TIMELINE STYLE)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildStatusListTab(bool isDark) {
    List<Map<String, dynamic>> filteredList = _mutationList;
    if (_selectedFilter != 'Semua') {
      filteredList = _mutationList
          .where((item) => item['tabType'] == _selectedFilter)
          .toList();
    }

    final int cKeluar = _mutationList.where((e) => e['tabType'] == 'Keluar').length;
    final int cMasuk = _mutationList.where((e) => e['tabType'] == 'Masuk').length;
    final int cRiwayat = _mutationList.where((e) => e['tabType'] == 'Riwayat').length;

    return RefreshIndicator(
      onRefresh: _loadMutations,
      color: const Color(0xFF2563EB),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
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
                    _buildFilterChip('Semua (${_mutationList.length})', 'Semua', isDark),
                    _buildFilterChip('Pelepasan ($cKeluar)', 'Keluar', isDark),
                    _buildFilterChip('Persetujuan ($cMasuk)', 'Masuk', isDark),
                    _buildFilterChip('Selesai ($cRiwayat)', 'Riwayat', isDark),
                  ],
                ),
              ),
            ),
          ),

          // List Items
          if (filteredList.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withAlpha(isDark ? 25 : 15),
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
                        'Belum Ada Pengajuan Mutasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Riwayat pemindahan domisili dan tarik warga Anda akan tercatat secara resmi di sini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: () => _tabController.animateTo(0),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Buat Pengajuan Mutasi'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = filteredList[index];
                    final int realIdx = _mutationList.indexOf(item);
                    final Color badgeCol = item['color'];
                    final bool isLocked = item['isLocked'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                            decoration: BoxDecoration(
                              color: item['bgColor'],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item['tabType'] == 'Keluar'
                                      ? Icons.logout_rounded
                                      : item['tabType'] == 'Masuk'
                                          ? Icons.group_add_rounded
                                          : Icons.check_circle_rounded,
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
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
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
                                // Nama & NIK
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['name'],
                                            style: TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w800,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'NIK: ${item['nik']}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'monospace',
                                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: (isLocked ? const Color(0xFF2563EB) : const Color(0xFF10B981))
                                            .withAlpha(isDark ? 35 : 15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                                        color: isLocked ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Route Info
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Desa Asal',
                                              style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item['desaAsal'],
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text(
                                              'Desa Tujuan',
                                              style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item['desaTujuan'],
                                              textAlign: TextAlign.end,
                                              style: const TextStyle(
                                                fontSize: 11.5,
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

                                // Status Lock Banner
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: (isLocked ? const Color(0xFF2563EB) : const Color(0xFF10B981))
                                        .withAlpha(isDark ? 25 : 12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isLocked ? Icons.vpn_key_rounded : Icons.verified_user_rounded,
                                        size: 14,
                                        color: isLocked ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item['lockStatus'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isLocked
                                                ? (isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E40AF))
                                                : const Color(0xFF10B981),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Action Button
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () => _handleActionClick(realIdx),
                                    icon: Icon(
                                      item['tabType'] == 'Keluar'
                                          ? Icons.close_rounded
                                          : item['tabType'] == 'Masuk'
                                              ? Icons.notifications_active_rounded
                                              : Icons.download_rounded,
                                      size: 15,
                                    ),
                                    label: Text(
                                      item['tabType'] == 'Keluar'
                                          ? 'Batalkan Pengajuan'
                                          : item['tabType'] == 'Masuk'
                                              ? 'Kirim Pengingat'
                                              : 'Unduh Bukti Mutasi',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: item['tabType'] == 'Keluar'
                                          ? Colors.redAccent
                                          : item['tabType'] == 'Masuk'
                                              ? const Color(0xFF2563EB)
                                              : const Color(0xFF10B981),
                                      backgroundColor: (item['tabType'] == 'Keluar'
                                              ? Colors.redAccent
                                              : item['tabType'] == 'Masuk'
                                                  ? const Color(0xFF2563EB)
                                                  : const Color(0xFF10B981))
                                          .withAlpha(20),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: filteredList.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // REUSABLE HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════
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

  Widget _buildPermohonanCard({
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withAlpha(isDark ? 45 : 20)
              : (isDark ? const Color(0xFF131C2E) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withAlpha(60),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                    size: 20,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withAlpha(isDark ? 40 : 20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: isSelected
                          ? (isDark ? Colors.white : color)
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
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
                    fontSize: 11,
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
          Icon(Icons.lock_rounded, size: 15, color: isDark ? Colors.white30 : Colors.grey[400]),
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
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.8,
        ),
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
