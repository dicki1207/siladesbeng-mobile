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
  static const Color _primaryBlue = Color(0xFF2563EB);

  String _selectedFilter = 'Semua';
  String _selectedRtFilter = 'Seluruh RW 01';
  String _searchQuery = '';
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  final AdminWargaService _adminWargaService = AdminWargaService();

  final List<String> _filters = [
    'Semua',
    'Menunggu Validasi',
    'Terverifikasi',
  ];

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
            displayStatus = 'Menunggu Validasi';
          }

          final String rawNik = (item['kyc_nik'] ?? '').toString();
          String maskedNik = 'Belum KYC';
          if (rawNik.isNotEmpty && rawNik.length >= 8) {
            maskedNik = '${rawNik.substring(0, 4)}••••••••${rawNik.length > 12 ? rawNik.substring(12) : ''}';
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
            'rt_rw': item['rt_rw'] ?? (widget.role == 'rt' ? 'RT 02 / RW 01' : 'RW 01'),
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
          if (!name.contains(query) && !id.contains(query) && !address.contains(query) && !nik.contains(query)) {
            return false;
          }
        }

        // 3. Filter status
        if (_selectedFilter == 'Menunggu Validasi') {
          return warga['verification_status'] == 'Menunggu Validasi';
        } else if (_selectedFilter == 'Terverifikasi') {
          return warga['verification_status'] == 'Terverifikasi';
        }
        return true;
      }).toList();
    });
  }

  Future<void> _approveVerification(int id, String name) async {
    final response = await _adminWargaService.approveKyc(id);
    if (!mounted) return;

    if (response['status'] == 'success') {
      await _loadWargaFromApi();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Verifikasi untuk $name berhasil disetujui.',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
              ),
            ],
          ),
          backgroundColor: _primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Gagal menyetujui verifikasi'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _rejectVerification(int id, String name) async {
    final TextEditingController reasonController = TextEditingController();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Tolak Verifikasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red.shade700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alasan penolakan untuk $name:', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Contoh: Foto KTP tidak jelas',
                hintStyle: const TextStyle(fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(fontSize: 12.5)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Tolak', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await _adminWargaService.rejectKyc(
        id,
        notes: reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : null,
      );
      if (!mounted) return;

      if (response['status'] == 'success') {
        await _loadWargaFromApi();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verifikasi untuk $name telah ditolak.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _showResidentDetailModal(Map<String, dynamic> warga) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isPending = warga['verification_status'] == 'Menunggu Validasi';
    final int rawId = warga['raw_id'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(isDark ? 80 : 100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _primaryBlue.withAlpha(isDark ? 40 : 15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        warga['name'].isNotEmpty ? warga['name'][0].toUpperCase() : 'W',
                        style: const TextStyle(
                          color: _primaryBlue,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          warga['name'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${warga['rt_rw']} • ID: ${warga['id']}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPending
                          ? const Color(0xFFF59E0B).withAlpha(isDark ? 40 : 15)
                          : _primaryBlue.withAlpha(isDark ? 40 : 15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      warga['verification_status'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPending ? const Color(0xFFD97706) : _primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildCompactDetailItem(isDark, 'Nomor NIK', warga['masked_nik'], Icons.badge_outlined),
                    const Divider(height: 12),
                    _buildCompactDetailItem(isDark, 'Alamat', warga['address'], Icons.location_on_outlined),
                    const Divider(height: 12),
                    _buildCompactDetailItem(isDark, 'Telepon', warga['phone'], Icons.phone_outlined),
                    const Divider(height: 12),
                    _buildCompactDetailItem(isDark, 'Wilayah', warga['rt_rw'], Icons.domain_outlined),
                    const Divider(height: 12),
                    _buildCompactDetailItem(isDark, 'Terdaftar', warga['registered_date'], Icons.calendar_today_outlined),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              if (isPending) ...[
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _rejectVerification(rawId, warga['name']);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _approveVerification(rawId, warga['name']);
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 15),
                        label: const Text('Setujui Validasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],

              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Tutup',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                      fontSize: 12,
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

  Widget _buildCompactDetailItem(bool isDark, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _primaryBlue),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
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
    final int verifiedWarga = _allWarga.where((w) => w['verification_status'] == 'Terverifikasi').length;
    final int pendingWarga = _allWarga.where((w) => w['verification_status'] == 'Menunggu Validasi').length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buku Induk & Data Warga',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              isRwMode ? 'Cakupan RW 01' : 'Wilayah RT 02 / RW 01',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _primaryBlue,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, size: 19, color: isDark ? Colors.white70 : _primaryBlue),
            tooltip: 'Segarkan',
            onPressed: _loadWargaFromApi,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWargaFromApi,
        color: _primaryBlue,
        child: Column(
          children: [
            // Top Compact Container (Stats + Search + Filter)
            Container(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Unified Slim Horizontal Stat Bar (Anti-Truncation)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildInlineStatItem(
                            isDark: isDark,
                            label: 'Total Warga',
                            count: '$totalWarga',
                            color: _primaryBlue,
                          ),
                        ),
                        Container(width: 1, height: 24, color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                        Expanded(
                          child: _buildInlineStatItem(
                            isDark: isDark,
                            label: 'Terverifikasi',
                            count: '$verifiedWarga',
                            color: const Color(0xFF059669),
                          ),
                        ),
                        Container(width: 1, height: 24, color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
                        Expanded(
                          child: _buildInlineStatItem(
                            isDark: isDark,
                            label: 'Menunggu',
                            count: '$pendingWarga',
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 2. Compact Search Field (Height 38px)
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        _searchQuery = val;
                        _applyFiltersAndSearch();
                      },
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari nama warga, NIK, atau alamat...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade500 : const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _primaryBlue),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _applyFiltersAndSearch();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 3. Compact Filter Chips
                  SizedBox(
                    height: 28,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedFilter = filter;
                                _applyFiltersAndSearch();
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _primaryBlue
                                    : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.grey.shade300 : const Color(0xFF475569)),
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // 4. Hierarchical RT Selector (For RW Admin)
                  if (isRwMode) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 26,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _rtRegions.length,
                        itemBuilder: (context, index) {
                          final rt = _rtRegions[index];
                          final isSelected = _selectedRtFilter == rt;
                          return Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: InkWell(
                              onTap: () {
                                _selectedRtFilter = rt;
                                _applyFiltersAndSearch();
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _primaryBlue.withAlpha(isDark ? 40 : 15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isSelected ? _primaryBlue : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                                  ),
                                ),
                                child: Text(
                                  rt,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? _primaryBlue : (isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),

            // Body List Section
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: _primaryBlue, strokeWidth: 2.5))
                  : _filteredWarga.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_search_rounded,
                                size: 44,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Data warga tidak ditemukan',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Coba sesuaikan kata kunci pencarian atau filter.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? Colors.grey.shade500 : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredWarga.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final warga = _filteredWarga[index];
                            return _buildCleanResidentCard(warga, isDark);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineStatItem({
    required bool isDark,
    required String label,
    required String count,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCleanResidentCard(Map<String, dynamic> warga, bool isDark) {
    final bool isVerified = warga['verification_status'] == 'Terverifikasi';
    final int rawId = warga['raw_id'] ?? 0;

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
          onTap: () => _showResidentDetailModal(warga),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Clean Circle Avatar with Initial
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isVerified
                        ? _primaryBlue.withAlpha(isDark ? 40 : 15)
                        : const Color(0xFFF59E0B).withAlpha(isDark ? 40 : 15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      warga['name'].isNotEmpty ? warga['name'][0].toUpperCase() : 'W',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isVerified ? _primaryBlue : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

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
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (isVerified)
                            const Icon(Icons.verified_rounded, size: 13, color: _primaryBlue),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'NIK: ${warga['masked_nik']} • ${warga['rt_rw']}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Action / Status
                if (!isVerified)
                  InkWell(
                    onTap: () => _approveVerification(rawId, warga['name']),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withAlpha(isDark ? 35 : 15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFF59E0B).withAlpha(80)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 11, color: Color(0xFFD97706)),
                          SizedBox(width: 3),
                          Text(
                            'Validasi',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
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
