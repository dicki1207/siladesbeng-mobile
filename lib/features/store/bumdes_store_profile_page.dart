// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pasar_detail_page.dart';
import 'toko_chat_page.dart';
import 'cart_page.dart';

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
 final String? bannerUrl;
 final String? description;
 final int? regionId;
 final List<Map<String, dynamic>>? initialProducts;

 const BumdesStoreProfilePage({
  super.key,
  required this.tokoName,
  required this.desaName,
  required this.kecamatanName,
  this.address,
  this.phone,
  this.avatarUrl,
  this.bannerUrl,
  this.description,
  this.regionId,
  this.initialProducts,
 });

 @override
 State<BumdesStoreProfilePage> createState() => _BumdesStoreProfilePageState();
}

class _BumdesStoreProfilePageState extends State<BumdesStoreProfilePage> {
 final PasarProductService _productService = PasarProductService();
 final PasarCartService _cartService = PasarCartService();
 final PasarFavoriteService _favService = PasarFavoriteService();

 List<Map<String, dynamic>> _products = [];
 bool _isLoading = true;
 bool _isStoreFavorite = false;
 int _cartCount = 0;

 String? _avatarUrl;
 String? _bannerUrl;
 String? _description;



 @override
 void initState() {
  super.initState();
  _avatarUrl = widget.avatarUrl;
  _bannerUrl = widget.bannerUrl;
  _description = widget.description;
  _loadStoreData();
 }

 Future<void> _loadStoreData() async {
  setState(() => _isLoading = true);

  try {
   if (widget.regionId != null) {
    final sellerProfile = await _productService.getSellerProfile(widget.regionId!);
    if (sellerProfile != null && mounted) {
     setState(() {
      if (sellerProfile['avatar'] != null) _avatarUrl = sellerProfile['avatar'];
      if (sellerProfile['store_banner'] != null) _bannerUrl = sellerProfile['store_banner'];
      if (sellerProfile['store_description'] != null) _description = sellerProfile['store_description'];
     });
    }
   }

   final cartCount = await _productService.getCartCount();
   final allProducts = await _productService.getProducts();

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



  return Scaffold(
   backgroundColor: Theme.of(context).scaffoldBackgroundColor,
   body: CustomScrollView(
    slivers: [
     // 1. Sliver App Bar with Gradient & Hero Banner
     SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFF2FA2F1),
      foregroundColor: Colors.white,
      actions: [
       // Cart with Badge
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
         Container(
          decoration: BoxDecoration(
           gradient: LinearGradient(
            colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFF2FA2F1), const Color(0xFF0284C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
           ),
          ),
         ),
         if (_bannerUrl != null && _bannerUrl!.isNotEmpty) ...[
          Positioned.fill(
           child: Image.network(
            _bannerUrl!,
            fit: BoxFit.cover,
            errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
           ),
          ),
          Positioned.fill(
           child: Container(
            decoration: BoxDecoration(
             gradient: LinearGradient(
              colors: [
               Colors.black.withValues(alpha: 0.65),
               Colors.black.withValues(alpha: 0.25),
               Colors.black.withValues(alpha: 0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
             ),
            ),
           ),
          ),
         ],
         // Glowing circle 1 (Top Right)
         Positioned(
          right: -25,
          top: -25,
          child: Container(
           width: 130,
           height: 130,
           decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(22),
           ),
          ),
         ),
         // Glowing circle 2 (Bottom Left)
         Positioned(
          left: -20,
          bottom: -20,
          child: Container(
           width: 80,
           height: 80,
           decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withAlpha(14),
           ),
          ),
         ),
         Positioned(
          left: 20,
          right: 20,
          bottom: 16,
          child: Row(
           crossAxisAlignment: CrossAxisAlignment.end,
           children: [
            // Avatar
            Container(
             width: 60,
             height: 60,
             decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
               BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
               ),
              ],
             ),
             child: ClipOval(
              child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                ? Image.network(
                  _avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const Center(
                   child: Icon(
                    Icons.storefront_rounded,
                    size: 32,
                    color: Color(0xFF0284C7),
                   ),
                  ),
                 )
                : Image.network(
                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.desaName)}&background=0284C7&color=fff&size=128',
                  fit: BoxFit.cover,
                 ),
             ),
            ),
            const SizedBox(width: 12),
            Expanded(
             child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
               Row(
                children: [
                 Container(
                  padding: const EdgeInsets.symmetric(
                   horizontal: 6,
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
                    alpha: 0.25,
                   ),
                   borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                   ' Buka',
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
                 fontSize: 16,
                 fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
               ),
               Text(
                '${widget.desaName} • ${widget.kecamatanName}',
                style: TextStyle(
                 color: Colors.white.withValues(alpha: 0.85),
                 fontSize: 11.5,
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

     // 2. Section ATAS: Tentang BUMDes & Informasi Toko (Sesuai Permintaan User!)
     SliverToBoxAdapter(
      child: Container(
       margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
       padding: const EdgeInsets.all(14),
       decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
         color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
         BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
          blurRadius: 8,
          offset: const Offset(0, 3),
         ),
        ],
       ),
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
         const SizedBox(height: 12),
         // Action Buttons Row (Chat & Favorit)
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
                 tokoAvatar: _avatarUrl,
                ),
               ),
              );
             },
             icon: const Icon(
              Icons.chat_bubble_rounded,
              size: 16,
              color: Colors.white,
             ),
             label: const Text(
              'Chat Toko BUMDes',
              style: TextStyle(
               fontWeight: FontWeight.bold,
               fontSize: 12.5,
              ),
             ),
             style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(10),
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
                   ? ' ${widget.tokoName} disimpan ke Toko Favorit'
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
              vertical: 10,
             ),
             shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
             ),
            ),
            child: Icon(
             _isStoreFavorite
               ? Icons.favorite_rounded
               : Icons.favorite_border_rounded,
             size: 18,
             color: _isStoreFavorite ? Colors.redAccent : null,
            ),
           ),
          ],
         ),
         const SizedBox(height: 12),
         const Divider(height: 1),
         const SizedBox(height: 10),
         // Tentang Toko Penjelasan Rinci
         Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: primaryColor,
           ),
           const SizedBox(width: 6),
           Expanded(
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              Text(
               'Tentang ${widget.tokoName}:',
               style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark
                  ? Colors.white
                  : const Color(0xFF0F172A),
               ),
              ),
              const SizedBox(height: 2),
              Text(
               _description != null && _description!.isNotEmpty
                 ? _description!
                 : 'Unit usaha ekonomi desa resmi ${widget.desaName}, ${widget.kecamatanName}. Menyediakan produk pangan lokal, sembako, dan hasil tani berkualitas dengan pengiriman kurir lokal antar-desa se-Kabupaten Bengkalis.',
               style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: isDark
                  ? Colors.white70
                  : Colors.grey[700],
               ),
              ),
             ],
            ),
           ),
          ],
         ),
         const SizedBox(height: 8),
         Container(
          padding: const EdgeInsets.symmetric(
           horizontal: 10,
           vertical: 6,
          ),
          decoration: BoxDecoration(
           color: isDark
             ? const Color(0xFF0F172A)
             : const Color(0xFFF1F5F9),
           borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
           children: [
            const Icon(
             Icons.access_time_rounded,
             size: 13,
             color: Colors.grey,
            ),
            const SizedBox(width: 5),
            Text(
             'Jam Buka: 08:00 - 17:00 WIB',
             style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white60 : Colors.grey[700],
             ),
            ),
            const Spacer(),
            const Icon(
             Icons.verified_user_rounded,
             size: 13,
             color: Color(0xFF10B981),
            ),
            const SizedBox(width: 4),
            const Text(
             'Legal Kemendesa',
             style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF10B981),
             ),
            ),
           ],
          ),
         ),
        ],
       ),
      ),
     ),

     // 3. Section TENGAH: Katalog Produk BUMDes (Grid Produk)
     SliverToBoxAdapter(
      child: Padding(
       padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
       child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
         Row(
          children: [
           const Icon(
            Icons.shopping_bag_outlined,
            size: 18,
            color: primaryColor,
           ),
           const SizedBox(width: 6),
           Text(
            'Katalog Produk BUMDes',
            style: TextStyle(
             fontSize: 15,
             fontWeight: FontWeight.bold,
             color: isDark
               ? Colors.white
               : const Color(0xFF0F172A),
            ),
           ),
          ],
         ),
         Text(
          '${_products.length} Produk',
          style: TextStyle(
           fontSize: 12,
           fontWeight: FontWeight.w600,
           color: isDark ? Colors.white54 : Colors.grey[600],
          ),
         ),
        ],
       ),
      ),
     ),

     if (_isLoading)
      const SliverToBoxAdapter(
       child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
       ),
      )
     else if (_products.isEmpty)
      SliverToBoxAdapter(
       child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
         child: Column(
          children: [
           Icon(
            Icons.inventory_2_outlined,
            size: 50,
            color: isDark ? Colors.white24 : Colors.grey[300],
           ),
           const SizedBox(height: 8),
           Text(
            'Belum ada produk di toko ini',
            style: TextStyle(
             color: isDark ? Colors.white54 : Colors.grey[600],
             fontSize: 12.5,
            ),
           ),
          ],
         ),
        ),
       ),
      )
     else
      SliverPadding(
       padding: const EdgeInsets.symmetric(horizontal: 16),
       sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
         crossAxisCount: 2,
         childAspectRatio: 0.70,
         crossAxisSpacing: 12,
         mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
         final product = _products[index];
         return _buildProductCard(product, isDark, primaryColor);
        }, childCount: _products.length),
       ),
      ),

     const SliverToBoxAdapter(child: SizedBox(height: 20)),
     // Review Section Removed


     const SliverToBoxAdapter(child: SizedBox(height: 40)),
    ],
   ),
  );
 }


 Widget _buildProductCard(
  Map<String, dynamic> product,
  bool isDark,
  Color primaryColor,
 ) {
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
     borderRadius: BorderRadius.circular(14),
     border: Border.all(
      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
     ),
     boxShadow: [
      BoxShadow(
       color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
       blurRadius: 6,
       offset: const Offset(0, 2),
      ),
     ],
    ),
    child: Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      // Thumbnail Image
      Expanded(
       child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
         top: Radius.circular(14),
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
      ),
      // Product Info
      Padding(
       padding: const EdgeInsets.all(8),
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
         const SizedBox(height: 2),
         Text(
          currencyFormat.format(price),
          style: TextStyle(
           fontSize: 13,
           fontWeight: FontWeight.w900,
           color: primaryColor,
          ),
         ),
         const SizedBox(height: 6),
         SizedBox(
          width: double.infinity,
          height: 28,
          child: OutlinedButton(
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
           style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: BorderSide(color: primaryColor, width: 1.2),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(6),
            ),
           ),
           child: const Text(
            '+ Keranjang',
            style: TextStyle(
             fontSize: 10.5,
             fontWeight: FontWeight.bold,
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
       Icon(icon, size: 14, color: iconColor),
       const SizedBox(width: 4),
       Text(
        title,
        style: const TextStyle(
         fontSize: 12.5,
         fontWeight: FontWeight.bold,
        ),
       ),
      ],
     ),
     const SizedBox(height: 2),
     Text(
      subtitle,
      style: TextStyle(
       fontSize: 10,
       color: isDark ? Colors.white54 : Colors.grey[600],
      ),
     ),
    ],
   ),
  );
 }

 Widget _buildMetricDivider(bool isDark) {
  return Container(
   width: 1,
   height: 24,
   color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
  );
 }
}
