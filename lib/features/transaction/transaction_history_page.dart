import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';
import 'package:siladesbeng_mobile/features/auth/login_page.dart';
import 'package:siladesbeng_mobile/features/transaction/transaction_detail_page.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => TransactionHistoryPageState();
}

class TransactionHistoryPageState extends State<TransactionHistoryPage> {
  String _selectedCategory = 'Semua';
  String _selectedStatus = 'Semua';
  bool _isLoggedIn = false;
  bool _isLoadingAuth = true;
  bool _isLoadingData = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _transactions = [];

  final ScrollController _scrollController = ScrollController();
  int _displayLimit = 10;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (_displayLimit >= _transactions.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _displayLimit += 10;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
        _isLoadingAuth = false;
      });
      if (_isLoggedIn) {
        _fetchHistory();
      }
    }
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoadingData = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/history'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _transactions = List<Map<String, dynamic>>.from(data['data']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  final List<String> _categories = [
    'Semua',
    'Penyewaan',
    'Pesanan Gas',
    'Sewa Kendaraan',
    'Fasilitas',
    'Laporan Warga',
  ];

  final List<String> _statuses = [
    'Semua',
    'Menunggu',
    'Dikonfirmasi',
    'Selesai',
    'Batal',
  ];

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty || rawDate == '-') return '-';
    try {
      if (rawDate.contains('T') ||
          (rawDate.contains('-') && rawDate.length <= 19)) {
        final parsed = DateTime.parse(rawDate.replaceAll(' WIB', ''));
        return '${DateFormat('d MMM yyyy, HH:mm').format(parsed)} WIB';
      }
      String formatted = rawDate
          .replaceAll('Sunday, ', '')
          .replaceAll('Monday, ', '')
          .replaceAll('Tuesday, ', '')
          .replaceAll('Wednesday, ', '')
          .replaceAll('Thursday, ', '')
          .replaceAll('Friday, ', '')
          .replaceAll('Saturday, ', '')
          .replaceAll('January', 'Jan')
          .replaceAll('February', 'Feb')
          .replaceAll('March', 'Mar')
          .replaceAll('April', 'Apr')
          .replaceAll('May', 'Mei')
          .replaceAll('June', 'Jun')
          .replaceAll('July', 'Jul')
          .replaceAll('August', 'Agu')
          .replaceAll('September', 'Sep')
          .replaceAll('October', 'Okt')
          .replaceAll('November', 'Nov')
          .replaceAll('December', 'Des');
      return formatted;
    } catch (_) {
      return rawDate;
    }
  }

  Widget _buildStatusBadge(String? statusStr) {
    final status = statusStr?.toString().toLowerCase().trim() ?? 'menunggu';
    Color textColor;
    Color bgColor;
    Color borderColor;
    String label;

    switch (status) {
      case 'selesai':
        textColor = const Color(0xFF10B981);
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.12);
        borderColor = const Color(0xFF10B981).withValues(alpha: 0.25);
        label = 'Selesai';
        break;
      case 'dikonfirmasi':
        textColor = const Color(0xFF3B82F6);
        bgColor = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        borderColor = const Color(0xFF3B82F6).withValues(alpha: 0.25);
        label = 'Dikonfirmasi';
        break;
      case 'batal':
        textColor = const Color(0xFFEF4444);
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.12);
        borderColor = const Color(0xFFEF4444).withValues(alpha: 0.25);
        label = 'Batal';
        break;
      case 'menunggu':
      default:
        textColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.12);
        borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.25);
        label = 'Menunggu';
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.5.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 10.5.sp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final bool hasActiveFilter =
        _selectedCategory != 'Semua' || _selectedStatus != 'Semua';

    if (_isLoadingAuth || _isLoadingData) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    List<Map<String, dynamic>> allFilteredList = _transactions.where((item) {
      bool catMatch =
          _selectedCategory == 'Semua' || item['category'] == _selectedCategory;
      bool statMatch =
          _selectedStatus == 'Semua' || item['status'] == _selectedStatus;
      bool searchMatch =
          _searchQuery.isEmpty ||
          (item['title']?.toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);
      return catMatch && statMatch && searchMatch;
    }).toList();

    List<Map<String, dynamic>> filteredList = allFilteredList
        .take(_displayLimit)
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          if (_isLoggedIn) {
            setState(() {
              _displayLimit = 10;
            });
            await _fetchHistory();
          }
        },
        color: primaryColor,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Single Filter Button integrated with Search Bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white12
                                    : Colors.grey.withValues(alpha: 0.15),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.04,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Cari nama layanan...',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey[400],
                                  fontSize: 13.5.sp,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: primaryColor,
                                  size: 22.sp,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.close_rounded,
                                          size: 18.sp,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _searchQuery = '';
                                            _displayLimit = 10;
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 14.h,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                  _displayLimit = 10;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        // 1 Dedicated Filter Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16.r),
                            onTap: _showFilterBottomSheet,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: hasActiveFilter
                                    ? primaryColor
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: hasActiveFilter
                                      ? primaryColor
                                      : (isDark
                                            ? Colors.white12
                                            : Colors.grey.withValues(
                                                alpha: 0.15,
                                              )),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: hasActiveFilter
                                        ? primaryColor.withValues(alpha: 0.3)
                                        : Colors.black.withValues(
                                            alpha: isDark ? 0.2 : 0.04,
                                          ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    color: hasActiveFilter
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.white70
                                              : primaryColor),
                                    size: 22.sp,
                                  ),
                                  if (hasActiveFilter)
                                    Positioned(
                                      top: 10.h,
                                      right: 10.w,
                                      child: Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: Colors.amber,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Active filter chip tag (if filter is applied)
                    if (hasActiveFilter)
                      Padding(
                        padding: EdgeInsets.only(top: 10.h),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Filter: ${_selectedCategory != 'Semua' ? _selectedCategory : ''}${_selectedCategory != 'Semua' && _selectedStatus != 'Semua' ? ' · ' : ''}${_selectedStatus != 'Semua' ? _selectedStatus : ''}',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 11.5.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedCategory = 'Semua';
                                        _selectedStatus = 'Semua';
                                        _displayLimit = 10;
                                      });
                                    },
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 14.sp,
                                      color: primaryColor,
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
            !_isLoggedIn
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildGuestState(),
                  )
                : filteredList.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  )
                : SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 4.h,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return _buildTransactionCard(filteredList[index]);
                      }, childCount: filteredList.length),
                    ),
                  ),
            if (_isLoadingMore)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: 90.h)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFF2563EB),
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
      title: Text(
        'Riwayat Aktivitas',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 18.sp,
          letterSpacing: 0.3,
        ),
      ),
      centerTitle: true,
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
    );
  }

  void _showFilterBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF2FA2F1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String tempCategory = _selectedCategory;
        String tempStatus = _selectedStatus;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final hasActiveFilter =
                tempCategory != 'Semua' || tempStatus != 'Semua';

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 80 : 25),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20.w,
                right: 20.w,
                top: 12.h,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white24
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Aktivitas',
                          style: TextStyle(
                            fontSize: 16.5.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        if (hasActiveFilter)
                          GestureDetector(
                            onTap: () {
                              setModalState(() {
                                tempCategory = 'Semua';
                                tempStatus = 'Semua';
                              });
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 4.h,
                              ),
                              child: Text(
                                'Reset',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 18.h),

                    // 1. Kategori Layanan Section
                    Text(
                      'Kategori Layanan',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF475569),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((name) {
                        final isSelected = tempCategory == name;

                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              tempCategory = name;
                            });
                          },
                          borderRadius: BorderRadius.circular(20.r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor
                                  : (isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : (isDark
                                        ? Colors.white10
                                        : const Color(0xFFE2E8F0)),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : const Color(0xFF334155)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 18.h),

                    // 2. Status Transaksi Section
                    Text(
                      'Status Transaksi',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF475569),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _statuses.map((status) {
                        final isSelected = tempStatus == status;

                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              tempStatus = status;
                            });
                          },
                          borderRadius: BorderRadius.circular(20.r),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor
                                  : (isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : (isDark
                                        ? Colors.white10
                                        : const Color(0xFFE2E8F0)),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 12.5.sp,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : const Color(0xFF334155)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 24.h),

                    // 3. Tombol Terapkan Filter
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = tempCategory;
                            _selectedStatus = tempStatus;
                            _displayLimit = 10;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                        child: Text(
                          'Terapkan Filter',
                          style: TextStyle(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final formattedDate = _formatDate(item['date']?.toString());
    final bool isLaporan =
        item['category'] == 'Laporan Warga' ||
        (item['title']?.toString().toLowerCase().contains('lapor') ?? false);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionDetailPage(transaction: item),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon/Image Box (Framed)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(8.0.w),
                    child: item['image'] != null
                        ? (item['image'].toString().startsWith('http')
                              ? Image.network(
                                  item['image'],
                                  errorBuilder: (_, _, _) {
                                    String fb = 'assets/images/F2.png';
                                    final img = item['image'].toString();
                                    if (img.contains('F1')) {
                                      fb = 'assets/images/F1.png';
                                    } else if (img.contains('mobil')) {
                                      fb = 'assets/images/mobil.png';
                                    } else if (img.contains('fasilitas')) {
                                      fb = 'assets/images/fasilitas.png';
                                    } else if (img.contains('lapor')) {
                                      fb = 'assets/images/lapor.png';
                                    }
                                    return Image.asset(
                                      fb,
                                      errorBuilder: (_, _, _) => Icon(
                                        Icons.apps_rounded,
                                        color: primaryColor,
                                        size: 24.sp,
                                      ),
                                    );
                                  },
                                )
                              : Image.asset(
                                  item['image'],
                                  errorBuilder: (_, _, _) => Icon(
                                    Icons.apps_rounded,
                                    color: primaryColor,
                                    size: 24.sp,
                                  ),
                                ))
                        : Icon(
                            Icons.apps_rounded,
                            color: primaryColor,
                            size: 24.sp,
                          ),
                  ),
                ),
                SizedBox(width: 12.w),

                // Main Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              item['title']?.toString() ?? 'Tidak ada judul',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.5.sp,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          _buildStatusBadge(item['status']),
                        ],
                      ),
                      SizedBox(height: 4.h),

                      // Date
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey[500],
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // Price or Detail Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (isLaporan)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                item['price']?.toString() ??
                                    'Prioritas: Normal',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[700],
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else
                            Text(
                              item['price']?.toString() ?? '-',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12.sp,
                            color: isDark ? Colors.white24 : Colors.grey[300],
                          ),
                        ],
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

  Widget _buildEmptyState() {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.0.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 54.sp,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Belum Ada Aktivitas',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.grey[800],
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Riwayat pesanan dan laporan Anda akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey[500],
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestState() {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.0.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 54.sp,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Belum Ada Aktivitas',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.grey[800],
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Silakan login untuk melihat riwayat aktivitas dan transaksi Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey[500],
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                ).then((value) {
                  if (value == true) {
                    checkLoginStatus();
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 32.w,
                  vertical: 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Login Sekarang',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
