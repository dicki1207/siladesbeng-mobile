import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'cart_page.dart';
import 'pasar_detail_page.dart';
import 'bumdes_store_profile_page.dart';
import 'toko_chat_page.dart';
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

  // Curated BUMDes Stores list for Cross-Village/District Discovery
  final List<Map<String, dynamic>> _featuredStores = [
    {
      'tokoName': 'BUMDes Senggoro Maju',
      'desaName': 'Desa Senggoro',
      'kecamatanName': 'Kec. Bengkalis',
      'rating': 4.9,
      'productCount': 12,
      'address': 'Jl. Bantan No. 12, Senggoro',
      'phone': '+62 812-7654-3210',
      'badge': 'Unggulan',
      'color': Color(0xFF0284C7),
    },
    {
      'tokoName': 'BUMDes Wonosari Berkah',
      'desaName': 'Desa Wonosari',
      'kecamatanName': 'Kec. Bengkalis',
      'rating': 4.8,
      'productCount': 9,
      'address': 'Jl. Wonosari Tengah, Bengkalis',
      'phone': '+62 813-8899-1122',
      'badge': 'Pangan',
      'color': Color(0xFF10B981),
    },
    {
      'tokoName': 'BUMDes Meskom Sejahtera',
      'desaName': 'Desa Meskom',
      'kecamatanName': 'Kec. Bengkalis',
      'rating': 4.9,
      'productCount': 15,
      'address': 'Jl. Utama Meskom, Bengkalis',
      'phone': '+62 822-4455-6677',
      'badge': 'Kerajinan',
      'color': Color(0xFFF59E0B),
    },
    {
      'tokoName': 'BUMDes Selatbaru Bahari',
      'desaName': 'Desa Selatbaru',
      'kecamatanName': 'Kec. Bantan',
      'rating': 4.7,
      'productCount': 8,
      'address': 'Kawasan Pantai Selatbaru, Bantan',
      'phone': '+62 852-1122-3344',
      'badge': 'Hasil Laut',
      'color': Color(0xFF8B5CF6),
    },
    {
      'tokoName': 'BUMDes Pakning Gemilang',
      'desaName': 'Desa Sungai Pakning',
      'kecamatanName': 'Kec. Bukit Batu',
      'rating': 4.8,
      'productCount': 11,
      'address': 'Jl. Jenderal Sudirman, Sungai Pakning',
      'phone': '+62 812-9988-7766',
      'badge': 'Komoditas',
      'color': Color(0xFFEC4899),
    },
  ];

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

      // Client-side region filter jika dipilih spesifik
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

  void _showRegionFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String tempKecamatan = _selectedKecamatan;
        String tempDesa = _selectedDesa;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final List<String> currentDesaList =
                _desaPerKecamatan[tempKecamatan] ?? ['Semua Desa'];

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF0EA5E9),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Pilih Wilayah BUMDes',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kecamatan (Antar-Kecamatan)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
                        selectedColor: const Color(0xFF0EA5E9).withAlpha(40),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF0EA5E9)
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF0EA5E9)
                              : Colors.grey.shade300,
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
                  const SizedBox(height: 16),
                  const Text(
                    'Desa (Antar-Desa)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: currentDesaList.map((desa) {
                      final isSelected = tempDesa == desa;
                      return ChoiceChip(
                        label: Text(desa),
                        selected: isSelected,
                        selectedColor: const Color(0xFF10B981).withAlpha(40),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : Colors.grey.shade300,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => tempDesa = desa);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedKecamatan = tempKecamatan;
                          _selectedDesa = tempDesa;
                        });
                        Navigator.pop(context);
                        _fetchData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Terapkan Wilayah',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String tempCategory = _selectedCategory;
        String tempSort = _selectedSort;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter & Urutkan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Urutkan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSortChip('Terbaru', 'latest', tempSort, (val) {
                        setModalState(() => tempSort = val);
                      }),
                      _buildSortChip('Harga Terendah', 'price_asc', tempSort, (
                        val,
                      ) {
                        setModalState(() => tempSort = val);
                      }),
                      _buildSortChip(
                        'Harga Tertinggi',
                        'price_desc',
                        tempSort,
                        (val) {
                          setModalState(() => tempSort = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Kategori',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = tempCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => tempCategory = cat);
                          }
                        },
                        selectedColor: const Color(0xFF0EA5E9).withAlpha(40),
                        backgroundColor: Theme.of(context).cardColor,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF0EA5E9)
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF0EA5E9)
                              : Colors.grey.shade300,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedCategory = tempCategory;
                          _selectedSort = tempSort;
                        });
                        Navigator.pop(context);
                        _fetchData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Terapkan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
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
    String current,
    Function(String) onSelected,
  ) {
    final isSelected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) onSelected(value);
      },
      selectedColor: const Color(0xFF0EA5E9).withAlpha(40),
      backgroundColor: Theme.of(context).cardColor,
      labelStyle: TextStyle(
        color: isSelected
            ? const Color(0xFF0EA5E9)
            : Theme.of(context).textTheme.bodyMedium?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF0EA5E9) : Colors.grey.shade300,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF0EA5E9);
    final bool hasActiveFilter =
        _selectedCategory != 'Semua' ||
        _selectedSort != 'latest' ||
        _selectedKecamatan != 'Semua Kecamatan' ||
        _selectedDesa != 'Semua Desa';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Pasar Daerah BUMDes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFF0284C7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          // Chat Toko Shortcut
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Layanan Chat BUMDes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TokoChatPage(
                    tokoName: 'BUMDes Senggoro Maju',
                    tokoDesa: 'Desa Senggoro',
                    tokoKecamatan: 'Kec. Bengkalis',
                  ),
                ),
              );
            },
          ),
          // Favorit Saya Shortcut
          IconButton(
            icon: const Icon(Icons.favorite_outline_rounded),
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
                icon: const Icon(Icons.shopping_cart_outlined),
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
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _cartCount > 99 ? '99+' : '$_cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchData();
          await _fetchCartCount();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Region Selector Pill Bar
            SliverToBoxAdapter(
              child: GestureDetector(
                onTap: _showRegionFilterBottomSheet,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lokasi Toko BUMDes Antar-Desa:',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF0369A1),
                              ),
                            ),
                            Text(
                              '$_selectedKecamatan • $_selectedDesa',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Ganti',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: Color(0xFF0284C7),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Search Bar + Filter Icon
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari produk BUMDes, sembako, kerajinan...',
                    hintStyle: const TextStyle(fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.tune_rounded,
                        color: hasActiveFilter ? const Color(0xFF0EA5E9) : null,
                      ),
                      onPressed: _showFilterBottomSheet,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onSubmitted: (value) {
                    setState(() => _searchQuery = value);
                    _fetchData();
                  },
                ),
              ),
            ),

            // 3. Featured BUMDes Stores (Cross-Village Showcase)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.storefront_rounded,
                              size: 18,
                              color: Color(0xFF0EA5E9),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Toko BUMDes Antar-Desa',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_featuredStores.length} Desa',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 135,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _featuredStores.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final store = _featuredStores[i];
                        return _buildStoreCard(store, isDark);
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 4. Quick Category Filter Pills
            SliverToBoxAdapter(
              child: Container(
                height: 38,
                margin: const EdgeInsets.only(top: 14, bottom: 6),
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
                      selectedColor: primaryColor.withAlpha(40),
                      backgroundColor: Theme.of(context).cardColor,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? primaryColor
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: isSelected ? primaryColor : Colors.grey.shade300,
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

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // 5. Products Grid
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
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada produk',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Produk di kategori atau wilayah ini belum tersedia.',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
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

  Widget _buildStoreCard(Map<String, dynamic> store, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BumdesStoreProfilePage(
              tokoName: store['tokoName'],
              desaName: store['desaName'],
              kecamatanName: store['kecamatanName'],
              address: store['address'],
              phone: store['phone'],
            ),
          ),
        ).then((_) => _fetchCartCount());
      },
      child: Container(
        width: 175,
        padding: const EdgeInsets.all(12),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (store['color'] as Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: store['color'],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: (store['color'] as Color).withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          store['badge'] ?? 'BUMDes',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: store['color'],
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 13,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${store['rating']}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store['tokoName'],
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${store['desaName']} • ${store['kecamatanName']}',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
        : int.tryParse(product['id'].toString()) ?? 0;
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
            // Thumbnail Image + Village Tag
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
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.grey,
                            ),
                          ),
                  ),
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
