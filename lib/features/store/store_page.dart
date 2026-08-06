import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'cart_page.dart';
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
  List<String> _categories = ['Semua', 'Bangunan', 'Listrik', 'Pertanian', 'Pupuk'];
  bool _isLoading = true;
  List<Map<String, dynamic>> _apiProducts = [];



  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    try {
      final categories = await _pasarProductService.getCategories();
      final products = await _pasarProductService.getProducts(category: _selectedCategory);
      
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

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedCategory == 'Semua') return _apiProducts;
    
    return _apiProducts.where((p) {
      final cat = p['kategori'] ?? p['category'];
      return cat == _selectedCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Pasar Daerah',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Banner or Search can go here
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Cari barang bangunan, listrik...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF0EA5E9),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? const Color(0xFF0EA5E9) : Colors.grey[300]!,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                          _fetchData();
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Products Grid
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredProducts.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('Belum ada produk di kategori ini')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.55,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildProductCard(_filteredProducts[index]);
                  },
                  childCount: _filteredProducts.length,
                ),
              ),
            ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    String name = product['nama_produk'] ?? product['name'] ?? 'Tanpa Nama';
    int stock = product['stok'] ?? product['stock'] ?? 0;
    
    dynamic rawPrice = product['harga'] ?? product['price'] ?? 0;
    double price = 0;
    if (rawPrice is String) {
      price = double.tryParse(rawPrice) ?? 0;
    } else {
      price = (rawPrice as num).toDouble();
    }
    
    String imageUrl = product['image_url'] ?? product['image'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.handyman, size: 50, color: Colors.grey),
                      ),
                    )
                  : const Icon(Icons.handyman, size: 50, color: Colors.grey),
            ),
          ),
          // Details
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Text(
                        'Stok: $stock',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCurrency.format(price),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0EA5E9),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (stock <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Stok habis!')),
                          );
                          return;
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Menambahkan $name...')),
                        );
                        
                        bool success = await _pasarCartService.addToCart(product['id'], 1);
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$name ditambahkan ke keranjang'),
                                duration: const Duration(seconds: 1),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal menambahkan ke keranjang'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.add_shopping_cart, size: 16, color: Colors.white),
                      label: const Text('Tambah', style: TextStyle(color: Colors.white, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
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
    );
  }
}
