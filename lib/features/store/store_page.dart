import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'cart_page.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  String _selectedCategory = 'Semua';
  final List<String> _categories = ['Semua', 'Bangunan', 'Listrik', 'Pertanian', 'Pupuk'];

  // Mock Data
  final List<Map<String, dynamic>> _mockProducts = [
    {
      'id': '1',
      'name': 'Semen Padang 50 Kg',
      'category': 'Bangunan',
      'price': 70000,
      'stock': 45,
      'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR6sJ_jZ5UqU9q_0U9r7V_r_8_l_0_1_2_3_4&s',
    },
    {
      'id': '2',
      'name': 'Pipa PVC Wavin 1 Inch',
      'category': 'Bangunan',
      'price': 25000,
      'stock': 120,
      'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ_x_x_x_x_x_x_x_x_x_x_x_x_x_x_x_x_x&s',
    },
    {
      'id': '3',
      'name': 'Kabel Broco NYM 2x1.5',
      'category': 'Listrik',
      'price': 350000,
      'stock': 12,
      'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ_x_x_x_x_x_x_x_x_x_x_x_x_x_x_x_x_x&s',
    },
    {
      'id': '4',
      'name': 'Cangkul Baja',
      'category': 'Pertanian',
      'price': 85000,
      'stock': 30,
      'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ_x_x_x_x_x_x_x_x_x_x_x_x_x_x_x_x_x&s',
    },
    {
      'id': '5',
      'name': 'Pupuk Urea 50 Kg',
      'category': 'Pupuk',
      'price': 120000,
      'stock': 50,
      'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ_x_x_x_x_x_x_x_x_x_x_x_x_x_x_x_x_x&s',
    },
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedCategory == 'Semua') return _mockProducts;
    return _mockProducts.where((p) => p['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Toko BUMDes',
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
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.65,
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
              child: const Icon(Icons.handyman, size: 50, color: Colors.grey),
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
                        product['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stok: ${product['stock']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCurrency.format(product['price']),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0EA5E9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product['name']} ditambahkan ke keranjang'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
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
