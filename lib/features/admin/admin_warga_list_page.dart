import 'package:flutter/material.dart';

class AdminWargaListPage extends StatefulWidget {
  final String role;
  final String? filterRt;
  const AdminWargaListPage({super.key, this.role = 'rt', this.filterRt});

  @override
  State<AdminWargaListPage> createState() => _AdminWargaListPageState();
}

class _AdminWargaListPageState extends State<AdminWargaListPage> {
  String _selectedFilter = 'Semua';
  String _selectedRtFilter = 'Seluruh RW 01';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    'Semua',
    'Menunggu Validasi',
    'Tervalidasi AI',
    'Warga Menetap',
    'Pendatang / Kost',
  ];

  final List<String> _rtRegions = [
    'Seluruh RW 01',
    'RT 01 / RW 01',
    'RT 02 / RW 01',
    'RT 03 / RW 01',
    'RT 04 / RW 01',
  ];

  // Daftar data warga (Buku Induk Digital Multi-RT) dengan privasi perbankan (Tanpa NIK terbuka & Tanpa Emoji)
  late List<Map<String, dynamic>> _allWarga;
  List<Map<String, dynamic>> _filteredWarga = [];

  @override
  void initState() {
    super.initState();
    if (widget.filterRt != null && _rtRegions.contains(widget.filterRt)) {
      _selectedRtFilter = widget.filterRt!;
    } else if (widget.role == 'rt') {
      _selectedRtFilter = 'RT 02 / RW 01'; // Default fokus RT untuk Admin RT 02
    }
    _initializeData();
  }

  void _initializeData() {
    _allWarga = [
      // RT 01
      {
        'id': 'SLD-2026-1011',
        'masked_nik': '5108••••••••1241',
        'name': 'Bpk. Wayan Darma (Ketua RT 01)',
        'family_role': 'Kepala Keluarga & RT',
        'address': 'Banjar Kelod Blok A No. 01',
        'rt_rw': 'RT 01 / RW 01',
        'residency_type': 'Warga Menetap',
        'verification_status': 'Tervalidasi AI',
        'phone': '0812-4455-8811',
        'members_count': 5,
        'occupation': 'Pimpinan Lingkungan & Usaha',
        'registered_date': '05 Jan 2026',
      },
      {
        'id': 'SLD-2026-1024',
        'masked_nik': '5108••••••••9023',
        'name': 'Ni Kadek Anjani',
        'family_role': 'Kepala Keluarga',
        'address': 'Banjar Kelod Blok A No. 15',
        'rt_rw': 'RT 01 / RW 01',
        'residency_type': 'Warga Menetap',
        'verification_status': 'Tervalidasi AI',
        'phone': '0819-2233-9900',
        'members_count': 3,
        'occupation': 'Pengrajin Tenun Ikat',
        'registered_date': '14 Feb 2026',
      },

      // RT 02
      {
        'id': 'SLD-2026-8891',
        'masked_nik': '5108••••••••8912',
        'name': 'I Nyoman Suartha (Ketua RT 02)',
        'family_role': 'Kepala Keluarga & RT',
        'address': 'Jl. Bali Banjar Blok C No. 14',
        'rt_rw': 'RT 02 / RW 01',
        'residency_type': 'Warga Menetap',
        'verification_status': 'Tervalidasi AI',
        'phone': '0812-3456-7890',
        'members_count': 4,
        'occupation': 'Pesta Kriya & Pertanian',
        'registered_date': '12 Jan 2026',
      },
      {
        'id': 'SLD-2026-9042',
        'masked_nik': '5108••••••••1045',
        'name': 'Ni Wayan Sukerti',
        'family_role': 'Kepala Keluarga',
        'address': 'Jl. Utama Bengkala No. 08',
        'rt_rw': 'RT 02 / RW 01',
        'residency_type': 'Warga Menetap',
        'verification_status': 'Menunggu Validasi',
        'phone': '0819-8765-4321',
        'members_count': 3,
        'occupation': 'Tenun Kain & Kerajinan',
        'registered_date': '27 Jul 2026',
      },
      {
        'id': 'SLD-2026-7731',
        'masked_nik': '5108••••••••5621',
        'name': 'Drs. Hendrawan Kusuma',
        'family_role': 'Kepala Keluarga',
        'address': 'Gang Melati IV No. 2A',
        'rt_rw': 'RT 02 / RW 01',
        'residency_type': 'Pendatang / Kost',
        'verification_status': 'Tervalidasi AI',
        'phone': '0852-1122-3344',
        'members_count': 2,
        'occupation': 'Guru Sekolah Dasar',
        'registered_date': '05 Mar 2026',
      },
      {
        'id': 'SLD-2026-6652',
        'masked_nik': '5108••••••••3318',
        'name': 'Ketut Arka Wijaya',
        'family_role': 'Kepala Keluarga',
        'address': 'Jl. Raya Bengkala-Kubutambahan No. 22',
        'rt_rw': 'RT 02 / RW 01',
        'residency_type': 'Warga Menetap',
        'verification_status': 'Tervalidasi AI',
        'phone': '0813-9988-7766',
        'members_count': 5,
        'occupation': 'Wiraswasta & Usaha Tani',
        'registered_date': '18 Feb 2026',
      },
      {
        'id': 'SLD-2026-9110',
        'masked_nik': '5108••••••••0098',
        'name': 'Putu Gede Mahendra',
        'family_role': 'Kepala Keluarga',
        'address': 'Gang Mawar Putih No. 05',
        'rt_rw': 'RT 02 / RW 01',
        'residency_type': 'Pendatang / Kost',
        'verification_status': 'Menunggu Validasi',
        'phone': '0878-5566-4433',
        'members_count': 1,
        'occupation': 'Karyawan Lepas & Profesional',
        'registered_date': '28 Jul 2026',
      },

      // RT 03 & RT 04
      {
        'id': 'SLD-2026-3011',
        'masked_nik': '5108••••••••6651',
        'name': 'Bpk. Ketut Santika (Ketua RT 03)',
        'family_role': 'Kepala Keluarga & RT',
        'address': 'Banjar Kaja No. 11',
        'rt_rw': 'RT 03 / RW 01',
        'residency_type': 'Warga Menetap',
        'verification_status': 'Tervalidasi AI',
        'phone': '0813-5577-9922',
        'members_count': 4,
        'occupation': 'Pamong & Budayawan',
        'registered_date': '10 Mar 2026',
      },
      {
        'id': 'SLD-2026-4019',
        'masked_nik': '5108••••••••8819',
        'name': 'Bpk. Gede Arini (Ketua RT 04)',
        'family_role': 'Kepala Keluarga & RT',
        'address': 'Banjar Kangin No. 45',
        'rt_rw': 'RT 04 / RW 01',
        'residency_type': 'Warga Menetap',
        'verification_status': 'Tervalidasi AI',
        'phone': '0878-1122-8877',
        'members_count': 5,
        'occupation': 'Ketua Kelopok Tani',
        'registered_date': '20 Mar 2026',
      },
      {
        'id': 'SLD-2026-4055',
        'masked_nik': '5108••••••••4400',
        'name': 'I Wayan Suteja',
        'family_role': 'Kepala Keluarga',
        'address': 'Banjar Kangin No. 12',
        'rt_rw': 'RT 04 / RW 01',
        'residency_type': 'Pendatang / Kost',
        'verification_status': 'Menunggu Validasi',
        'phone': '0812-7788-9944',
        'members_count': 2,
        'occupation': 'Teknisi Telekomunikasi',
        'registered_date': '26 Jul 2026',
      },
    ];

    _applyFiltersAndSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFiltersAndSearch() {
    setState(() {
      _filteredWarga = _allWarga.where((warga) {
        // 1. Filter Hierarki Wilayah (RT vs RW)
        if (_selectedRtFilter != 'Seluruh RW 01' && widget.role == 'rw') {
          if (warga['rt_rw'] != _selectedRtFilter) return false;
        } else if (widget.role == 'rt') {
          // Jika Admin adalah RT, batasi HANYA wilayah RT 02/RW 01 (kecuali disetel lain)
          if (warga['rt_rw'] != 'RT 02 / RW 01') return false;
        }

        // 2. Filter Pencarian Teks
        final matchesSearch = warga['name']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            warga['id']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            warga['address']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());

        if (!matchesSearch) return false;

        // 3. Filter Status Domisili & Verifikasi
        if (_selectedFilter == 'Semua') {
          return true;
        } else if (_selectedFilter == 'Menunggu Validasi') {
          return warga['verification_status'] == 'Menunggu Validasi';
        } else if (_selectedFilter == 'Tervalidasi AI') {
          return warga['verification_status'] == 'Tervalidasi AI';
        } else if (_selectedFilter == 'Warga Menetap') {
          return warga['residency_type'] == 'Warga Menetap';
        } else if (_selectedFilter == 'Pendatang / Kost') {
          return warga['residency_type'] == 'Pendatang / Kost';
        }
        return true;
      }).toList();
    });
  }

  void _approveVerification(String id, String name) {
    setState(() {
      final index = _allWarga.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        _allWarga[index]['verification_status'] = 'Tervalidasi AI';
      }
      _applyFiltersAndSearch();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Data domisili & scan wajah untuk $name telah berhasil disetujui oleh Koordinator.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showResidentDetailModal(Map<String, dynamic> warga) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 25,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withAlpha(80),
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Color(0xFF3B82F6),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Arsip Buku Induk Wilayah ${warga['rt_rw']}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.blueAccent : Colors.blue.shade800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        warga['name'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
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
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.withAlpha(40),
                ),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    isDark,
                    'Nomor Identitas (NIK)',
                    warga['masked_nik'],
                    Icons.shield_rounded,
                    isMono: true,
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    isDark,
                    'ID Register Desa',
                    warga['id'],
                    Icons.badge_rounded,
                    isMono: true,
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    isDark,
                    'Status Dalam Keluarga',
                    '${warga['family_role']} (${warga['members_count']} Jiwa)',
                    Icons.family_restroom_rounded,
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    isDark,
                    'Alamat Domisili',
                    '${warga['address']}, ${warga['rt_rw']}',
                    Icons.home_work_rounded,
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    isDark,
                    'Pekerjaan Utama',
                    warga['occupation'],
                    Icons.work_outline_rounded,
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    isDark,
                    'Tanggal Terdaftar',
                    warga['registered_date'],
                    Icons.calendar_today_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (warga['verification_status'] == 'Menunggu Validasi')
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _approveVerification(warga['id'], warga['name']);
                  },
                  icon: const Icon(Icons.verified_user_rounded, size: 20),
                  label: const Text(
                    'SETUJUI VERIFIKASI DOMISILI & WAJAH',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded, size: 20),
                label: const Text(
                  'TUTUP ARSIP',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey.shade400,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    bool isDark,
    String label,
    String value,
    IconData icon, {
    bool isMono = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13.5,
              color: isDark ? Colors.white : Colors.grey.shade900,
              fontWeight: FontWeight.w800,
              fontFamily: isMono ? 'Courier' : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isRwMode = widget.role == 'rw';

    // Hitung statistik berdasarkan daftar warga yang sudah difilter oleh Wilayah RT/RW saat ini
    final scopedWarga = _allWarga.where((warga) {
      if (isRwMode && _selectedRtFilter != 'Seluruh RW 01') {
        return warga['rt_rw'] == _selectedRtFilter;
      } else if (!isRwMode) {
        return warga['rt_rw'] == 'RT 02 / RW 01';
      }
      return true;
    }).toList();

    int totalKK = scopedWarga.length;
    int totalJiwa = scopedWarga.fold<int>(
      0,
      (sum, item) => sum + (item['members_count'] as int),
    );
    int pendingCount = scopedWarga
        .where((w) => w['verification_status'] == 'Menunggu Validasi')
        .length;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // PREMIUM ULTRA-HERO HEADER
          SliverAppBar(
            expandedHeight: isRwMode ? 225 : 200,
            floating: false,
            pinned: true,
            backgroundColor: isDark
                ? const Color(0xFF0F172A)
                : const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF021B3A),
                            const Color(0xFF0F172A),
                            const Color(0xFF1E1B4B),
                          ]
                        : [
                            const Color(0xFF1D4ED8),
                            const Color(0xFF2563EB),
                            const Color(0xFF1E40AF),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(15),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(90),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isRwMode
                                          ? const Color(0xFF10B981).withAlpha(180)
                                          : const Color(0xFF3B82F6).withAlpha(180),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isRwMode
                                            ? Icons.account_tree_rounded
                                            : Icons.shield_rounded,
                                        color: isRwMode
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF3B82F6),
                                        size: 13,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          isRwMode
                                              ? 'KOORDINATOR WILAYAH • RW 01 BENGKALA'
                                              : 'WILAYAH • RT 02 / RW 01',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (pendingCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFF59E0B,
                                      ).withAlpha(40),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFF59E0B),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.pending_actions_rounded,
                                          color: Color(0xFFF59E0B),
                                          size: 13,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$pendingCount Menunggu',
                                          style: const TextStyle(
                                            color: Color(0xFFF59E0B),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isRwMode
                                  ? 'Buku Induk Multi-RT (RW 01)'
                                  : 'Buku Induk & Domisili Warga',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isRwMode
                                  ? 'Hierarki koordinasi seluruh warga RT 01, 02, 03, & 04'
                                  : 'Kelola kepemilikan domisili, validasi KYC, & arsip KK',
                              style: TextStyle(
                                color: Colors.white.withAlpha(210),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // SUMMARY KPI DASHBOARD BAR
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      isDark,
                      isRwMode ? 'Total KK (RW)' : 'Total KK',
                      '$totalKK',
                      'Kepala Keluarga',
                      Icons.folder_shared_rounded,
                      const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      isDark,
                      isRwMode ? 'Jiwa (RW 01)' : 'Total Jiwa',
                      '$totalJiwa',
                      'Warga Terdaftar',
                      Icons.groups_rounded,
                      const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryCard(
                      context,
                      isDark,
                      'Pending AI',
                      '$pendingCount',
                      'Butuh Validasi',
                      Icons.verified_rounded,
                      const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // HIERARCHICAL RT SELECTOR (EKSKLUSIF UNTUK KOORDINATOR RW)
          if (isRwMode)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_tree_rounded, size: 18, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        const Text(
                          'Hierarki Wilayah (Filter Per RT):',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 42,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _rtRegions.length,
                        itemBuilder: (context, index) {
                          final rt = _rtRegions[index];
                          final isSelected = _selectedRtFilter == rt;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              label: Text(rt),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) {
                                  _selectedRtFilter = rt;
                                  _applyFiltersAndSearch();
                                }
                              },
                              selectedColor: const Color(0xFF1E3A8A),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                fontSize: 13,
                              ),
                              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected ? Colors.transparent : (isDark ? Colors.white24 : Colors.grey.withAlpha(60)),
                                  width: 1.4,
                                ),
                              ),
                              elevation: isSelected ? 4 : 0,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    Divider(color: isDark ? Colors.white12 : Colors.grey.withAlpha(40)),
                  ],
                ),
              ),
            ),

          // SEARCH BAR & FILTERS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Field
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.withAlpha(50),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 20 : 10),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        _searchQuery = val;
                        _applyFiltersAndSearch();
                      },
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari Nama Warga, ID Register, atau Alamat...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                          fontSize: 13.5,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 22),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _applyFiltersAndSearch();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Filter Chips (Status Domisili)
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _selectedFilter = filter;
                                _applyFiltersAndSearch();
                              }
                            },
                            selectedColor: const Color(0xFF3B82F6),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.grey.shade300
                                      : Colors.grey.shade700),
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 12.5,
                            ),
                            backgroundColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : (isDark
                                        ? Colors.white24
                                        : Colors.grey.withAlpha(60)),
                                width: 1.3,
                              ),
                            ),
                            elevation: isSelected ? 3 : 0,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // RESIDENT LIST
          if (_filteredWarga.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person_off_rounded,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak Ada Data Warga Ditemukan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Coba ubah kata kunci pencarian atau filter status Anda.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final warga = _filteredWarga[index];
                  return _buildResidentCard(warga, isDark);
                }, childCount: _filteredWarga.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    bool isDark,
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withAlpha(60),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(15),
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
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildResidentCard(Map<String, dynamic> warga, bool isDark) {
    final bool isVerified = warga['verification_status'] == 'Tervalidasi AI';
    final bool isMenetap = warga['residency_type'] == 'Warga Menetap';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isVerified
              ? (isDark ? Colors.white12 : Colors.grey.withAlpha(40))
              : const Color(0xFFF59E0B).withAlpha(150),
          width: isVerified ? 1.2 : 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _showResidentDetailModal(warga),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row with Status Badge & Residency Type
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isMenetap
                            ? const Color(0xFF3B82F6).withAlpha(25)
                            : const Color(0xFF8B5CF6).withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isMenetap
                              ? const Color(0xFF3B82F6).withAlpha(80)
                              : const Color(0xFF8B5CF6).withAlpha(80),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isMenetap
                                ? Icons.home_rounded
                                : Icons.luggage_rounded,
                            size: 13,
                            color: isMenetap
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF8B5CF6),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            warga['residency_type'],
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: isMenetap
                                  ? const Color(0xFF3B82F6)
                                  : const Color(0xFF8B5CF6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isVerified
                            ? const Color(0xFF10B981).withAlpha(25)
                            : const Color(0xFFF59E0B).withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isVerified
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isVerified
                                ? Icons.check_circle_rounded
                                : Icons.timer_rounded,
                            size: 13,
                            color: isVerified
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            warga['verification_status'],
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: isVerified
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Main Identity Info
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isVerified
                              ? [
                                  const Color(0xFF3B82F6),
                                  const Color(0xFF1D4ED8),
                                ]
                              : [
                                  const Color(0xFFF59E0B),
                                  const Color(0xFFD97706),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: (isVerified
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFF59E0B))
                                .withAlpha(60),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            warga['name'],
                            style: TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.grey.shade900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'ID: ${warga['id']} • ${warga['rt_rw']}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                      size: 26,
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(
                  color: isDark ? Colors.white12 : Colors.grey.withAlpha(40),
                  height: 1,
                ),
                const SizedBox(height: 14),

                // Footer Row: Address & Member count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              warga['address'],
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withAlpha(80)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            size: 14,
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${warga['members_count']} Jiwa',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // If pending, show a prominent quick approval button
                if (!isVerified) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _approveVerification(warga['id'], warga['name']),
                      icon: const Icon(
                        Icons.fact_check_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'VALIDASI & SETUJUI DOMISILI SEKARANG',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
