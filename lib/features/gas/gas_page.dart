import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'gas_booking_page.dart';
import '../rental/item_detail_page.dart';
import '../../widgets/product_card_widget.dart';

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
      final token = prefs.getString('auth_token');

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
        Uri.parse('http://10.250.3.148:8000/api/gas'),
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Kategori',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0EA5E9),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF0EA5E9)
                            : Colors.grey[300]!,
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Layanan Gas LPG',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_categories.length > 1)
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: _showFilterModal,
            ),
        ],
      ),
      body: RefreshIndicator(
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
                vertical: 24.0,
              ),
              sliver: _isLoading
                  ? const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 50),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0EA5E9),
                          ),
                        ),
                      ),
                    )
                  : _filteredGasItems.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum Ada Gas',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Saat ini BUMDes belum menyediakan stok gas\ndi kategori ini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16.0,
                            mainAxisSpacing: 16.0,
                            childAspectRatio: 0.7,
                          ),
                      delegate: SliverChildBuilderDelegate((
                        BuildContext context,
                        int index,
                      ) {
                        return _buildPremiumGasCard(_filteredGasItems[index]);
                      }, childCount: _filteredGasItems.length),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
    bool isAsset = imageUrl.startsWith('assets/') || imageUrl.contains('F2.png');
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
