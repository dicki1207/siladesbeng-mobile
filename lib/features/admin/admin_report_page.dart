import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';
import 'package:siladesbeng_mobile/features/admin/admin_report_detail_page.dart';

class AdminReportPage extends StatefulWidget {
  const AdminReportPage({super.key});

  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  String _role = 'rt';
  String _profileName = '';
  List<Map<String, dynamic>> _allReports = [];
  List<Map<String, dynamic>> _filteredReports = [];
  bool _isLoading = true;
  String _selectedFilter = 'Semua';

  final List<String> _filters = ['Semua', 'Menunggu', 'Diproses', 'Selesai'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadRole();
    await _fetchReports();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _role = prefs.getString('user_role') ?? 'rt';
        _profileName = prefs.getString('profile_name') ?? 'Pengurus';
      });
    }
  }

  Future<void> _fetchReports() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('auth_token');

    if (token != null) {
      try {
        final res = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/admin-reports'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        if (res.statusCode == 200) {
          final decoded = json.decode(res.body);
          if (decoded['data'] != null) {
            final List fetchedData = decoded['data'];
            if (mounted) {
              setState(() {
                _allReports = fetchedData.map<Map<String, dynamic>>((e) {
                  final userObj = e['user'] is Map
                      ? e['user'] as Map<String, dynamic>
                      : null;
                  final String reporterName =
                      userObj?['name'] ??
                      (e['nama'] != null && e['nama'].toString().isNotEmpty
                          ? e['nama'].toString()
                          : 'Warga Desa');
                  final String kategori = e['kategori'] ?? 'Laporan Warga';
                  final String deskripsi = e['deskripsi'] ?? '';
                  final String rawStatus = e['status'] ?? 'Pending';

                  // Normalisasi status untuk filter
                  String normalizedStatus = 'Menunggu';
                  final sLower = rawStatus.toLowerCase();
                  if (sLower == 'pending' || sLower == 'menunggu') {
                    normalizedStatus = 'Menunggu';
                  } else if (sLower.contains('proses') ||
                      sLower.contains('teruskan')) {
                    normalizedStatus = 'Diproses';
                  } else if (sLower == 'selesai') {
                    normalizedStatus = 'Selesai';
                  } else if (sLower == 'ditolak') {
                    normalizedStatus = 'Ditolak';
                  }

                  String dateStr = '';
                  if (e['created_at'] != null) {
                    try {
                      final dt = DateTime.parse(e['created_at'].toString());
                      dateStr =
                          '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
                    } catch (_) {
                      dateStr = e['created_at'].toString().substring(0, 10);
                    }
                  }

                  // Debug: tampilkan data bukti mentah dari API
                  debugPrint(
                    '📸 Laporan #${e['id']} bukti=${e['bukti']} | foto_bukti=${e['foto_bukti']} | foto=${e['foto']}',
                  );

                  return {
                    'id': e['id'].toString(),
                    'title': kategori,
                    'kategori': kategori,
                    'category': kategori,
                    'reporter': reporterName,
                    'reporter_name': reporterName,
                    'date': dateStr,
                    'status': rawStatus,
                    'normalized_status': normalizedStatus,
                    'description': deskripsi,
                    'deskripsi': deskripsi,
                    'lokasi': e['lokasi'] ?? '',
                    'bukti': e['bukti'],
                    'foto_bukti': e['foto_bukti'],
                    'foto': e['foto'],
                    'user': userObj,
                  };
                }).toList();
                _applyFilter(_selectedFilter);
                _isLoading = false;
              });
            }
            return;
          }
        }
      } catch (e) {
        debugPrint('Error fetching reports: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'Semua') {
        _filteredReports = _allReports;
      } else {
        _filteredReports = _allReports.where((r) {
          final norm = r['normalized_status'] ?? '';
          return norm == filter;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFF2563EB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [const Color(0xFF2FA2F1), const Color(0xFF0284C7)],
                ),
              ),
            ),
            // Glowing circle 1 (Top Right)
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(22),
                ),
              ),
            ),
            // Glowing circle 2 (Bottom Left)
            Positioned(
              bottom: -25,
              left: -15,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(14),
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kelola Laporan Warga',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: 0.2,
              ),
            ),
            if (_profileName.isNotEmpty)
              Text(
                '$_profileName • ${_role.toUpperCase()}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchReports,
        color: primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Filter Choice Chips Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) _applyFilter(filter);
                          },
                          selectedColor: const Color(0xFF2563EB),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569)),
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                          backgroundColor: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : (isDark
                                        ? Colors.white12
                                        : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            if (_isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filteredReports.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withAlpha(15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Tidak ada laporan ($_selectedFilter)',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final report = _filteredReports[index];
                    return _buildModernReportCard(report, isDark);
                  }, childCount: _filteredReports.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernReportCard(Map<String, dynamic> report, bool isDark) {
    final status = report['status'] ?? 'Pending';
    final sLower = status.toString().toLowerCase();

    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;

    if (sLower == 'selesai') {
      statusColor = const Color(0xFF10B981);
      statusBgColor = const Color(0xFF10B981).withAlpha(20);
      statusIcon = Icons.check_circle_rounded;
    } else if (sLower.contains('proses') || sLower.contains('teruskan')) {
      statusColor = const Color(0xFF2563EB);
      statusBgColor = const Color(0xFF2563EB).withAlpha(20);
      statusIcon = Icons.autorenew_rounded;
    } else if (sLower == 'ditolak') {
      statusColor = Colors.redAccent;
      statusBgColor = Colors.redAccent.withAlpha(20);
      statusIcon = Icons.cancel_rounded;
    } else {
      statusColor = Colors.amber.shade700;
      statusBgColor = Colors.amber.withAlpha(25);
      statusIcon = Icons.access_time_rounded;
    }

    final String title = report['title']?.isNotEmpty == true
        ? report['title']
        : 'Laporan Aduan';
    final String description = report['deskripsi']?.isNotEmpty == true
        ? report['deskripsi']
        : 'Tidak ada deskripsi detail.';
    final String reporter = report['reporter']?.isNotEmpty == true
        ? report['reporter']
        : 'Warga';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AdminReportDetailPage(report: report, role: _role),
              ),
            ).then((_) => _fetchReports());
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withAlpha(15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${report['id']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 13, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title (Category)
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Description
                Text(
                  description,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 14),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                ),
                const SizedBox(height: 10),

                // Footer Row: Pelapor & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 15,
                          color: const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          reporter,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF334155),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (report['date'] != null &&
                        report['date'].toString().isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: isDark ? Colors.white38 : Colors.grey[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            report['date'],
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey[500],
                              fontSize: 11.5,
                            ),
                          ),
                        ],
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
