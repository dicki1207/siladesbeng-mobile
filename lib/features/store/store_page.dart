// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'cart_page.dart';
import 'pasar_detail_page.dart';
import 'pasar_favorite_page.dart';
import 'package:siladesbeng_mobile/services/pasar_product_service.dart';
import 'package:siladesbeng_mobile/services/pasar_cart_service.dart';
import 'package:siladesbeng_mobile/services/pasar_favorite_service.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final PasarProductService _pasarProductService = PasarProductService();
  final PasarCartService _pasarCartService = PasarCartService();
  final PasarFavoriteService _pasarFavService = PasarFavoriteService();

  String _selectedCategory = 'Semua';
  String _selectedSort = 'latest';
  String _selectedKecamatan = 'Semua Kecamatan';
  String _selectedDesa = 'Semua Desa';
  String _searchQuery = '';
  List<String> _categories = ['Semua'];
  bool _isLoading = true;
  List<Map<String, dynamic>> _apiProducts = [];
  List<int> _favProductIds = [];
  int _cartCount = 0;

  final TextEditingController _searchController = TextEditingController();

  final List<String> _kecamatanList = [
    'Semua Kecamatan',
    'Kec. Bengkalis',
    'Kec. Bantan',
    'Kec. Bukit Batu',
    'Kec. Siak Kecil',
    'Kec. Mandau',
    'Kec. Pinggir',
    'Kec. Rupat',
  ];

  final Map<String, List<String>> _desaPerKecamatan = {
    'Semua Kecamatan': ['Semua Desa'],
    'Kec. Bengkalis': [
      'Semua Desa',
      'Desa Senggoro',
      'Desa Wonosari',
      'Desa Kelapapati',
      'Desa Pedekik',
      'Desa Damon',
      'Desa Meskom',
      'Desa Penampi',
    ],
    'Kec. Bantan': [
      'Semua Desa',
      'Desa Bantan Tua',
      'Desa Selatbaru',
      'Desa Bantan Air',
      'Desa Teluk Pambang',
    ],
    'Kec. Bukit Batu': [
      'Semua Desa',
      'Desa Sungai Pakning',
      'Desa Sejangat',
      'Desa Dompas',
    ],
    'Kec. Siak Kecil': ['Semua Desa', 'Desa Lubuk Muda', 'Desa Sepotong'],
    'Kec. Mandau': ['Semua Desa', 'Duri Barat', 'Duri Timur', 'Gajah Sakti'],
    'Kec. Pinggir': ['Semua Desa', 'Desa Pinggir', 'Desa Balai Pungut'],
    'Kec. Rupat': ['Semua Desa', 'Batu Panjang', 'Tanjung Kapal'],
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchCartCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCartCount() async {
    final count = await _pasarProductService.getCartCount();
    if (mounted) {
      setState(() => _cartCount = count);
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      final categories = await _pasarProductService.getCategories();
      final products = await _pasarProductService.getProducts(
        category: _selectedCategory,
        search: _searchQuery,
        sort: _selectedSort,
      );

      // Client-side region filter
      List<Map<String, dynamic>> filtered = products;
      if (_selectedDesa != 'Semua Desa') {
        filtered = filtered.where((p) {
          final region = p['region'] is Map
              ? p['region']['name']?.toString() ?? ''
              : '';
          final lokasi = p['lokasi']?.toString() ?? '';
          return region.toLowerCase().contains(_selectedDesa.toLowerCase()) ||
              lokasi.toLowerCase().contains(_selectedDesa.toLowerCase());
        }).toList();
      } else if (_selectedKecamatan != 'Semua Kecamatan') {
        filtered = filtered.where((p) {
          final lokasi = p['lokasi']?.toString() ?? '';
          return lokasi.toLowerCase().contains(
            _selectedKecamatan.toLowerCase(),
          );
        }).toList();
      }

      final favIds = await _pasarFavService.getFavoriteProductIds();

      if (mounted) {
        setState(() {
          if (categories.isNotEmpty) _categories = categories;
          _apiProducts = filtered.isNotEmpty ? filtered : products;
          _favProductIds = favIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Unified Filter specifically for Wilayah & Urutkan Harga
  void _showFilterBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF0EA5E9);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String tempKecamatan = _selectedKecamatan;
        String tempDesa = _selectedDesa;
        String tempSort = _selectedSort;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final List<String> currentDesaList =
                _desaPerKecamatan[tempKecamatan] ?? ['Semua Desa'];

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: primaryColor,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Filter Wilayah & Urutan',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempKecamatan = 'Semua Kecamatan';
                              tempDesa = 'Semua Desa';
                              tempSort = 'latest';
                            });
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),

                    // 1. Wilayah Kecamatan (Antar-Kecamatan)
                    const Text(
                      '1. Wilayah Kecamatan (Kab. Bengkalis)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _kecamatanList.map((kec) {
                        final isSelected = tempKecamatan == kec;
                        return ChoiceChip(
                          label: Text(kec),
                          selected: isSelected,
                          selectedColor: primaryColor.withValues(alpha: 0.18),
                          backgroundColor: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? primaryColor
                                : (isDark ? Colors.white70 : Colors.grey[700]),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 11.5,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? primaryColor
                                : (isDark
                                      ? Colors.white12
                                      : const Color(0xFFCBD5E1)),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                tempKecamatan = kec;
                                tempDesa = 'Semua Desa';
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),

                    if (tempKecamatan != 'Semua Kecamatan') ...[
                      const SizedBox(height: 14),
                      Text(
                        'Desa di $tempKecamatan',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: currentDesaList.map((desa) {
                          final isSelected = tempDesa == desa;
                          return ChoiceChip(
                            label: Text(desa),
                            selected: isSelected,
                            selectedColor: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.18),
                            backgroundColor: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF10B981)
                                  : (isDark
                                        ? Colors.white70
                                        : Colors.grey[700]),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 11.5,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF10B981)
                                  : (isDark
                                        ? Colors.white12
                                        : const Color(0xFFCBD5E1)),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => tempDesa = desa);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // 2. Urutan Harga / Waktu
                    const Text(
                      '2. Urutan Produk',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildSortChip(
                          'Terbaru',
                          'latest',
                          tempSort,
                          (val) => setModalState(() => tempSort = val),
                          isDark,
                          primaryColor,
                        ),
                        _buildSortChip(
                          'Harga Terendah',
                          'price_asc',
                          tempSort,
                          (val) => setModalState(() => tempSort = val),
                          isDark,
                          primaryColor,
                        ),
                        _buildSortChip(
                          'Harga Tertinggi',
                          'price_desc',
                          tempSort,
                          (val) => setModalState(() => tempSort = val),
                          isDark,
                          primaryColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedKecamatan = tempKecamatan;
                            _selectedDesa = tempDesa;
                            _selectedSort = tempSort;
                          });
                          Navigator.pop(context);
                          _fetchData();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Terapkan Wilayah & Urutan',
                          style: TextStyle(
                            fontSize: 14.5,
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

  Widget _buildSortChip(
    String label,
    String value,
    String groupValue,
    ValueChanged<String> onChanged,
    bool isDark,
    Color primaryColor,
  ) {
    final isSelected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: primaryColor.withValues(alpha: 0.18),
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        color: isSelected
            ? primaryColor
            : (isDark ? Colors.white70 : Colors.grey[700]),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 11.5,
      ),
      side: BorderSide(
        color: isSelected
            ? primaryColor
            : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
      ),
      onSelected: (selected) {
        if (selected) onChanged(value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF0EA5E9);

    final hasActiveRegionFilter =
        _selectedKecamatan != 'Semua Kecamatan' ||
        _selectedDesa != 'Semua Desa';
    final hasActiveSortFilter = _selectedSort != 'latest';
    final hasRegionOrSortFilter = hasActiveRegionFilter || hasActiveSortFilter;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF090D16)
          : const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text(
          'Pasar Daerah',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFF0284C7),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Favorit Saya
          IconButton(
            icon: const Icon(
              Icons.favorite_outline_rounded,
              color: Colors.white,
            ),
            tooltip: 'Favorit Saya',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PasarFavoritePage()),
              ).then((_) {
                _fetchData();
                _fetchCartCount();
              });
            },
          ),
          // Cart with Count
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartPage()),
                  );
                  _fetchCartCount();
                },
              ),
              if (_cartCount > 0)
                Positioned(
                  top: 8,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _cartCount > 99 ? '99+' : '$_cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
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
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchData();
          await _fetchCartCount();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Search Bar with Filter Wilayah & Urutan Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari produk BUMDes, sembako, kerajinan...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.grey[500],
                    ),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            color: hasRegionOrSortFilter ? primaryColor : null,
                          ),
                          onPressed: _showFilterBottomSheet,
                          tooltip: 'Filter Wilayah & Urutkan',
                        ),
                        if (hasRegionOrSortFilter)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white10
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.white10
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: primaryColor,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onSubmitted: (value) {
                    setState(() => _searchQuery = value);
                    _fetchData();
                  },
                ),
              ),
            ),

            // 2. Active Filter Badges (Kecamatan / Desa / Urutan)
            if (hasRegionOrSortFilter)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (hasActiveRegionFilter)
                          InputChip(
                            avatar: const Icon(
                              Icons.location_on_rounded,
                              size: 14,
                              color: Color(0xFF0284C7),
                            ),
                            label: Text(
                              _selectedDesa != 'Semua Desa'
                                  ? '$_selectedDesa ($_selectedKecamatan)'
                                  : _selectedKecamatan,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                            backgroundColor: const Color(
                              0xFF0284C7,
                            ).withValues(alpha: 0.12),
                            side: BorderSide(
                              color: const Color(
                                0xFF0284C7,
                              ).withValues(alpha: 0.3),
                            ),
                            onDeleted: () {
                              setState(() {
                                _selectedKecamatan = 'Semua Kecamatan';
                                _selectedDesa = 'Semua Desa';
                              });
                              _fetchData();
                            },
                          ),
                        if (hasActiveSortFilter) ...[
                          const SizedBox(width: 6),
                          InputChip(
                            avatar: const Icon(
                              Icons.sort_rounded,
                              size: 14,
                              color: primaryColor,
                            ),
                            label: Text(
                              _selectedSort == 'price_asc'
                                  ? 'Termurah'
                                  : 'Tertinggi',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            backgroundColor: primaryColor.withValues(
                              alpha: 0.12,
                            ),
                            side: BorderSide(
                              color: primaryColor.withValues(alpha: 0.3),
                            ),
                            onDeleted: () {
                              setState(() => _selectedSort = 'latest');
                              _fetchData();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

            // 3. Quick Category Horizontal Pills (Specifically for Kategori Produk)
            SliverToBoxAdapter(
              child: Container(
                height: 38,
                margin: const EdgeInsets.only(top: 4, bottom: 8),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final isSelected = _selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: primaryColor.withValues(alpha: 0.18),
                      backgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? primaryColor
                            : (isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569)),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? primaryColor
                            : (isDark
                                  ? Colors.white12
                                  : const Color(0xFFE2E8F0)),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat);
                          _fetchData();
                        }
                      },
                    );
                  },
                ),
              ),
            ),

            // 4. Products Grid Immediately at the Top!
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_apiProducts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 70,
                        color: isDark ? Colors.white24 : Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada produk',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Produk di kategori atau wilayah ini belum tersedia.',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey[500],
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.70,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = _apiProducts[index];
                    return _buildProductCard(product, isDark);
                  }, childCount: _apiProducts.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, bool isDark) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final String name = product['nama_produk'] ?? product['name'] ?? '';
    final double price = product['harga'] != null
        ? double.tryParse(product['harga'].toString()) ?? 0
        : (product['price'] != null
              ? double.tryParse(product['price'].toString()) ?? 0
              : 0);
    final String? imageUrl =
        product['image_url'] ??
        (product['images'] is List && product['images'].isNotEmpty
            ? product['images'][0]
            : null);
    final int productId = product['id'] is int
        ? product['id']
        : int.tryParse(product['id']?.toString() ?? '0') ?? 0;
    final String lokasi = product['region'] is Map
        ? product['region']['name']?.toString() ?? ''
        : (product['lokasi']?.toString() ?? 'Bengkalis');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PasarDetailPage(productId: productId),
          ),
        ).then((_) => _fetchCartCount());
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Image + Village Tag + Heart Toggle
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : Colors.grey[200],
                              child: const Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : Colors.grey[200],
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  // Village Tag
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.store_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            lokasi,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Heart Toggle Button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () async {
                        final isNowFav = await _pasarFavService
                            .toggleProductFavorite(productId);
                        if (mounted) {
                          setState(() {
                            if (isNowFav) {
                              _favProductIds.add(productId);
                            } else {
                              _favProductIds.remove(productId);
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isNowFav
                                    ? '❤️ $name ditambahkan ke Favorit'
                                    : '$name dihapus dari Favorit',
                              ),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _favProductIds.contains(productId)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 15,
                          color: _favProductIds.contains(productId)
                              ? Colors.redAccent
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '4.9',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(48)',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(price),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0EA5E9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final success = await _pasarCartService.addToCart(
                          productId,
                          1,
                        );
                        if (mounted && success) {
                          _fetchCartCount();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ditambahkan ke keranjang!'),
                              backgroundColor: Color(0xFF10B981),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 14),
                      label: const Text(
                        '+ Keranjang',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0EA5E9),
                        side: const BorderSide(
                          color: Color(0xFF0EA5E9),
                          width: 1.2,
                        ),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
