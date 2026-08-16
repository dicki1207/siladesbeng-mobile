// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:siladesbeng_mobile/services/pasar_product_service.dart';
import 'package:siladesbeng_mobile/services/pasar_cart_service.dart';
import 'cart_page.dart';

class PasarDetailPage extends StatefulWidget {
  final int productId;

  const PasarDetailPage({super.key, required this.productId});

  @override
  State<PasarDetailPage> createState() => _PasarDetailPageState();
}

class _PasarDetailPageState extends State<PasarDetailPage> with SingleTickerProviderStateMixin {
  final PasarProductService _productService = PasarProductService();
  final PasarCartService _cartService = PasarCartService();

  Map<String, dynamic>? _product;
  bool _isLoading = true;
  int _quantity = 1;
  int _currentImageIndex = 0;
  late TabController _tabController;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    final detail = await _productService.getProductDetail(widget.productId);
    if (mounted) {
      setState(() {
        _product = detail;
        _isLoading = false;
      });
    }
  }

  List<String> get _images {
    if (_product == null) return [];
    final images = _product!['images'];
    if (images is List && images.isNotEmpty) {
      return List<String>.from(images);
    }
    final singleImage = _product!['image_url'];
    if (singleImage != null && singleImage.toString().isNotEmpty) {
      return [singleImage.toString()];
    }
    return [];
  }

  double get _price {
    final raw = _product?['harga'] ?? 0;
    if (raw is String) return double.tryParse(raw) ?? 0;
    return (raw as num).toDouble();
  }

  int get _stock => _product?['stok'] ?? 0;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail Produk'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail Produk'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: Text('Produk tidak ditemukan')),
      );
    }

    final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final String name = _product!['nama_produk'] ?? 'Tanpa Nama';
    final String? satuan = _product!['satuan'];
    final String? kategori = _product!['kategori'];
    final String? deskripsi = _product!['deskripsi'];
    final String? lokasi = _product!['lokasi'];
    final Map<String, dynamic>? region = _product!['region'] is Map ? Map<String, dynamic>.from(_product!['region']) : null;
    final String regionName = region?['name'] ?? lokasi ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // SliverAppBar with Image Carousel
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Theme.of(context).cardColor,
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  SharePlus.instance.share(ShareParams(text: 'Lihat produk $name di Pasar Daerah SiladesBeng!'));
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image Carousel
                  if (_images.isNotEmpty)
                    PageView.builder(
                      controller: _pageController,
                      itemCount: _images.length,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return Image.network(
                          _images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.storefront, size: 60, color: Colors.grey[400]),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.storefront, size: 60, color: Colors.grey[400]),
                    ),

                  // Gradient overlay for readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withAlpha(80)],
                        ),
                      ),
                    ),
                  ),

                  // Page Indicator
                  if (_images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_images.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentImageIndex == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index ? Colors.white : Colors.white.withAlpha(120),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),

                  // Badges
                  if (_stock > 0 && _stock <= 5)
                    Positioned(
                      top: 100,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Tersisa $_stock!',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (_stock <= 0)
                    Positioned(
                      top: 100,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Stok Habis',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Product Info
          SliverToBoxAdapter(
            child: Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Harga
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency.format(_price),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0EA5E9),
                        ),
                      ),
                      if (satuan != null && satuan.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 3),
                          child: Text(
                            '/$satuan',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Nama
                  Text(
                    name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // Stok
                  Text(
                    'Stok: $_stock',
                    style: TextStyle(fontSize: 13, color: _stock <= 5 ? Colors.red : Colors.grey[600]),
                  ),

                  // Kategori
                  if (kategori != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withAlpha(15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF0EA5E9).withAlpha(50)),
                        ),
                        child: Text(
                          kategori,
                          style: const TextStyle(color: Color(0xFF0EA5E9), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Seller / Region Card
          if (regionName.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0EA5E9).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.store, color: Color(0xFF0EA5E9)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  regionName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withAlpha(20),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Toko Desa',
                                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 12, color: Colors.grey[400]),
                              const SizedBox(width: 2),
                              Text(
                                'Pengiriman same-day',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
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

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Tab Deskripsi & Info
          SliverToBoxAdapter(
            child: Container(
              color: Theme.of(context).cardColor,
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF0EA5E9),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF0EA5E9),
                    tabs: const [
                      Tab(text: 'Deskripsi'),
                      Tab(text: 'Info Penting'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              color: Theme.of(context).cardColor,
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: _tabController.index == 0
                        ? Text(
                            deskripsi ?? 'Tidak ada deskripsi untuk produk ini.',
                            style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.5),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow(Icons.local_shipping, 'Pengiriman', 'Same-day delivery (satu desa)'),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.verified_user, 'Garansi', 'Barang dijamin sesuai pesanan'),
                              const SizedBox(height: 12),
                              _buildInfoRow(Icons.swap_horiz, 'Pengembalian', 'Hubungi penjual jika ada masalah'),
                            ],
                          ),
                  );
                },
              ),
            ),
          ),

          // Spacer untuk bottom bar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // Sticky Bottom Bar
      bottomNavigationBar: _stock <= 0
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: const SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: null,
                  child: Text('Stok Habis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, -4))],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Qty + Subtotal
                    Row(
                      children: [
                        // Quantity Stepper
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  if (_quantity > 1) setState(() => _quantity--);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(Icons.remove, size: 18, color: _quantity > 1 ? Colors.black : Colors.grey),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  '$_quantity',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  if (_quantity < _stock) {
                                    setState(() => _quantity++);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Melebihi stok tersedia'), backgroundColor: Colors.orange),
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(Icons.add, size: 18, color: _quantity < _stock ? Colors.black : Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Subtotal
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Subtotal', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                            Text(
                              formatCurrency.format(_price * _quantity),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0EA5E9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Action Buttons
                    Row(
                      children: [
                        // Keranjang
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              bool success = await _cartService.addToCart(widget.productId, _quantity);
                              if (mounted) {
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Ditambahkan ke keranjang!'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Gagal menambahkan'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                            label: const Text('Keranjang', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0EA5E9),
                              side: const BorderSide(color: Color(0xFF0EA5E9)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Beli Langsung
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              bool success = await _cartService.addToCart(widget.productId, _quantity);
                              if (mounted && success) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
                              }
                            },
                            icon: const Icon(Icons.flash_on, size: 18, color: Colors.white),
                            label: const Text('Beli Langsung', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0EA5E9),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF0EA5E9)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
