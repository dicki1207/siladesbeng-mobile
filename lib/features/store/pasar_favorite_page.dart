// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siladesbeng_mobile/services/pasar_favorite_service.dart';
import 'package:siladesbeng_mobile/services/pasar_product_service.dart';
import 'package:siladesbeng_mobile/services/pasar_cart_service.dart';
import 'pasar_detail_page.dart';
import 'bumdes_store_profile_page.dart';
import 'toko_chat_page.dart';

class PasarFavoritePage extends StatefulWidget {
  const PasarFavoritePage({super.key});

  @override
  State<PasarFavoritePage> createState() => _PasarFavoritePageState();
}

class _PasarFavoritePageState extends State<PasarFavoritePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PasarFavoriteService _favService = PasarFavoriteService();
  final PasarProductService _productService = PasarProductService();
  final PasarCartService _cartService = PasarCartService();

  List<Map<String, dynamic>> _favoriteProducts = [];
  List<String> _favoriteStores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    try {
      final favIds = await _favService.getFavoriteProductIds();
      final favStores = await _favService.getFavoriteStoreNames();
      final allProducts = await _productService.getProducts();

      final favProds = allProducts.where((p) {
        final id = p['id'] is int
            ? p['id']
            : int.tryParse(p['id']?.toString() ?? '0') ?? 0;
        return favIds.contains(id);
      }).toList();

      if (mounted) {
        setState(() {
          _favoriteProducts = favProds;
          _favoriteStores = favStores;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeProductFavorite(int productId, String productName) async {
    await _favService.toggleProductFavorite(productId);
    setState(() {
      _favoriteProducts.removeWhere((p) {
        final id = p['id'] is int
            ? p['id']
            : int.tryParse(p['id']?.toString() ?? '0') ?? 0;
        return id == productId;
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$productName dihapus dari favorit'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _removeStoreFavorite(String storeName) async {
    await _favService.toggleStoreFavorite(storeName);
    setState(() {
      _favoriteStores.remove(storeName);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$storeName dihapus dari toko favorit'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFF2563EB),
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Favorit Saya',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17.5,
                color: Colors.white,
              ),
            ),
            Text(
              'Daftar produk & BUMDes tersimpan',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
          ),
          tabs: [
            Tab(text: 'Produk (${_favoriteProducts.length})'),
            Tab(text: 'Toko BUMDes (${_favoriteStores.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: Produk Favorit
                _buildProductFavoritesTab(isDark, primaryColor, currencyFormat),
                // TAB 2: Toko BUMDes Favorit
                _buildStoreFavoritesTab(isDark, primaryColor),
              ],
            ),
    );
  }

  Widget _buildProductFavoritesTab(
    bool isDark,
    Color primaryColor,
    NumberFormat currencyFormat,
  ) {
    if (_favoriteProducts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 64,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Belum Ada Produk Favorit',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tekan ikon hati ❤️ pada produk yang kamu sukai agar mudah ditemukan kembali.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.storefront_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  'Jelajahi Pasar Daerah',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _favoriteProducts.length,
        itemBuilder: (context, index) {
          final product = _favoriteProducts[index];
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
              ).then((_) => _loadFavorites());
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
                  // Image + Heart Remove Button
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
                            child: Text(
                              lokasi,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Heart Remove Button
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () =>
                                _removeProductFavorite(productId, name),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                size: 16,
                                color: Colors.redAccent,
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
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        const Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Color(0xFFF59E0B),
                            ),
                            SizedBox(width: 2),
                            Text(
                              '4.9 (48)',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(price),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0EA5E9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 30,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final success = await _cartService.addToCart(
                                productId,
                                1,
                              );
                              if (mounted && success) {
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
                            icon: const Icon(
                              Icons.add_shopping_cart,
                              size: 13,
                              color: Colors.white,
                            ),
                            label: const Text(
                              '+ Keranjang',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
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
      ),
    );
  }

  Widget _buildStoreFavoritesTab(bool isDark, Color primaryColor) {
    if (_favoriteStores.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  size: 64,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Belum Ada Toko BUMDes Favorit',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Simpan toko BUMDes langgananmu agar mudah melihat katalog dan promo desa terbaru.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteStores.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final storeName = _favoriteStores[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BumdesStoreProfilePage(
                        tokoName: storeName,
                        desaName: 'Bengkalis',
                        kecamatanName: 'Kec. Bengkalis',
                      ),
                    ),
                  ).then((_) => _loadFavorites());
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.storefront_rounded,
                    color: primaryColor,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BumdesStoreProfilePage(
                          tokoName: storeName,
                          desaName: 'Bengkalis',
                          kecamatanName: 'Kec. Bengkalis',
                        ),
                      ),
                    ).then((_) => _loadFavorites());
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 12,
                            color: Color(0xFF0284C7),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'BUMDes Resmi • Rating 4.9 ⭐',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: primaryColor,
                  size: 20,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TokoChatPage(
                        tokoName: storeName,
                        tokoDesa: 'Bengkalis',
                        tokoKecamatan: 'Kec. Bengkalis',
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () => _removeStoreFavorite(storeName),
              ),
            ],
          ),
        );
      },
    );
  }
}
