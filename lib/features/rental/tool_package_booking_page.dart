import 'package:flutter/material.dart';

import 'package:siladesbeng_mobile/features/rental/rental_booking_page.dart';
import 'package:siladesbeng_mobile/services/rental_service.dart';

class ToolPackageBookingPage extends StatefulWidget {
  const ToolPackageBookingPage({super.key});

  @override
  State<ToolPackageBookingPage> createState() => _ToolPackageBookingPageState();
}

class _ToolPackageBookingPageState extends State<ToolPackageBookingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _durationDays = 1;
  final RentalService _rentalService = RentalService();

  // State for Tab 1: Paket Admin Desa
  int? _selectedPackageIndex;
  List<Map<String, dynamic>> _adminPackages = [];

  // State for Tab 2: Rangkai Paket Sendiri (Harga Satuan)
  List<Map<String, dynamic>> _customItems = [];
  bool _isLoading = true;

  void _showDetailModal(
    BuildContext context,
    Map<String, dynamic> item, {
    int? adminIndex,
    int? customIndex,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? Theme.of(ctx).cardColor : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.blue.withAlpha(40) : Colors.blue[50],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      adminIndex != null ? Icons.stars : Icons.handyman,
                      color: isDark ? Colors.blue[400] : Colors.blue[800],
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          adminIndex != null
                              ? 'Rp ${item['discountedPrice']} /hari (HEMAT ${item['hemat']})'
                              : 'Rp ${item['price']} /hari',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.blue[400] : Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Deskripsi Layanan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item['description'] ??
                    'Penyewaan perlengkapan berkualitas, kokoh, dan terawat dari BUMDes.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                  height: 1.5,
                ),
              ),
              if (item['details'] != null &&
                  (item['details'] as List).isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Rincian & Fasilitas Paket:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                ...((item['details'] as List<dynamic>?) ?? [])
                    .map((e) => e.toString())
                    .map(
                  (detail) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: isDark ? Colors.blue[400] : Colors.blue[600],
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            detail,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[300] : Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (adminIndex != null) {
                      setState(() {
                        _tabController.index = 0;
                        _selectedPackageIndex = adminIndex;
                      });
                      _handleBooking();
                    } else if (customIndex != null) {
                      setState(() {
                        _tabController.index = 1;
                        _customItems[customIndex]['selected'] = true;
                        if (_customItems[customIndex]['qty'] == 0) {
                          _customItems[customIndex]['qty'] = 1;
                        }
                      });
                      _handleBooking();
                    }
                  },
                  icon: const Icon(Icons.bolt, size: 20),
                  label: const Text(
                    'Langsung Sewa Sekarang / Checkout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.blue[600] : Colors.blue[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    final items = await _rentalService.getRentalItems();
    if (mounted) {
      setState(() {
        _adminPackages = items.where((item) => item['unit'] == 'Paket' || item['unit'] == 'paket').map((item) {
          return {
            'id': item['id'],
            'name': item['name'] ?? 'Paket',
            'items': item['description'] ?? '',
            'originalPrice': (item['price'] ?? 0) + 50000, // Example markup for visual
            'discountedPrice': item['price'] ?? 0,
            'hemat': 'Spesial',
            'color': Colors.blue,
            'description': item['description'] ?? '',
            'image': item['image'],
            'details': [item['description'] ?? ''],
          };
        }).toList();

        _customItems = items.where((item) => item['unit'] != 'Paket' && item['unit'] != 'paket').map((item) {
          return {
            'id': item['id'],
            'name': item['name'] ?? 'Alat',
            'price': item['price'] ?? 0,
            'qty': 1,
            'unit': item['unit'] ?? 'unit',
            'selected': false,
            'image': item['image'],
            'icon': Icons.build,
            'description': item['description'] ?? '',
          };
        }).toList();
        
        _isLoading = false;
      });
    }
  }


  int _calculateCustomDailyPrice() {
    int total = 0;
    for (var item in _customItems) {
      if (item['selected'] == true) {
        total += (item['price'] as int) * (item['qty'] as int);
      }
    }
    return total;
  }

  int _getTotalPrice() {
    if (_tabController.index == 0) {
      if (_selectedPackageIndex == null) return 0;
      return _adminPackages[_selectedPackageIndex!]['discountedPrice'] *
          _durationDays;
    } else {
      return _calculateCustomDailyPrice() * _durationDays;
    }
  }

  String _getSummaryTitle() {
    if (_tabController.index == 0 && _selectedPackageIndex != null) {
      return _adminPackages[_selectedPackageIndex!]['name'];
    } else {
      List<String> items = [];
      for (var item in _customItems) {
        if (item['selected'] == true && (item['qty'] as int) > 0) {
          items.add('${item['qty']} ${item['unit']} (${item['name']})');
        }
      }
      return items.isEmpty
          ? 'Belum Pilih Alat'
          : 'Paket Custom: ${items.join(', ')}';
    }
  }

  Future<void> _handleBooking() async {
    final int total = _getTotalPrice();
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih paket atau item alat terlebih dahulu!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final String packageName = _tabController.index == 0
        ? _getSummaryTitle()
        : 'Paket Custom Bebas';
    
    final String itemsDesc = _tabController.index == 0 && _selectedPackageIndex != null
        ? _adminPackages[_selectedPackageIndex!]['items']
        : _getSummaryTitle();

    final int pricePerDay = _tabController.index == 0
        ? (_selectedPackageIndex != null ? _adminPackages[_selectedPackageIndex!]['discountedPrice'] : 0)
        : _calculateCustomDailyPrice();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RentalBookingPage(
          item: {
            'id': 0,
            'name': packageName,
            'price': pricePerDay,
            'type': 'paket',
            'description': itemsDesc,
            'image': 'http://10.250.3.148:8000/assets/img/package_placeholder.png', // Or handle appropriately
          },
          category: 'Paket Sewa Alat',
          initialDuration: _durationDays,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Penyewaan & Peminjaman Alat',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: isDark ? const Color(0xFF10192A) : Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(icon: Icon(Icons.stars), text: 'Paket Hemat Desa'),
            Tab(icon: Icon(Icons.handyman), text: 'Buat Paket Sendiri'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics:
                  const NeverScrollableScrollPhysics(), // handle manual switches
              children: [_buildAdminPackagesTab(), _buildCustomPackageTab()],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildAdminPackagesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_adminPackages.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada paket tersedia saat ini.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? Colors.blue.withAlpha(40) : Colors.blue[50],
            border: Border.all(color: isDark ? Colors.blue[700]! : Colors.blue[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: isDark ? Colors.blue[300] : Colors.blue[800]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Paket peminjaman yang sudah ditetapkan Admin Desa jauh lebih murah dibanding harga satuan!',
                  style: TextStyle(color: isDark ? Colors.blue[100] : Colors.blue[900], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._adminPackages.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isSelected = _selectedPackageIndex == idx;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedPackageIndex = idx);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? Colors.blue[900]!.withAlpha(80) : Colors.blue[50])
                    : (isDark ? Theme.of(context).cardColor : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? Colors.blue[400]! : Colors.blue[800]!)
                      : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: item['color'] as Color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'HEMAT ${item['hemat']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['items'],
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 14),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rp ${item['originalPrice']} /hari',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Rp ${item['discountedPrice']} /hari',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.blue[400] : Colors.blue[800],
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? (isDark ? Colors.blue[400] : Colors.blue[800]) : Colors.grey,
                        size: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showDetailModal(context, item, adminIndex: idx),
                          icon: const Icon(Icons.info_outline, size: 17),
                          label: const Text(
                            'Lihat Detail',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.blue[400] : Colors.blue[800],
                            side: BorderSide(color: isDark ? Colors.blue[400]! : Colors.blue[800]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _selectedPackageIndex = idx);
                            _handleBooking();
                          },
                          icon: const Icon(Icons.bolt, size: 17),
                          label: const Text(
                            'Langsung Sewa',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.blue[600] : Colors.blue[800],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCustomPackageTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_customItems.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada alat/satuan tersedia saat ini.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.blue.withAlpha(40) : Colors.blue[50],
                border: Border.all(color: isDark ? Colors.blue[700]! : Colors.blue[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.checklist_rtl_rounded,
                    color: isDark ? Colors.blue[300] : Colors.blue[800],
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Centang kotak pada foto untuk memilih alat yang dibutuhkan, lalu sesuaikan jumlahnya!',
                      style: TextStyle(
                        color: isDark ? Colors.blue[200] : Colors.blue[900],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.52,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, idx) => _buildCustomItemCard(idx),
              childCount: _customItems.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildCustomItemCard(int idx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final item = _customItems[idx];
    final bool isSelected = item['selected'] == true;
    final int qty = item['qty'] as int;
    final int price = item['price'] as int;

    return GestureDetector(
      onTap: () {
        setState(() {
          _customItems[idx]['selected'] = !isSelected;
          if (_customItems[idx]['selected'] == true && qty == 0) {
            _customItems[idx]['qty'] = 1;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.blue[900]!.withAlpha(80) : Colors.blue[50]!.withAlpha(120))
              : (isDark ? Theme.of(context).cardColor : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.blue[400]! : Colors.blue[800]!)
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
            width: isSelected ? 2.2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.blue.withAlpha(25)
                  : Colors.black.withAlpha(10),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: Container(
                    height: 105,
                    width: double.infinity,
                    color: isDark ? Colors.grey[850] : Colors.grey[100],
                    child: item['image'] != null
                        ? Image.network(
                            item['image'] as String,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(
                              color: isSelected
                                  ? (isDark ? Colors.blue[900] : Colors.blue[100])
                                  : (isDark ? Colors.grey[800] : Colors.grey[200]),
                              child: Icon(
                                item['icon'] as IconData? ?? Icons.handyman,
                                size: 45,
                                color: isSelected
                                    ? (isDark ? Colors.blue[300] : Colors.blue[800])
                                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                              ),
                            ),
                          )
                        : Container(
                            color: isSelected
                                ? (isDark ? Colors.blue[900] : Colors.blue[100])
                                : (isDark ? Colors.grey[800] : Colors.grey[200]),
                            child: Icon(
                              item['icon'] as IconData? ?? Icons.handyman,
                              size: 45,
                              color: isSelected
                                  ? (isDark ? Colors.blue[300] : Colors.blue[800])
                                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? Colors.blue[600] : Colors.blue[800])
                          : (isDark ? Colors.grey[800]!.withAlpha(220) : Colors.white.withAlpha(220)),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(35),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Icon(
                        isSelected ? Icons.check : Icons.add,
                        size: 16,
                        color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.grey[800]),
                      ),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'DIPILIH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isSelected
                                ? (isDark ? Colors.blue[200] : Colors.blue[900])
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Rp $price /hari',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: isSelected
                                ? (isDark ? Colors.blue[400] : Colors.blue[800])
                                : (isDark ? Colors.grey[400] : Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.blue[500]! : Colors.blue[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (qty > 1) {
                                    _customItems[idx]['qty'] = qty - 1;
                                  } else {
                                    _customItems[idx]['selected'] = false;
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.remove_circle_outline,
                                  size: 18,
                                  color: Colors.red[600],
                                ),
                              ),
                            ),
                            Text(
                              '$qty',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _customItems[idx]['qty'] = qty + 1;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.add_circle_outline,
                                  size: 18,
                                  color: isDark ? Colors.blue[400] : Colors.blue[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        ),
                        child: Center(
                          child: Text(
                            '+ Pilih & Atur Jumlah',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[300] : Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    Center(
                      child: InkWell(
                        onTap: () =>
                            _showDetailModal(context, item, customIndex: idx),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Lihat Detail',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.blue[400] : Colors.blue[700],
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
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

  Widget _buildBottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int total = _getTotalPrice();
    final String summary = _getSummaryTitle();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).cardColor : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _tabController.index == 0
                      ? 'Pilihan: $summary'
                      : 'Rincian: $summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Lama: ', style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: () {
                      if (_durationDays > 1) setState(() => _durationDays--);
                    },
                    child: const Icon(
                      Icons.remove_circle,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$_durationDays Hari',
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _durationDays++),
                    child: Icon(
                      Icons.add_circle,
                      size: 20,
                      color: isDark ? Colors.blue[400] : Colors.blue[800],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    total == 0 ? 'Rp 0' : 'Rp $total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: isDark ? Colors.blue[300] : Colors.blue[900],
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _handleBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.blue[600] : Colors.blue[800],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 8,
                  shadowColor: Colors.blue.withAlpha(100),
                ),
                child: const Text(
                  'Pesan Paket',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
