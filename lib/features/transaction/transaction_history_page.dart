import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
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

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
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

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Semua', 'icon': Icons.apps},
    {
      'name': 'Penyewaan',
      'image': 'http://10.250.3.148:8000/User/img/elemen/F1.png',
    },
    {
      'name': 'Pesanan Gas',
      'image': 'http://10.250.3.148:8000/User/img/elemen/F2.png',
    },
    {
      'name': 'Sewa Kendaraan',
      'image': 'http://10.250.3.148:8000/User/img/elemen/mobil.png',
    },
    {
      'name': 'Fasilitas',
      'image': 'http://10.250.3.148:8000/User/img/elemen/fasilitas.png',
    },
    {
      'name': 'Laporan Warga',
      'image': 'http://10.250.3.148:8000/User/img/elemen/lapor.png',
    },
  ];

  final List<String> _statuses = [
    'Semua',
    'Menunggu',
    'Dikonfirmasi',
    'Selesai',
    'Batal',
  ];



  @override
  Widget build(BuildContext context) {
    if (_isLoadingAuth || _isLoadingData) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    List<Map<String, dynamic>> filteredList = _transactions.where((item) {
      bool catMatch =
          _selectedCategory == 'Semua' || item['category'] == _selectedCategory;
      bool statMatch =
          _selectedStatus == 'Semua' || item['status'] == _selectedStatus;
      bool searchMatch = _searchQuery.isEmpty || 
          (item['title']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      return catMatch && statMatch && searchMatch;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          if (_isLoggedIn) {
            await _fetchHistory();
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari nama layanan...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.withAlpha(50)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.withAlpha(50)),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildCategoryDropdown()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatusDropdown()),
                      ],
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
                    horizontal: 16,
                    vertical: 8,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _buildTransactionCard(filteredList[index]);
                    }, childCount: filteredList.length),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: const Color(
        0xFF1E88E5,
      ), // Matching the top color of the gradient
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
      title: const Text(
        'Riwayat Aktivitas',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ),
      centerTitle: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E88E5), // Original Blue
              Color(0xFF4FC3F7), // Light Blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        labelText: 'Kategori',
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withAlpha(50)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withAlpha(50)),
        ),
      ),
      items: _categories.map((cat) {
        return DropdownMenuItem<String>(
          value: cat['name'],
          child: Text(
            cat['name']!,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedCategory = value);
        }
      },
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedStatus,
      isExpanded: true,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        labelText: 'Status',
        filled: true,
        fillColor: Theme.of(context).cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withAlpha(50)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withAlpha(50)),
        ),
      ),
      items: _statuses.map((status) {
        return DropdownMenuItem<String>(
          value: status,
          child: Text(
            status,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedStatus = value);
        }
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> item) {
    Color statusColor;
    final status = item['status']?.toString().toLowerCase() ?? '';
    switch (status) {
      case 'selesai':
        statusColor = Colors.green;
        break;
      case 'dikonfirmasi':
        statusColor = Colors.blue;
        break;
      case 'batal':
        statusColor = Colors.red;
        break;
      case 'menunggu':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionDetailPage(transaction: item),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(15),
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
                                      Icons.apps,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  );
                                },
                              )
                            : Image.asset(
                                item['image'],
                                errorBuilder: (_, _, _) => Icon(
                                  Icons.apps,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ))
                        : Icon(
                            Icons.apps,
                            color: Theme.of(context).primaryColor,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title']?.toString() ?? 'Tidak ada judul',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['date']?.toString() ?? '-',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(150) ?? Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            item['price']?.toString() ?? '-',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withAlpha(50)),
                            ),
                            child: Text(
                              item['status']?.toString() ?? 'Menunggu',
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Belum ada aktivitas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Riwayat pesanan dan laporan Anda akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withAlpha(150) ??
                  Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            Text(
              'Belum ada aktivitas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Silakan login untuk melihat riwayat aktivitas dan transaksi Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withAlpha(150) ??
                    Colors.grey[500],
              ),
            ),
            const SizedBox(height: 30),
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
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
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
