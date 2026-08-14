import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
        Uri.parse('http://10.250.3.148:8000/api/history'),
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
      if (rawDate.contains('T') || (rawDate.contains('-') && rawDate.length <= 19)) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 10.5,
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
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    List<Map<String, dynamic>> allFilteredList = _transactions.where((item) {
      bool catMatch =
          _selectedCategory == 'Semua' || item['category'] == _selectedCategory;
      bool statMatch =
          _selectedStatus == 'Semua' || item['status'] == _selectedStatus;
      bool searchMatch = _searchQuery.isEmpty ||
          (item['title']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return catMatch && statMatch && searchMatch;
    }).toList();

    List<Map<String, dynamic>> filteredList =
        allFilteredList.take(_displayLimit).toList();

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
                              borderRadius: BorderRadius.circular(16),
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
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Cari nama layanan...',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey[400],
                                  fontSize: 13.5,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: primaryColor,
                                  size: 22,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 18,
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
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
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
                        const SizedBox(width: 10),
                        // 1 Dedicated Filter Button
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _showFilterBottomSheet,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: hasActiveFilter
                                    ? primaryColor
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: hasActiveFilter
                                      ? primaryColor
                                      : (isDark
                                          ? Colors.white12
                                          : Colors.grey.withValues(alpha: 0.15)),
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
                                    size: 22,
                                  ),
                                  if (hasActiveFilter)
                                    Positioned(
                                      top: 10,
                                      right: 10,
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
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
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
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
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
                                      size: 14,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
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
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final primaryColor = Theme.of(context).primaryColor;
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: primaryColor,
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
      title: const Text(
        'Riwayat Aktivitas',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 18,
          letterSpacing: 0.3,
        ),
      ),
      centerTitle: true,
    );
  }

  void _showFilterBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String tempCategory = _selectedCategory;
        String tempStatus = _selectedStatus;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Aktivitas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (tempCategory != 'Semua' || tempStatus != 'Semua')
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempCategory = 'Semua';
                              tempStatus = 'Semua';
                            });
                          },
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kategori Layanan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((name) {
                      final isSelected = tempCategory == name;
                      return ChoiceChip(
                        label: Text(name),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              tempCategory = name;
                            });
                          }
                        },
                        selectedColor: primaryColor,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey[100],
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? primaryColor
                                : (isDark
                                    ? Colors.white12
                                    : Colors.grey.withValues(alpha: 0.2)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Status Transaksi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statuses.map((status) {
                      final isSelected = tempStatus == status;
                      return ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              tempStatus = status;
                            });
                          }
                        },
                        selectedColor: primaryColor,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey[100],
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? primaryColor
                                : (isDark
                                    ? Colors.white12
                                    : Colors.grey.withValues(alpha: 0.2)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Terapkan Filter',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
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
    final bool isLaporan = item['category'] == 'Laporan Warga' ||
        (item['title']?.toString().toLowerCase().contains('lapor') ?? false);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionDetailPage(transaction: item),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon/Image Box (Framed)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
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
                                      size: 24,
                                    ),
                                  );
                                },
                              )
                            : Image.asset(
                                item['image'],
                                errorBuilder: (_, _, _) => Icon(
                                  Icons.apps_rounded,
                                  color: primaryColor,
                                  size: 24,
                                ),
                              ))
                        : Icon(
                            Icons.apps_rounded,
                            color: primaryColor,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

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
                                fontSize: 14.5,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(item['status']),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Date
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey[500],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Price or Detail Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (isLaporan)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item['price']?.toString() ?? 'Prioritas: Normal',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[700],
                                  fontSize: 11,
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
                                fontSize: 14,
                              ),
                            ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
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
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 54,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Aktivitas',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Riwayat pesanan dan laporan Anda akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey[500],
                fontSize: 13,
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
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 54,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Aktivitas',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.grey[800],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Silakan login untuk melihat riwayat aktivitas dan transaksi Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey[500],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
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
