import 'package:siladesbeng_mobile/core/api_config.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:siladesbeng_mobile/features/rental/rental_booking_page.dart';
import 'package:siladesbeng_mobile/services/rental_service.dart';

class ToolPackageBookingPage extends StatefulWidget {
  const ToolPackageBookingPage({super.key});

  @override
  State<ToolPackageBookingPage> createState() => _ToolPackageBookingPageState();
}

class _ToolPackageBookingPageState extends State<ToolPackageBookingPage>
    with SingleTickerProviderStateMixin {
  late final ShowcaseView _showcaseView;

  // Showcase Tour Keys
  final GlobalKey _keyTabs = GlobalKey();
  final GlobalKey _keyItem = GlobalKey();
  final GlobalKey _keyBottomBar = GlobalKey();

  late TabController _tabController;
  final int _durationDays = 1;
  final RentalService _rentalService = RentalService();

  // State for Tab 1: Paket Admin Desa
  int? _selectedPackageIndex;
  List<Map<String, dynamic>> _adminPackages = [];

  // State for Tab 2: Rangkai Paket Sendiri (Harga Satuan)
  List<Map<String, dynamic>> _customItems = [];
  bool _isLoading = true;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  int _parseInt(dynamic val, [int defaultValue = 0]) {
    if (val == null) return defaultValue;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is num) return val.toInt();
    if (val is String) {
      return int.tryParse(val) ??
          (double.tryParse(val)?.toInt() ?? defaultValue);
    }
    return defaultValue;
  }

  @override
  void initState() {
    super.initState();
    _showcaseView = ShowcaseView.register();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _fetchItems();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartShowcase();
    });
  }

  Future<void> _checkAndStartShowcase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenTour = prefs.getBool('has_seen_tool_rental_tour') ?? false;
      if (!hasSeenTour && mounted) {
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          _showcaseView.startShowCase([
            _keyTabs,
            _keyItem,
            _keyBottomBar,
          ]);
          await prefs.setBool('has_seen_tool_rental_tour', true);
        }
      }
    } catch (e) {
      debugPrint('Tool rental showcase error: $e');
    }
  }

  void _replayRentalTour() {
    _showcaseView.startShowCase([
      _keyTabs,
      _keyItem,
      _keyBottomBar,
    ]);
  }

  @override
  void dispose() {
    _showcaseView.unregister();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchItems() async {
    try {
      final items = await _rentalService.getRentalItems();
      if (mounted) {
        setState(() {
          _adminPackages = items
              .where(
                (item) => item['unit'] == 'Paket' || item['unit'] == 'paket',
              )
              .map((item) {
                final int itemPrice = _parseInt(
                  item['price'] ?? item['harga'] ?? item['harga_satuan'],
                );
                return {
                  'id': _parseInt(item['id']),
                  'name': item['name'] ?? item['nama'] ?? 'Paket Alat',
                  'items':
                      item['description'] ??
                      item['deskripsi'] ??
                      'Perlengkapan alat terpadu dari BUMDes',
                  'price': itemPrice,
                  'description':
                      item['description'] ??
                      item['deskripsi'] ??
                      'Penyewaan perlengkapan berkualitas, kokoh, dan terawat dari BUMDes.',
                  'image': item['image'] ?? item['foto'],
                  'details':
                      (item['description'] != null &&
                          item['description'].toString().isNotEmpty)
                      ? [item['description'].toString()]
                      : [
                          'Peralatan lengkap dan siap pakai',
                          'Layanan pengantaran tersedia',
                        ],
                };
              })
              .toList();

          _customItems = items
              .where(
                (item) => item['unit'] != 'Paket' && item['unit'] != 'paket',
              )
              .map((item) {
                final int itemPrice = _parseInt(
                  item['price'] ?? item['harga'] ?? item['harga_satuan'],
                );
                return {
                  'id': _parseInt(item['id']),
                  'name': item['name'] ?? item['nama'] ?? 'Alat',
                  'price': itemPrice,
                  'qty': 1,
                  'unit': item['unit'] ?? 'unit',
                  'selected': false,
                  'image': item['image'] ?? item['foto'],
                  'icon': Icons.handyman_outlined,
                  'description': item['description'] ?? item['deskripsi'] ?? '',
                };
              })
              .toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDetailModal(
    BuildContext context,
    Map<String, dynamic> item, {
    int? adminIndex,
    int? customIndex,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final int itemPrice = _parseInt(item['price']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          top: 16,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child:
                          (item['image'] != null &&
                              item['image'].toString().isNotEmpty)
                          ? Image.network(
                              item['image'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    adminIndex != null
                                        ? Icons.inventory_2_outlined
                                        : Icons.handyman_outlined,
                                    color: primaryColor,
                                    size: 26,
                                  ),
                            )
                          : Icon(
                              adminIndex != null
                                  ? Icons.inventory_2_outlined
                                  : Icons.handyman_outlined,
                              color: primaryColor,
                              size: 26,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] ?? 'Detail Paket',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_currencyFormat.format(itemPrice)} / Hari',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
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
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item['description'] ??
                    'Penyewaan perlengkapan berkualitas, kokoh, dan terawat dari BUMDes.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.grey[700],
                  height: 1.5,
                ),
              ),
              if (item['details'] != null &&
                  (item['details'] as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Fasilitas & Kelengkapan:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                ...((item['details'] as List<dynamic>?) ?? [])
                    .map((e) => e.toString())
                    .map(
                      (detail) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: primaryColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                detail,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
              const SizedBox(height: 24),
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
                        if (_parseInt(_customItems[customIndex]['qty']) == 0) {
                          _customItems[customIndex]['qty'] = 1;
                        }
                      });
                      _handleBooking();
                    }
                  },
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text(
                    'Pilih & Sewa Paket Ini',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateCustomDailyPrice() {
    int total = 0;
    for (var item in _customItems) {
      if (item['selected'] == true) {
        total += _parseInt(item['price']) * _parseInt(item['qty'], 1);
      }
    }
    return total;
  }

  int _getTotalPrice() {
    if (_tabController.index == 0) {
      if (_selectedPackageIndex == null ||
          _adminPackages.isEmpty ||
          _selectedPackageIndex! >= _adminPackages.length) {
        return 0;
      }
      return _parseInt(_adminPackages[_selectedPackageIndex!]['price']) *
          _durationDays;
    } else {
      return _calculateCustomDailyPrice() * _durationDays;
    }
  }

  String _getSummaryTitle() {
    if (_tabController.index == 0 &&
        _selectedPackageIndex != null &&
        _selectedPackageIndex! < _adminPackages.length) {
      return _adminPackages[_selectedPackageIndex!]['name'];
    } else {
      List<String> items = [];
      for (var item in _customItems) {
        if (item['selected'] == true && _parseInt(item['qty']) > 0) {
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
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final String packageName = _tabController.index == 0
        ? _getSummaryTitle()
        : 'Paket Custom Bebas';

    final String itemsDesc =
        _tabController.index == 0 &&
            _selectedPackageIndex != null &&
            _selectedPackageIndex! < _adminPackages.length
        ? _adminPackages[_selectedPackageIndex!]['items']
        : _getSummaryTitle();

    final int pricePerDay = _tabController.index == 0
        ? (_selectedPackageIndex != null &&
                  _selectedPackageIndex! < _adminPackages.length
              ? _parseInt(_adminPackages[_selectedPackageIndex!]['price'])
              : 0)
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
            'image': '${ApiConfig.baseUrl}/assets/img/package_placeholder.png',
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
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Penyewaan Alat',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: const Color(0xFF2563EB),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'Panduan Sewa',
            onPressed: _replayRentalTour,
          ),
        ],
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFF2FA2F1), const Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipRRect(
            child: Stack(
              children: [
                Positioned(
                  top: -30,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(22),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -15,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Showcase(
            key: _keyTabs,
            title: 'Pilihan Mode Sewa',
            description: 'Pilih "Paket Alat Desa" untuk paket lengkap hemat, atau "Buat Paket Sendiri" untuk memilih alat satuan sesuai kebutuhan.',
            targetBorderRadius: BorderRadius.circular(25),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              indicator: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: isDark ? Colors.white : primaryColor,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.85),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
              tabs: const [
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_rounded, size: 15),
                        SizedBox(width: 5),
                        Text('Paket Alat Desa'),
                      ],
                    ),
                  ),
                ),
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.handyman_rounded, size: 15),
                        SizedBox(width: 5),
                        Text('Buat Paket Sendiri'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
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
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
      );
    }
    if (_adminPackages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'Belum ada paket alat tersedia.',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _adminPackages.length,
      itemBuilder: (context, idx) {
        final item = _adminPackages[idx];
        final isSelected = _selectedPackageIndex == idx;
        final int itemPrice = _parseInt(item['price']);

        final cardWidget = GestureDetector(
          onTap: () {
            setState(() => _selectedPackageIndex = idx);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.08)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? primaryColor
                    : (isDark
                          ? Colors.white10
                          : Colors.grey.withValues(alpha: 0.15)),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
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
                        item['name']?.toString() ?? 'Paket Alat',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Paket Resmi',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item['items']?.toString() ?? '',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey[600],
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tarif Sewa',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_currencyFormat.format(itemPrice)} / Hari',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? primaryColor : Colors.grey[400],
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showDetailModal(context, item, adminIndex: idx),
                        icon: const Icon(Icons.info_outline_rounded, size: 16),
                        label: const Text(
                          'Lihat Detail',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _selectedPackageIndex = idx);
                          _handleBooking();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Langsung Sewa',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
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

        if (idx == 0) {
          return Showcase(
            key: _keyItem,
            title: 'Pilih Paket Sewa',
            description: 'Ketuk pada kartu paket untuk memilih paket perlengkapan yang ingin disewa.',
            targetBorderRadius: BorderRadius.circular(16),
            child: cardWidget,
          );
        }

        return cardWidget;
      },
    );
  }

  Widget _buildCustomPackageTab() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
      );
    }
    if (_customItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handyman_outlined, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'Tidak ada alat satuan tersedia saat ini.',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryColor.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pilih alat yang Anda butuhkan dan sesuaikan jumlahnya untuk membuat paket sendiri.',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF334155),
                        fontSize: 12,
                        height: 1.35,
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
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, idx) => _buildCustomItemCard(idx),
              childCount: _customItems.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildCustomItemCard(int idx) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final item = _customItems[idx];
    final bool isSelected = item['selected'] == true;
    final int qty = _parseInt(item['qty'], 1);
    final int price = _parseInt(item['price']);

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
              ? primaryColor.withValues(alpha: 0.08)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark
                      ? Colors.white10
                      : Colors.grey.withValues(alpha: 0.15)),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Thumbnail Box
            Expanded(
              flex: 50,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child:
                          (item['image'] != null &&
                              item['image'].toString().isNotEmpty)
                          ? Image.network(
                              item['image'].toString(),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.handyman_outlined,
                                size: 36,
                                color: Colors.grey[400],
                              ),
                            )
                          : Icon(
                              Icons.handyman_outlined,
                              size: 36,
                              color: Colors.grey[400],
                            ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor
                            : Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSelected ? Icons.check_rounded : Icons.add_rounded,
                        size: 14,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Info Box
            Expanded(
              flex: 50,
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
                          item['name']?.toString() ?? 'Alat',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_currencyFormat.format(price)} / Hari',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    // Quantity Control
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            if (qty > 1) {
                              setState(
                                () => _customItems[idx]['qty'] = qty - 1,
                              );
                            } else if (qty == 1) {
                              setState(() {
                                _customItems[idx]['selected'] = false;
                                _customItems[idx]['qty'] = 0;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.remove, size: 14),
                          ),
                        ),
                        Text(
                          '$qty',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _customItems[idx]['selected'] = true;
                              _customItems[idx]['qty'] = qty + 1;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
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
    final primaryColor = Theme.of(context).primaryColor;
    final int total = _getTotalPrice();

    return Showcase(
      key: _keyBottomBar,
      title: 'Total & Lanjutkan Pemesanan',
      description: 'Periksa estimasi biaya sewa harian dan ketuk tombol "Lanjutkan Sewa" untuk melengkapi formulir jadwal dan pengantaran.',
      targetBorderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 15,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row: Total Price & Checkout Button
              Row(
                children: [
                  Expanded(
                    flex: 48,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Biaya (per hari)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white38 : Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _currencyFormat.format(total),
                            style: TextStyle(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w900,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 52,
                    child: ElevatedButton.icon(
                      onPressed: _handleBooking,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text(
                        'Lanjutkan Sewa',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
