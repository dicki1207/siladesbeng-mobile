import 'package:flutter/material.dart';
import 'package:siladesbeng_mobile/services/admin_warga_service.dart';

class AdminWargaListPage extends StatefulWidget {
  final String role;
  final String? filterRt;
  const AdminWargaListPage({super.key, this.role = 'rt', this.filterRt});

  @override
  State<AdminWargaListPage> createState() => _AdminWargaListPageState();
}

class _AdminWargaListPageState extends State<AdminWargaListPage> {
  static const Color _primaryBlue = Color(0xFF0EA5E9);

  String _selectedFilter = 'Semua';
  String _selectedRtFilter = 'Seluruh RW 01';
  String _searchQuery = '';
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final AdminWargaService _adminWargaService = AdminWargaService();

  final List<String> _rtRegions = [
    'Seluruh RW 01',
    'RT 01 / RW 01',
    'RT 02 / RW 01',
    'RT 03 / RW 01',
    'RT 04 / RW 01',
  ];

  List<Map<String, dynamic>> _allWarga = [];
  List<Map<String, dynamic>> _filteredWarga = [];

  @override
  void initState() {
    super.initState();
    if (widget.filterRt != null && _rtRegions.contains(widget.filterRt)) {
      _selectedRtFilter = widget.filterRt!;
    } else if (widget.role == 'rt') {
      _selectedRtFilter = 'RT 02 / RW 01';
    }
    _loadWargaFromApi();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWargaFromApi() async {
    setState(() => _isLoading = true);
    try {
      final data = await _adminWargaService.getWargaList();
      if (!mounted) return;

      setState(() {
        _allWarga = data.map<Map<String, dynamic>>((item) {
          final String verStatus = item['verification_status'] ?? 'unverified';
          final String? kycStatus = item['kyc_status'];

          String displayStatus;
          if (verStatus == 'verified' || kycStatus == 'approved') {
            displayStatus = 'Terverifikasi';
          } else {
            displayStatus = 'Belum Verifikasi';
          }

          final String rawNik = (item['kyc_nik'] ?? '').toString();
          String maskedNik = 'Belum KYC';
          if (rawNik.isNotEmpty && rawNik.length >= 8) {
            maskedNik =
                '${rawNik.substring(0, 4)}••••••••${rawNik.length > 12 ? rawNik.substring(12) : ''}';
          } else if (rawNik.isNotEmpty) {
            maskedNik = rawNik;
          }

          return {
            'id': item['id']?.toString() ?? '',
            'raw_id': int.tryParse(item['id']?.toString() ?? '0') ?? 0,
            'name': item['name'] ?? 'Warga',
            'masked_nik': maskedNik,
            'email': item['email'] ?? '-',
            'address': item['address'] ?? '-',
            'rt_rw':
                item['rt_rw'] ??
                (widget.role == 'rt' ? 'RT 02 / RW 01' : 'RW 01'),
            'verification_status': displayStatus,
            'phone': item['phone'] ?? '-',
            'registered_date': item['registered_date'] ?? '-',
          };
        }).toList();
        _applyFiltersAndSearch();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFiltersAndSearch() {
    final query = _searchQuery.trim().toLowerCase();

    setState(() {
      _filteredWarga = _allWarga.where((warga) {
        // 1. Filter RT untuk RW
        if (widget.role == 'rw' && _selectedRtFilter != 'Seluruh RW 01') {
          if (warga['rt_rw'] != _selectedRtFilter) return false;
        }

        // 2. Search query
        if (query.isNotEmpty) {
          final name = warga['name'].toString().toLowerCase();
          final id = warga['id'].toString().toLowerCase();
          final address = warga['address'].toString().toLowerCase();
          final nik = warga['masked_nik'].toString().toLowerCase();
          if (!name.contains(query) &&
              !id.contains(query) &&
              !address.contains(query) &&
              !nik.contains(query)) {
            return false;
          }
        }

        // 3. Filter status
        if (_selectedFilter == 'Belum Verifikasi') {
          return warga['verification_status'] == 'Belum Verifikasi' ||
              warga['verification_status'] == 'Menunggu Validasi';
        } else if (_selectedFilter == 'Terverifikasi') {
          return warga['verification_status'] == 'Terverifikasi';
        }
        return true;
      }).toList();
    });
  }

  void _showResidentDetailModal(Map<String, dynamic> warga) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isVerified = warga['verification_status'] == 'Terverifikasi';
    final bool isPending = !isVerified;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: isDark ? const Color(0xFF1E293B) : Colors.transparent,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(isDark ? 80 : 100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header in Modal
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPending
                            ? [const Color(0xFFD97706), const Color(0xFFF59E0B)]
                            : [
                                const Color(0xFF1D4ED8),
                                const Color(0xFF3B82F6),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isPending
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF2563EB))
                                  .withAlpha(80),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        warga['name'].isNotEmpty
                            ? warga['name'][0].toUpperCase()
                            : 'W',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${warga['rt_rw']} • ID: #${warga['id']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
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
                      color: isPending
                          ? const Color(0xFFF59E0B).withAlpha(isDark ? 40 : 20)
                          : const Color(0xFF10B981).withAlpha(isDark ? 40 : 20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPending
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      warga['verification_status'],
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isPending
                            ? const Color(0xFFD97706)
                            : const Color(0xFF059669),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Detail List Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF131C2E)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    _buildCompactDetailItem(
                      isDark,
                      'Nomor Induk KTP (NIK)',
                      warga['masked_nik'],
                      Icons.badge_rounded,
                    ),
                    const Divider(height: 16),
                    _buildCompactDetailItem(
                      isDark,
                      'Alamat Domisili',
                      warga['address'],
                      Icons.location_on_rounded,
                    ),
                    const Divider(height: 16),
                    _buildCompactDetailItem(
                      isDark,
                      'Nomor Kontak',
                      warga['phone'],
                      Icons.phone_rounded,
                    ),
                    const Divider(height: 16),
                    _buildCompactDetailItem(
                      isDark,
                      'Cakupan Wilayah',
                      warga['rt_rw'],
                      Icons.holiday_village_rounded,
                    ),
                    const Divider(height: 16),
                    _buildCompactDetailItem(
                      isDark,
                      'Tanggal Registrasi',
                      warga['registered_date'],
                      Icons.calendar_month_rounded,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Verification Status Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: isVerified
                      ? const Color(
                          0xFF10B981,
                        ).withValues(alpha: isDark ? 0.2 : 0.1)
                      : const Color(
                          0xFFF59E0B,
                        ).withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isVerified
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isVerified
                          ? Icons.verified_user_rounded
                          : Icons.info_outline_rounded,
                      size: 20,
                      color: isVerified
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isVerified
                            ? 'Status KTP telah Terverifikasi Resmi oleh Pemerintah Desa.'
                            : 'Warga belum melakukan verifikasi / menunggu validasi Kantor Desa.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isVerified
                              ? const Color(0xFF10B981)
                              : const Color(0xFFD97706),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Tutup Detail',
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : const Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDetailItem(
    bool isDark,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _primaryBlue.withAlpha(isDark ? 35 : 20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: _primaryBlue),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isRwMode = widget.role == 'rw';

    final int totalWarga = _allWarga.length;
    final int verifiedWarga = _allWarga
        .where((w) => w['verification_status'] == 'Terverifikasi')
        .length;
    final int pendingWarga = _allWarga
        .where((w) => w['verification_status'] == 'Menunggu Validasi')
        .length;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF090D16)
          : const Color(0xFFF4F6FA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 145,
              pinned: true,
              floating: false,
              elevation: 0,
              scrolledUnderElevation: 2,
              backgroundColor: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF2FA2F1),
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
                                ]
                              : [
                                  const Color(0xFF2FA2F1),
                                  const Color(0xFF0284C7),
                                ],
                        ),
                      ),
                    ),
                    // Ambient light circle 1 (Top Right)
                    Positioned(
                      right: -25,
                      top: -25,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(22),
                        ),
                      ),
                    ),
                    // Ambient light circle 2 (Bottom Left)
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(14),
                        ),
                      ),
                    ),
                    // Title and Scope in Header
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 16,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(35),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withAlpha(40),
                              ),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Buku Induk Kependudukan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(30),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.place_rounded,
                                        size: 12,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isRwMode
                                            ? 'Cakupan: Seluruh RW 01'
                                            : 'Wilayah Kerja: RT 02 / RW 01',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
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
                  ],
                ),
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _loadWargaFromApi,
          color: _primaryBlue,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── 1. DASHBOARD METRIC STAT CARDS (INTERACTIVE) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      // Total Card
                      Expanded(
                        child: _buildInteractiveStatCard(
                          isDark: isDark,
                          title: 'Total Warga',
                          count: '$totalWarga',
                          subtitle: 'Terdaftar',
                          color: const Color(0xFF2563EB),
                          icon: Icons.people_alt_rounded,
                          isSelected: _selectedFilter == 'Semua',
                          onTap: () {
                            setState(() {
                              _selectedFilter = 'Semua';
                              _applyFiltersAndSearch();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Terverifikasi Card
                      Expanded(
                        child: _buildInteractiveStatCard(
                          isDark: isDark,
                          title: 'Terverifikasi',
                          count: '$verifiedWarga',
                          subtitle: 'Data Valid',
                          color: const Color(0xFF10B981),
                          icon: Icons.verified_user_rounded,
                          isSelected: _selectedFilter == 'Terverifikasi',
                          onTap: () {
                            setState(() {
                              _selectedFilter = 'Terverifikasi';
                              _applyFiltersAndSearch();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Belum Verifikasi Card
                      Expanded(
                        child: _buildInteractiveStatCard(
                          isDark: isDark,
                          title: 'Belum Valid',
                          count: '$pendingWarga',
                          subtitle: 'Verif Desa',
                          color: const Color(0xFFF59E0B),
                          icon: Icons.pending_actions_rounded,
                          isSelected: _selectedFilter == 'Belum Verifikasi',
                          onTap: () {
                            setState(() {
                              _selectedFilter = 'Belum Verifikasi';
                              _applyFiltersAndSearch();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── 2. SEARCH & FILTER CONTROLS ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Modern Rounded Search Bar
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF131C2E)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 25 : 5),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
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
                            fontSize: 13,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Cari nama warga, NIK, atau alamat...',
                            hintStyle: TextStyle(
                              fontSize: 12.5,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : const Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: _primaryBlue,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.cancel_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchQuery = '';
                                      _applyFiltersAndSearch();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),

                      // Hierarchical RT Selector (For RW Admin)
                      if (isRwMode) ...[
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _rtRegions.map((rt) {
                              final isSelected = _selectedRtFilter == rt;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedRtFilter = rt;
                                      _applyFiltersAndSearch();
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? _primaryBlue.withAlpha(
                                              isDark ? 45 : 20,
                                            )
                                          : (isDark
                                                ? const Color(0xFF131C2E)
                                                : Colors.white),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? _primaryBlue
                                            : (isDark
                                                  ? const Color(0xFF1E293B)
                                                  : const Color(0xFFE2E8F0)),
                                      ),
                                    ),
                                    child: Text(
                                      rt,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? _primaryBlue
                                            : (isDark
                                                  ? Colors.grey.shade400
                                                  : const Color(0xFF64748B)),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── 3. LIST CONTENT OR RICH EMPTY STATE ──
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: _primaryBlue),
                  ),
                )
              else if (_filteredWarga.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Rich civic empty illustration container
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: _primaryBlue.withAlpha(isDark ? 25 : 15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.folder_shared_rounded,
                              size: 46,
                              color: _primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Data Warga Belum Ditemukan',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Tidak ada hasil untuk kata kunci "$_searchQuery". Periksa kembali ejaan nama atau NIK.'
                                : 'Belum ada warga yang terdaftar pada filter "$_selectedFilter". Data pendaftar aplikasi akan otomatis masuk ke sini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty ||
                              _selectedFilter != 'Semua') ...[
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedFilter = 'Semua';
                                  _selectedRtFilter = isRwMode
                                      ? 'Seluruh RW 01'
                                      : 'RT 02 / RW 01';
                                  _applyFiltersAndSearch();
                                });
                              },
                              icon: const Icon(
                                Icons.restart_alt_rounded,
                                size: 16,
                              ),
                              label: const Text('Reset Filter Pencarian'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryBlue,
                                side: const BorderSide(color: _primaryBlue),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final warga = _filteredWarga[index];
                      return _buildCleanResidentCard(warga, isDark);
                    }, childCount: _filteredWarga.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // REUSABLE DASHBOARD WIDGETS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildInteractiveStatCard({
    required bool isDark,
    required String title,
    required String count,
    required String subtitle,
    required Color color,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
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
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 20 : 4),
                    blurRadius: 6,
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
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(isDark ? 40 : 20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? color
                    : (isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9.5,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanResidentCard(Map<String, dynamic> warga, bool isDark) {
    final bool isVerified = warga['verification_status'] == 'Terverifikasi';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showResidentDetailModal(warga),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Clean Avatar with Initial
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isVerified
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      warga['name'].isNotEmpty
                          ? warga['name'][0].toUpperCase()
                          : 'W',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Name & Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              warga['name'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (isVerified)
                            const Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: Color(0xFF10B981),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFF59E0B,
                                ).withAlpha(isDark ? 35 : 20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Pending',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.badge_rounded,
                            size: 12,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            warga['masked_nik'],
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  ${warga['rt_rw']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.grey.shade500
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Clean Detail Chevron
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? Colors.white30 : const Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
