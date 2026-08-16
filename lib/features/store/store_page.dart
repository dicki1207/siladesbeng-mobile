import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'cart_page.dart';
import 'pasar_detail_page.dart';
import 'package:siladesbeng_mobile/services/pasar_product_service.dart';
import 'package:siladesbeng_mobile/services/pasar_cart_service.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  final PasarProductService _pasarProductService = PasarProductService();
  final PasarCartService _pasarCartService = PasarCartService();
  String _selectedCategory = 'Semua';
  String _selectedSort = 'latest';
  String _searchQuery = '';
  List<String> _categories = ['Semua'];
  bool _isLoading = true;
  List<Map<String, dynamic>> _apiProducts = [];
  int _cartCount = 0;

  final TextEditingController _searchController = TextEditingController();

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

      if (mounted) {
        setState(() {
          if (categories.isNotEmpty) _categories = categories;
          _apiProducts = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                  // Header
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

                  // Sorting
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

                  // Kategori
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

                  // Tombol Terapkan
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
    // Chip info untuk filter aktif
    final bool hasActiveFilter =
        _selectedCategory != 'Semua' || _selectedSort != 'latest';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Pasar Daerah',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
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
            // Search Bar + Filter Icon
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.tune,
                        color: hasActiveFilter ? const Color(0xFF0EA5E9) : null,
                      ),
                      onPressed: _showFilterBottomSheet,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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

            // Active Filter Chips
            if (hasActiveFilter)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_selectedCategory != 'Semua')
                        Chip(
                          label: Text(
                            _selectedCategory,
                            style: const TextStyle(fontSize: 12),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() => _selectedCategory = 'Semua');
                            _fetchData();
                          },
                          backgroundColor: const Color(
                            0xFF0EA5E9,
                          ).withAlpha(20),
                          side: const BorderSide(color: Color(0xFF0EA5E9)),
                          labelStyle: const TextStyle(color: Color(0xFF0EA5E9)),
                          deleteIconColor: const Color(0xFF0EA5E9),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (_selectedSort != 'latest')
                        Chip(
                          label: Text(
                            _selectedSort == 'price_asc'
                                ? 'Harga Terendah'
                                : 'Harga Tertinggi',
                            style: const TextStyle(fontSize: 12),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() => _selectedSort = 'latest');
                            _fetchData();
                          },
                          backgroundColor: const Color(
                            0xFF0EA5E9,
                          ).withAlpha(20),
                          side: const BorderSide(color: Color(0xFF0EA5E9)),
                          labelStyle: const TextStyle(color: Color(0xFF0EA5E9)),
                          deleteIconColor: const Color(0xFF0EA5E9),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Products Grid
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
                        'Produk di kategori ini belum tersedia.',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.58,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return _buildProductCard(_apiProducts[index]);
                  }, childCount: _apiProducts.length),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final String name =
        product['nama_produk'] ?? product['name'] ?? 'Tanpa Nama';
    final int stock = product['stok'] ?? product['stock'] ?? 0;
    final String? kategori = product['kategori'] ?? product['category'];
    final String? satuan = product['satuan'];
    final String? regionName = product['region'] != null
        ? product['region']['name']
        : null;
    final String imageUrl = product['image_url'] ?? product['image'] ?? '';

    dynamic rawPrice = product['harga'] ?? product['price'] ?? 0;
    double price = 0;
    if (rawPrice is String) {
      price = double.tryParse(rawPrice) ?? 0;
    } else {
      price = (rawPrice as num).toDouble();
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PasarDetailPage(productId: product['id']),
          ),
        );
        _fetchCartCount();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image + Badge Kategori
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: Icon(
                                      Icons.storefront,
                                      size: 40,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.storefront,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          ),
                  ),
                  // Badge Kategori
                  if (kategori != null && kategori != 'Semua')
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withAlpha(200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          kategori,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Badge Stok Rendah
                  if (stock > 0 && stock <= 5)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Sisa $stock',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  // Badge Habis
                  if (stock <= 0)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(100),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'HABIS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Details
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama produk
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Harga + Satuan
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                formatCurrency.format(price),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0EA5E9),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (satuan != null && satuan.isNotEmpty)
                              Text(
                                ' /$satuan',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    // Lokasi desa
                    if (regionName != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              regionName,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    // Tombol Tambah
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton.icon(
                        onPressed: stock <= 0
                            ? null
                            : () async {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Menambahkan $name...'),
                                  ),
                                );

                                bool success = await _pasarCartService
                                    .addToCart(product['id'], 1);

                                if (mounted) {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).hideCurrentSnackBar();
                                  if (success) {
                                    _fetchCartCount();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '$name ditambahkan ke keranjang',
                                        ),
                                        duration: const Duration(seconds: 1),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Gagal menambahkan ke keranjang',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: const Icon(
                          Icons.add_shopping_cart,
                          size: 14,
                          color: Colors.white,
                        ),
                        label: Text(
                          stock <= 0 ? 'Habis' : 'Tambah',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: stock <= 0
                              ? Colors.grey
                              : const Color(0xFF0EA5E9),
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
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
}
