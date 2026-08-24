// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pasar_detail_page.dart';
import 'toko_chat_page.dart';
import 'cart_page.dart';
import 'give_review_dialog.dart';
import 'report_store_dialog.dart';
import 'package:siladesbeng_mobile/services/pasar_cart_service.dart';
import 'package:siladesbeng_mobile/services/pasar_product_service.dart';
import 'package:siladesbeng_mobile/services/pasar_favorite_service.dart';

class BumdesStoreProfilePage extends StatefulWidget {
  final String tokoName;
  final String desaName;
  final String kecamatanName;
  final String? address;
  final String? phone;
  final String? avatarUrl;
  final List<Map<String, dynamic>>? initialProducts;

  const BumdesStoreProfilePage({
    super.key,
    required this.tokoName,
    required this.desaName,
    required this.kecamatanName,
    this.address,
    this.phone,
    this.avatarUrl,
    this.initialProducts,
  });

  @override
  State<BumdesStoreProfilePage> createState() => _BumdesStoreProfilePageState();
}

class _BumdesStoreProfilePageState extends State<BumdesStoreProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PasarProductService _productService = PasarProductService();
  final PasarCartService _cartService = PasarCartService();
  final PasarFavoriteService _favService = PasarFavoriteService();

  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  bool _isStoreFavorite = false;
  int _cartCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStoreData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    setState(() => _isLoading = true);

    try {
      final cartCount = await _productService.getCartCount();
      final allProducts = await _productService.getProducts();

      // Filter produk milik BUMDes ini atau gunakan dummy list terkurasi
      List<Map<String, dynamic>> storeProds = [];
      if (widget.initialProducts != null &&
          widget.initialProducts!.isNotEmpty) {
        storeProds = widget.initialProducts!;
      } else {
        storeProds = allProducts.where((p) {
          final region = p['region'] is Map
              ? p['region']['name']?.toString() ?? ''
              : '';
          final lokasi = p['lokasi']?.toString() ?? '';
          return region.toLowerCase().contains(widget.desaName.toLowerCase()) ||
              lokasi.toLowerCase().contains(widget.desaName.toLowerCase()) ||
              lokasi.toLowerCase().contains(widget.kecamatanName.toLowerCase());
        }).toList();

        // Fallback jika tidak ada filter match spesifik, tampilkan produk teratas
        if (storeProds.isEmpty && allProducts.isNotEmpty) {
          storeProds = allProducts.take(6).toList();
        }
      }

      final isFav = await _favService.isStoreFavorite(widget.tokoName);

      if (mounted) {
        setState(() {
          _products = storeProds;
          _cartCount = cartCount;
          _isStoreFavorite = isFav;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF0EA5E9);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Sliver App Bar with Gradient & Hero Banner
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              backgroundColor: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              actions: [
                // Cart Icon with Badge
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartPage()),
                        ).then((_) => _loadStoreData());
                      },
                    ),
                    if (_cartCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$_cartCount',
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
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Tautan profil ${widget.tokoName} disalin!',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (value) {
                    if (value == 'report') {
                      ReportStoreDialog.show(
                        context,
                        targetName: widget.tokoName,
                        desaName: widget.desaName,
                        isProduct: false,
                      );
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Laporkan Toko BUMDes',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient Background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF0F172A),
                                  const Color(0xFF1E3A8A),
                                ]
                              : [
                                  const Color(0xFF0284C7),
                                  const Color(0xFF0369A1),
                                  const Color(0xFF1E3A8A),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    // Ambient Pattern Circle
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    // Store Profile Info Container
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 20,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Avatar
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.storefront_rounded,
                                size: 36,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Name, Location, Badges
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade400,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.verified_rounded,
                                            size: 11,
                                            color: Color(0xFF78350F),
                                          ),
                                          SizedBox(width: 3),
                                          Text(
                                            'BUMDes Resmi',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF78350F),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '🟢 Buka',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.tokoName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.desaName} • ${widget.kecamatanName}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Store Metric Bar & Action Buttons
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.25 : 0.04,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Metrics Row
                    Row(
                      children: [
                        _buildMetricItem(
                          icon: Icons.star_rounded,
                          iconColor: Colors.amber,
                          title: '4.9 / 5.0',
                          subtitle: 'Rating Toko',
                          isDark: isDark,
                        ),
                        _buildMetricDivider(isDark),
                        _buildMetricItem(
                          icon: Icons.inventory_2_rounded,
                          iconColor: primaryColor,
                          title: '${_products.length} Item',
                          subtitle: 'Produk BUMDes',
                          isDark: isDark,
                        ),
                        _buildMetricDivider(isDark),
                        _buildMetricItem(
                          icon: Icons.local_shipping_rounded,
                          iconColor: const Color(0xFF10B981),
                          title: 'Antar-Desa',
                          subtitle: 'Layanan Kirim',
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Action Buttons Row (Chat & Call)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TokoChatPage(
                                    tokoName: widget.tokoName,
                                    tokoDesa: widget.desaName,
                                    tokoKecamatan: widget.kecamatanName,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.chat_bubble_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Chat Toko BUMDes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Favorite Store Button
                        OutlinedButton(
                          onPressed: () async {
                            final isNow = await _favService.toggleStoreFavorite(
                              widget.tokoName,
                            );
                            if (mounted) {
                              setState(() => _isStoreFavorite = isNow);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isNow
                                        ? '❤️ ${widget.tokoName} disimpan ke Toko Favorit'
                                        : '${widget.tokoName} dihapus dari Toko Favorit',
                                  ),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _isStoreFavorite
                                ? Colors.redAccent
                                : (isDark
                                      ? Colors.white70
                                      : const Color(0xFF334155)),
                            side: BorderSide(
                              color: _isStoreFavorite
                                  ? Colors.redAccent.withValues(alpha: 0.5)
                                  : (isDark
                                        ? Colors.white24
                                        : const Color(0xFFCBD5E1)),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Icon(
                            _isStoreFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                            color: _isStoreFavorite ? Colors.redAccent : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () {
                            _showStoreInfoBottomSheet(context, isDark);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? Colors.white70
                                : const Color(0xFF334155),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : const Color(0xFFCBD5E1),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Tab Bar
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: primaryColor,
                  unselectedLabelColor: isDark
                      ? Colors.white54
                      : Colors.grey[600],
                  indicatorColor: primaryColor,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(text: 'Katalog Produk'),
                    Tab(text: '⭐ Ulasan (4.9)'),
                    Tab(text: 'Tentang & Kirim'),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: Katalog Produk BUMDes
            _buildProductsTab(isDark, primaryColor, currencyFormat),
            // TAB 2: Ulasan Warga (Rating & Reviews)
            _buildReviewsTab(isDark, primaryColor),
            // TAB 3: Tentang BUMDes & Info Pengiriman Antar-Desa
            _buildAboutTab(isDark, primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDivider(bool isDark) {
    return Container(
      width: 1,
      height: 28,
      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildProductsTab(
    bool isDark,
    Color primaryColor,
    NumberFormat currencyFormat,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.store_mall_directory_outlined,
                size: 60,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 14),
              const Text(
                'Belum Ada Produk',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'BUMDes ini sedang menyiapkan stok produk baru.',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
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

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PasarDetailPage(productId: productId),
              ),
            ).then((_) => _loadStoreData());
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
                // Product Image
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
                                    Icons.shopping_bag,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.shopping_bag,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.desaName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Product Info
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
                      // Quick Add Button
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final success = await _cartService.addToCart(
                              productId,
                              1,
                            );
                            if (mounted && success) {
                              _loadStoreData();
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
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor, width: 1.2),
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
      },
    );
  }

  Widget _buildReviewsTab(bool isDark, Color primaryColor) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
      children: [
        // 1. Rating Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(18),
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
            children: [
              Row(
                children: [
                  // Overall Big Score
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        '4.9',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFF59E0B),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          5,
                          (index) => const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF59E0B),
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '48 Ulasan Warga',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),
                  // Progress Bars
                  Expanded(
                    child: Column(
                      children: [
                        _buildRatingBar(5, 0.88, '88%', isDark),
                        _buildRatingBar(4, 0.10, '10%', isDark),
                        _buildRatingBar(3, 0.02, '2%', isDark),
                        _buildRatingBar(2, 0.00, '0%', isDark),
                        _buildRatingBar(1, 0.00, '0%', isDark),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Write Review Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    GiveReviewDialog.show(
                      context,
                      productName: 'Toko ${widget.tokoName}',
                      tokoName: widget.tokoName,
                      desaName: widget.desaName,
                    );
                  },
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Beri Penilaian & Ulasan BUMDes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. Section Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ulasan Pembeli Terverifikasi',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_rounded, size: 12, color: Colors.green),
                  SizedBox(width: 3),
                  Text(
                    '100% Asli',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 3. Review Cards
        _buildCustomerReviewCard(
          name: 'Pak Hendra Saputra',
          desaOrigin: 'Warga Desa Wonosari',
          rating: 5,
          timeAgo: '2 hari lalu',
          tags: ['🚚 Pengiriman Cepat', '🥬 Kualitas Segar'],
          comment:
              'Pesan cabai rawit dan sayur segar dari BUMDes Senggoro diantar cepat banget sampai ke Wonosari. Barangnya segar dan harganya lebih murah dari pasar biasa.',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildCustomerReviewCard(
          name: 'Ibu Rina Marlina',
          desaOrigin: 'Warga Desa Bantan Tua',
          rating: 5,
          timeAgo: '4 hari lalu',
          tags: ['📦 Kemasan Rapi', '💬 Admin BUMDes Ramah'],
          comment:
              'Admin BUMDes sangat ramah di chat, kurir lokalnya sopan. Kemasan olahan lempuk duriannya rapi dan rasanya autentik khas Bengkalis.',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildCustomerReviewCard(
          name: 'Ahmad Zulkarnain',
          desaOrigin: 'Warga Desa Damon',
          rating: 5,
          timeAgo: '1 minggu lalu',
          tags: ['💰 Harga Pas', '🌟 Produk Asli Desa'],
          comment:
              'Sangat terbantu ada BUMDes digital antar-desa ini. Belanja sembako dan kebutuhan pangan jadi lebih praktis tanpa harus keluar rumah.',
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildCustomerReviewCard(
          name: 'Syarifah Aisyah',
          desaOrigin: 'Warga Desa Meskom',
          rating: 4,
          timeAgo: '2 minggu lalu',
          tags: ['🚚 Pengiriman Cepat'],
          comment:
              'Kualitas produk bagus, proses pengiriman antar-desa lancar. Semoga terus ditambah variasi produk lokal lainnya!',
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildRatingBar(int star, double percent, String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$star',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.grey[700],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                color: const Color(0xFFF59E0B),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 26,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerReviewCard({
    required String name,
    required String desaOrigin,
    required int rating,
    required String timeAgo,
    required List<String> tags,
    required String comment,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(
                  0xFF0EA5E9,
                ).withValues(alpha: 0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0EA5E9),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$desaOrigin • $timeAgo',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? Colors.white54 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            comment,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab(bool isDark, Color primaryColor) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
      children: [
        // BUMDes Overview Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_rounded, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Badan Usaha Milik Desa (BUMDes)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${widget.tokoName} merupakan unit usaha resmi milik Pemerintah ${widget.desaName}, ${widget.kecamatanName}. Menghadirkan produk unggulan lokal, komoditas pangan desa, dan kerajinan UMKM warga dengan jaminan mutu dan transparansi harga.',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Cross-Village Delivery Policy
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.route_rounded, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Jangkauan Pengiriman Antar-Desa',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildDeliveryPoint(
                title: 'Satu Desa (${widget.desaName})',
                desc:
                    'Same-day delivery (Gratis / Rp 5.000 via kurir lokal desa).',
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildDeliveryPoint(
                title: 'Antar-Desa Satu Kecamatan (${widget.kecamatanName})',
                desc:
                    'Pengiriman 1 hari kerja ke seluruh desa tetangga dalam kecamatan.',
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _buildDeliveryPoint(
                title: 'Antar-Kecamatan Se-Kabupaten Bengkalis',
                desc:
                    'Melayani pesanan lintas kecamatan dengan ekspedisi kemitraan BUMDes.',
                isDark: isDark,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Operational & Contact
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Jam Operasional & Alamat',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '🕒 Setiap Hari: 08:00 - 17:00 WIB',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '📍 Kantor BUMDes ${widget.desaName}, ${widget.address ?? 'Jalan Utama Desa, ${widget.kecamatanName}'}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryPoint({
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 16,
          color: Color(0xFF10B981),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showStoreInfoBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.tokoName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.desaName}, ${widget.kecamatanName}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(
                Icons.badge_rounded,
                color: Color(0xFF0EA5E9),
              ),
              title: const Text(
                'Status Legalitas',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'Terdaftar di Kemendesa PDTT',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(
                Icons.phone_rounded,
                color: Color(0xFF10B981),
              ),
              title: const Text('Kontak Resmi', style: TextStyle(fontSize: 13)),
              subtitle: Text(
                widget.phone ?? '+62 812-3456-7890',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
