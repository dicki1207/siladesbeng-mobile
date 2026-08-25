import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_config.dart';
import '../../widgets/product_card_widget.dart';
import '../rental/item_detail_page.dart';
import 'gas_booking_page.dart';

class GasPage extends StatefulWidget {
  const GasPage({super.key});

  @override
  State<GasPage> createState() => _GasPageState();
}

class _GasPageState extends State<GasPage> {
  List<dynamic> _allGasItems = [];
  List<String> _categories = ['Semua'];
  String _selectedCategory = 'Semua';
  bool _isLoading = true;

  List<dynamic> get _filteredGasItems {
    if (_selectedCategory == 'Semua') {
      return _allGasItems;
    }
    return _allGasItems
        .where(
          (item) =>
              (item['kategori'] ?? 'Lainnya').toString() == _selectedCategory,
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchGas();
  }

  Future<void> _fetchGas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      if (token == null) {
        if (mounted) {
          setState(() {
            _allGasItems = [];
            _categories = ['Semua'];
            _isLoading = false;
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/gas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (!mounted) return;
          setState(() {
            final rawItems = data['data'] as List? ?? [];
            _allGasItems = rawItems.map((item) {
              item['name'] = item['jenis_gas'] ?? item['name'];
              item['price'] = item['harga_satuan'] ?? item['price'];
              item['image'] =
                  item['image_url'] ?? item['image'] ?? 'assets/images/F2.png';
              item['description'] =
                  item['deskripsi'] ?? item['description'] ?? '';
              return item;
            }).toList();

            final uniqueCategories = _allGasItems
                .map((e) => e['kategori']?.toString() ?? '')
                .where((e) => e.isNotEmpty)
                .toSet()
                .toList();
            _categories = ['Semua', ...uniqueCategories];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Gagal mengambil data gas: $e");
    }

    if (!mounted) return;
    setState(() {
      _allGasItems = [];
      _categories = ['Semua'];
      _isLoading = false;
    });
  }

  void _showFilterModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2563EB);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Kategori',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: isDark ? Colors.white60 : Colors.grey[600],
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569)),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: primaryColor,
                    backgroundColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? primaryColor
                            : (isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                        Navigator.pop(ctx);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Layanan Gas LPG',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFF2563EB),
        elevation: 0,
        centerTitle: true,
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
                      : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
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
        actions: [
          if (_categories.length > 1)
            IconButton(
              icon: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _showFilterModal,
            ),
        ],
      ),
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: () async {
          setState(() {
            _isLoading = true;
          });
          await _fetchGas();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 20.0,
              ),
              sliver: _isLoading
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Center(
                          child: CircularProgressIndicator(color: primaryColor),
                        ),
                      ),
                    )
                  : _filteredGasItems.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 70,
                                color: isDark
                                    ? Colors.white24
                                    : Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum Ada Gas',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Saat ini BUMDes belum menyediakan stok gas\ndi kategori ini.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14.0,
                            mainAxisSpacing: 14.0,
                            childAspectRatio: 0.68,
                          ),
                      delegate: SliverChildBuilderDelegate((
                        BuildContext context,
                        int index,
                      ) {
                        return _buildPremiumGasCard(_filteredGasItems[index]);
                      }, childCount: _filteredGasItems.length),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumGasCard(dynamic item) {
    double priceVal = 0;
    if (item['price'] != null) {
      if (item['price'] is String) {
        priceVal = double.tryParse(item['price'].toString()) ?? 0;
      } else if (item['price'] is num) {
        priceVal = (item['price'] as num).toDouble();
      }
    }

    String imageUrl = item['image'] ?? 'assets/images/F2.png';
    bool isAsset =
        imageUrl.startsWith('assets/') || imageUrl.contains('F2.png');
    if (isAsset) imageUrl = 'assets/images/F2.png';

    // Ambil stok dan status
    int stock = 0;
    if (item['stok'] != null) {
      stock = int.tryParse(item['stok'].toString()) ?? 0;
    } else if (item['stock'] != null) {
      stock = int.tryParse(item['stock'].toString()) ?? 0;
    }

    String status = item['status'] ?? (stock > 0 ? 'Tersedia' : 'Habis');
    bool isAvailable = status.toLowerCase() == 'tersedia' || stock > 0;

    return ProductCardWidget(
      title: item['name'] ?? 'Gas LPG',
      category: item['kategori'] ?? 'Subsidi / Non-Subsidi',
      imageUrl: imageUrl,
      isAssetImage: isAsset,
      price: priceVal,
      priceUnit: '/Tabung',
      stockLabel: 'Sisa Stok',
      stockValue: stock.toString(),
      statusText: isAvailable ? 'Tersedia' : 'Habis',
      statusColor: isAvailable ? const Color(0xFF10B981) : Colors.red,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailPage(
              item: item,
              category: 'Beli Gas',
              bookingPage: GasBookingPage(item: item),
            ),
          ),
        );
      },
    );
  }
}
