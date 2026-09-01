// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:siladesbeng_mobile/services/pasar_product_service.dart';
import 'package:siladesbeng_mobile/services/pasar_cart_service.dart';
import 'cart_page.dart';
import 'bumdes_store_profile_page.dart';
import 'toko_chat_page.dart';
import 'give_review_dialog.dart';
import 'return_refund_dialog.dart';
import 'report_store_dialog.dart';
import 'package:siladesbeng_mobile/services/pasar_favorite_service.dart';

class PasarDetailPage extends StatefulWidget {
 final int productId;

 const PasarDetailPage({super.key, required this.productId});

 @override
 State<PasarDetailPage> createState() => _PasarDetailPageState();
}

class _PasarDetailPageState extends State<PasarDetailPage>
  with SingleTickerProviderStateMixin {
 final PasarProductService _productService = PasarProductService();
 final PasarCartService _cartService = PasarCartService();
 final PasarFavoriteService _favService = PasarFavoriteService();

 Map<String, dynamic>? _product;
 Map<String, dynamic>? _seller;
 List<Map<String, dynamic>> _apiReviews = [];
 Map<String, dynamic>? _ratingSummary;
 List<Map<String, dynamic>> _storeOtherProducts = [];
 bool _isLoading = true;
 bool _isFavorite = false;
 int _quantity = 1;
 int _currentImageIndex = 0;
 late TabController _tabController;
 final PageController _pageController = PageController();

 @override
 void initState() {
  super.initState();
  _tabController = TabController(length: 3, vsync: this);
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
  final allProducts = await _productService.getProducts();
  final isFav = await _favService.isProductFavorite(widget.productId);

  if (mounted) {
   Map<String, dynamic>? prodData;
   Map<String, dynamic>? sellerData;
   List<Map<String, dynamic>> revData = [];
   Map<String, dynamic>? ratingSum;

   if (detail != null) {
    if (detail.containsKey('product') && detail['product'] is Map) {
     prodData = Map<String, dynamic>.from(detail['product']);
     if (detail['seller'] is Map) {
      sellerData = Map<String, dynamic>.from(detail['seller']);
     }
     if (detail['reviews'] is List) {
      revData = List<Map<String, dynamic>>.from(detail['reviews']);
     }
     if (detail['rating_summary'] is Map) {
      ratingSum = Map<String, dynamic>.from(detail['rating_summary']);
     }
    } else {
     prodData = detail;
    }
   }

   // Filter other products from the same store / region
   final otherProds = allProducts
     .where((p) {
      final pId = p['id'] is int
        ? p['id']
        : int.tryParse(p['id']?.toString() ?? '0');
      return pId != widget.productId;
     })
     .take(6)
     .toList();

   setState(() {
    _product = prodData;
    _seller = sellerData;
    _apiReviews = revData;
    _ratingSummary = ratingSum;
    _storeOtherProducts = otherProds;
    _isFavorite = isFav;
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

 void _showImageZoomDialog(String imageSource) {
  showDialog(
   context: context,
   builder: (ctx) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(12),
    child: Stack(
     alignment: Alignment.topRight,
     children: [
      InteractiveViewer(
       panEnabled: true,
       minScale: 0.5,
       maxScale: 3.0,
       child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageSource.startsWith('assets/')
          ? Image.asset(imageSource, fit: BoxFit.contain)
          : Image.network(
            imageSource,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Container(
             color: Colors.black54,
             padding: const EdgeInsets.all(40),
             child: const Icon(
              Icons.broken_image,
              color: Colors.white,
              size: 40,
             ),
            ),
           ),
       ),
      ),
      Positioned(
       top: 10,
       right: 10,
       child: IconButton(
        icon: Container(
         padding: const EdgeInsets.all(4),
         decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
         ),
         child: const Icon(Icons.close, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(ctx),
       ),
      ),
     ],
    ),
   ),
  );
 }

 @override
 Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  const primaryColor = Color(0xFF0EA5E9);

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

  final formatCurrency = NumberFormat.currency(
   locale: 'id_ID',
   symbol: 'Rp ',
   decimalDigits: 0,
  );
  final String name = _product!['nama_produk'] ?? 'Tanpa Nama';
  final String? satuan = _product!['satuan'];
  final String? kategori = _product!['kategori'];
  final String? deskripsi = _product!['deskripsi'];
  final String? lokasi = _product!['lokasi'];
  final Map<String, dynamic>? region = _product!['region'] is Map
    ? Map<String, dynamic>.from(_product!['region'])
    : null;
  final String regionName = region?['name'] ?? lokasi ?? 'BUMDes Desa';

  return Scaffold(
   backgroundColor: Theme.of(context).scaffoldBackgroundColor,
   body: CustomScrollView(
    slivers: [
     // 1. SliverAppBar with Image Carousel
     SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: Theme.of(context).cardColor,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
       // Favorite Heart Button
       IconButton(
        icon: AnimatedScale(
         scale: _isFavorite ? 1.2 : 1.0,
         duration: const Duration(milliseconds: 200),
         child: Icon(
          _isFavorite
            ? Icons.favorite_rounded
            : Icons.favorite_border_rounded,
          color: _isFavorite ? Colors.redAccent : Colors.white,
         ),
        ),
        tooltip: 'Simpan ke Favorit',
        onPressed: () async {
         final isNow = await _favService.toggleProductFavorite(
          widget.productId,
         );
         if (mounted) {
          setState(() => _isFavorite = isNow);
          ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text(
             isNow
               ? ' $name ditambahkan ke Favorit'
               : '$name dihapus dari Favorit',
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
           ),
          );
         }
        },
       ),
       // Share Button
       IconButton(
        icon: const Icon(Icons.share_outlined),
        onPressed: () {
         SharePlus.instance.share(
          ShareParams(
           text:
             'Lihat produk $name dari BUMDes $regionName di Pasar Daerah SiladesBeng!',
          ),
         );
        },
       ),
       // More Options (Komplain / Lapor)
       PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded),
        onSelected: (value) {
         if (value == 'return') {
          ReturnRefundDialog.show(
           context,
           productName: name,
           tokoName: 'BUMDes $regionName',
           productPrice: _price,
           productImage: _images.isNotEmpty ? _images[0] : null,
          );
         } else if (value == 'report') {
          ReportStoreDialog.show(
           context,
           targetName: name,
           desaName: regionName,
           isProduct: true,
          );
         }
        },
        itemBuilder: (ctx) => [
         const PopupMenuItem(
          value: 'return',
          child: Row(
           children: [
            Icon(
             Icons.assignment_return_outlined,
             size: 18,
             color: Color(0xFF0EA5E9),
            ),
            SizedBox(width: 8),
            Text(
             'Ajukan Pengembalian',
             style: TextStyle(fontSize: 13),
            ),
           ],
          ),
         ),
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
             'Laporkan Produk Ini',
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
         if (_images.isNotEmpty)
          PageView.builder(
           controller: _pageController,
           itemCount: _images.length,
           onPageChanged: (index) {
            setState(() => _currentImageIndex = index);
           },
           itemBuilder: (context, index) {
            return GestureDetector(
             onTap: () => _showImageZoomDialog(_images[index]),
             child: Image.network(
              _images[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                Container(
                 color: Colors.grey[200],
                 child: Icon(
                  Icons.storefront,
                  size: 60,
                  color: Colors.grey[400],
                 ),
                ),
             ),
            );
           },
          )
         else
          Container(
           color: Colors.grey[200],
           child: Icon(
            Icons.storefront,
            size: 60,
            color: Colors.grey[400],
           ),
          ),
         // Gradient Overlay
         Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 80,
          child: Container(
           decoration: BoxDecoration(
            gradient: LinearGradient(
             colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.6),
             ],
             begin: Alignment.topCenter,
             end: Alignment.bottomCenter,
            ),
           ),
          ),
         ),
         // Image Indicator Dots
         if (_images.length > 1)
          Positioned(
           bottom: 16,
           left: 0,
           right: 0,
           child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_images.length, (index) {
             return Container(
              width: _currentImageIndex == index ? 20 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
               color: _currentImageIndex == index
                 ? Colors.white
                 : Colors.white.withValues(alpha: 0.5),
               borderRadius: BorderRadius.circular(3),
              ),
             );
            }),
           ),
          ),
        ],
       ),
      ),
     ),

     // 2. Product Name, Price, Category & Rating Badge
     SliverToBoxAdapter(
      child: Container(
       color: Theme.of(context).cardColor,
       padding: const EdgeInsets.all(16),
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Row(
          children: [
           if (kategori != null)
            Container(
             padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
             ),
             decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
             ),
             child: Text(
              kategori,
              style: const TextStyle(
               color: primaryColor,
               fontSize: 11,
               fontWeight: FontWeight.bold,
              ),
             ),
            ),
           const SizedBox(width: 8),
           // Rating Snippet
           Container(
            padding: const EdgeInsets.symmetric(
             horizontal: 8,
             vertical: 3,
            ),
            decoration: BoxDecoration(
             color: Colors.amber.withValues(alpha: 0.15),
             borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
             mainAxisSize: MainAxisSize.min,
             children: [
              Icon(
               Icons.star_rounded,
               size: 13,
               color: Color(0xFFF59E0B),
              ),
              SizedBox(width: 3),
              Text(
               '4.9 (48 ulasan)',
               style: TextStyle(
                color: Color(0xFFD97706),
                fontSize: 11,
                fontWeight: FontWeight.bold,
               ),
              ),
             ],
            ),
           ),
           const Spacer(),
           // Stock Status
           Container(
            padding: const EdgeInsets.symmetric(
             horizontal: 8,
             vertical: 3,
            ),
            decoration: BoxDecoration(
             color: _stock > 0
               ? Colors.green.withValues(alpha: 0.12)
               : Colors.red.withValues(alpha: 0.12),
             borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
             _stock > 0 ? 'Stok: $_stock' : 'Habis',
             style: TextStyle(
              color: _stock > 0 ? Colors.green : Colors.red,
              fontSize: 11,
              fontWeight: FontWeight.bold,
             ),
            ),
           ),
          ],
         ),
         const SizedBox(height: 10),
         Text(
          name,
          style: const TextStyle(
           fontSize: 19,
           fontWeight: FontWeight.w900,
          ),
         ),
         const SizedBox(height: 8),
         Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
           Text(
            formatCurrency.format(_price),
            style: const TextStyle(
             fontSize: 22,
             fontWeight: FontWeight.w900,
             color: Color(0xFF0EA5E9),
            ),
           ),
           if (satuan != null && satuan.isNotEmpty)
            Text(
             ' /$satuan',
             style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
             ),
            ),
          ],
         ),
        ],
       ),
      ),
     ),

     const SliverToBoxAdapter(child: SizedBox(height: 8)),

     // 3. Interactive Seller / BUMDes Card
     SliverToBoxAdapter(
      child: Container(
       color: Theme.of(context).cardColor,
       padding: const EdgeInsets.all(16),
       child: Row(
        children: [
         GestureDetector(
          onTap: () {
           Navigator.push(
            context,
            MaterialPageRoute(
             builder: (_) => BumdesStoreProfilePage(
              tokoName: 'BUMDes $regionName',
              desaName: regionName,
              kecamatanName: 'Kec. Bengkalis',
             ),
            ),
           );
          },
          child: Container(
           width: 48,
           height: 48,
           decoration: BoxDecoration(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
             color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
            ),
           ),
           child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: (_seller != null && _seller!['avatar'] != null && _seller!['avatar'].toString().isNotEmpty)
              ? Image.network(
                _seller!['avatar'],
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const Icon(
                 Icons.storefront_rounded,
                 color: Color(0xFF0EA5E9),
                 size: 26,
                ),
               )
              : const Icon(
                Icons.storefront_rounded,
                color: Color(0xFF0EA5E9),
                size: 26,
               ),
           ),
          ),
         ),
         const SizedBox(width: 12),
         Expanded(
          child: GestureDetector(
           onTap: () {
            final regId = _product?['region_id'] is int
              ? _product!['region_id']
              : int.tryParse(_product?['region_id']?.toString() ?? '0');
            Navigator.push(
             context,
             MaterialPageRoute(
              builder: (_) => BumdesStoreProfilePage(
               tokoName: _seller?['store_name'] ?? 'BUMDes $regionName',
               desaName: regionName,
               kecamatanName: 'Kec. Bengkalis',
               avatarUrl: _seller?['avatar'],
               bannerUrl: _seller?['store_banner'],
               description: _seller?['store_description'],
               regionId: regId,
              ),
             ),
            );
           },
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             Text(
              _seller?['store_name'] ?? 'BUMDes $regionName',
              style: const TextStyle(
               fontWeight: FontWeight.bold,
               fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
             ),
             const SizedBox(height: 2),
             Row(
              children: [
               Container(
                padding: const EdgeInsets.symmetric(
                 horizontal: 5,
                 vertical: 1.5,
                ),
                decoration: BoxDecoration(
                 color: Colors.blue.withValues(alpha: 0.15),
                 borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                 'BUMDes Resmi',
                 style: TextStyle(
                  color: Color(0xFF0284C7),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                 ),
                ),
               ),
               const SizedBox(width: 4),
               Expanded(
                child: Text(
                 '• Antar-Desa',
                 style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                 ),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
                ),
               ),
              ],
             ),
            ],
           ),
          ),
         ),
         const SizedBox(width: 6),
         OutlinedButton(
          onPressed: () {
           final regId = _product?['region_id'] is int
             ? _product!['region_id']
             : int.tryParse(_product?['region_id']?.toString() ?? '0');
           Navigator.push(
            context,
            MaterialPageRoute(
             builder: (_) => BumdesStoreProfilePage(
              tokoName: _seller?['store_name'] ?? 'BUMDes $regionName',
              desaName: regionName,
              kecamatanName: 'Kec. Bengkalis',
              avatarUrl: _seller?['avatar'],
              bannerUrl: _seller?['store_banner'],
              description: _seller?['store_description'],
              regionId: regId,
             ),
            ),
           );
          },
          style: OutlinedButton.styleFrom(
           foregroundColor: const Color(0xFF0EA5E9),
           side: const BorderSide(
            color: Color(0xFF0EA5E9),
            width: 1.2,
           ),
           padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
           ),
           minimumSize: Size.zero,
           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
           shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
           ),
          ),
          child: const Text(
           'Kunjungi Toko',
           style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
           ),
          ),
         ),
        ],
       ),
      ),
     ),

     const SliverToBoxAdapter(child: SizedBox(height: 8)),

     // 4. Tab Bar: Deskripsi, Ulasan Warga (Foto Barang), Info Penting
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
          indicatorWeight: 3,
          labelStyle: const TextStyle(
           fontWeight: FontWeight.bold,
           fontSize: 13,
          ),
          tabs: [
           const Tab(text: 'Deskripsi'),
           Tab(text: ' Ulasan (${_apiReviews.length})'),
           const Tab(text: 'Info Penting'),
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
         if (_tabController.index == 0) {
          return Padding(
           padding: const EdgeInsets.all(16),
           child: Text(
            deskripsi ?? 'Tidak ada deskripsi untuk produk ini.',
            style: TextStyle(
             color: isDark ? Colors.white70 : Colors.grey[700],
             fontSize: 14,
             height: 1.5,
            ),
           ),
          );
         } else if (_tabController.index == 1) {
          // TAB 2: Ulasan Pembeli dari Backend
          final avgRating = _ratingSummary?['average']?.toString() ?? '5.0';
          final totalReviews = _ratingSummary?['total_reviews'] ?? _apiReviews.length;

          return Padding(
           padding: const EdgeInsets.all(16),
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             // Rating Score & Write Review Button
             Row(
              children: [
               Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 Row(
                  children: [
                   Text(
                    avgRating,
                    style: const TextStyle(
                     fontSize: 28,
                     fontWeight: FontWeight.w900,
                     color: Color(0xFFF59E0B),
                    ),
                   ),
                   const SizedBox(width: 6),
                   const Icon(
                    Icons.star_rounded,
                    color: Color(0xFFF59E0B),
                    size: 24,
                   ),
                  ],
                 ),
                 Text(
                  '$totalReviews Ulasan Pembeli',
                  style: const TextStyle(
                   fontSize: 11.5,
                   color: Colors.grey,
                   fontWeight: FontWeight.w500,
                  ),
                 ),
                ],
               ),
               const Spacer(),
               ElevatedButton.icon(
                onPressed: () async {
                 final result = await GiveReviewDialog.show(
                  context,
                  productId: widget.productId,
                  productName: name,
                  tokoName: _seller?['store_name'] ?? 'BUMDes $regionName',
                  desaName: regionName,
                  productImage: _images.isNotEmpty
                    ? _images[0]
                    : null,
                 );
                 if (result == true) {
                  _fetchDetail();
                 }
                },
                icon: const Icon(
                 Icons.edit_note_rounded,
                 size: 18,
                 color: Colors.white,
                ),
                label: const Text(
                 'Beri Ulasan',
                 style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                 ),
                ),
                style: ElevatedButton.styleFrom(
                 backgroundColor: const Color(0xFFF59E0B),
                 padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                 ),
                 shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                 ),
                 elevation: 0,
                ),
               ),
              ],
             ),
             const Divider(height: 24),

             // Customer Reviews List
             if (_apiReviews.isEmpty)
              Center(
               child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                 children: [
                  Icon(
                   Icons.rate_review_outlined,
                   size: 40,
                   color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                   'Belum ada ulasan untuk produk ini.',
                   style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                   ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                   'Jadilah yang pertama memberikan ulasan!',
                   style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white38 : Colors.grey[500],
                   ),
                  ),
                 ],
                ),
               ),
              )
             else
              ..._apiReviews.map(
               (rev) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildDetailedReviewCard(rev, isDark),
               ),
              ),
            ],
           ),
          );
         } else {
          // TAB 3: Info Penting
          return Padding(
           padding: const EdgeInsets.all(16),
           child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             _buildInfoRow(
              Icons.local_shipping_rounded,
              'Pengiriman',
              'Same-day delivery (satu desa & antar-desa Bengkalis)',
             ),
             const SizedBox(height: 12),
             _buildInfoRow(
              Icons.verified_user_rounded,
              'Garansi Mutu',
              'Barang dijamin asli dan sesuai standar BUMDes',
             ),
             const SizedBox(height: 12),
             _buildInfoRow(
              Icons.chat_bubble_outline_rounded,
              'Layanan Tanya BUMDes',
              'Gunakan tombol Chat Penjual untuk info stok atau custom pesanan',
             ),
            ],
           ),
          );
         }
        },
       ),
      ),
     ),

     const SliverToBoxAdapter(child: SizedBox(height: 12)),

     // 5. Section: "Produk Lainnya dari Toko BUMDes Ini" (Cross-sell)
     if (_storeOtherProducts.isNotEmpty)
      SliverToBoxAdapter(
       child: Container(
        color: Theme.of(context).cardColor,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Row(
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: [
            Row(
             children: [
              const Icon(
               Icons.storefront_rounded,
               size: 19,
               color: Color(0xFF0EA5E9),
              ),
              const SizedBox(width: 6),
              Text(
               'Lainnya dari BUMDes $regionName',
               style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
               ),
              ),
             ],
            ),
            GestureDetector(
             onTap: () {
              Navigator.push(
               context,
               MaterialPageRoute(
                builder: (_) => BumdesStoreProfilePage(
                 tokoName: 'BUMDes $regionName',
                 desaName: regionName,
                 kecamatanName: 'Kec. Bengkalis',
                ),
               ),
              );
             },
             child: const Text(
              'Lihat Semua →',
              style: TextStyle(
               color: Color(0xFF0EA5E9),
               fontSize: 12,
               fontWeight: FontWeight.bold,
              ),
             ),
            ),
           ],
          ),
          const SizedBox(height: 12),
          SizedBox(
           height: 190,
           child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _storeOtherProducts.length,
            separatorBuilder: (context, index) =>
              const SizedBox(width: 12),
            itemBuilder: (context, i) {
             final prod = _storeOtherProducts[i];
             return _buildOtherProductItem(
              prod,
              isDark,
              formatCurrency,
             );
            },
           ),
          ),
         ],
        ),
       ),
      ),

     // Spacer for Sticky Bottom Bar
     const SliverToBoxAdapter(child: SizedBox(height: 120)),
    ],
   ),

   // Sticky Bottom Action Bar
   bottomNavigationBar: _stock <= 0
     ? Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
         BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, -4),
         ),
        ],
       ),
       child: const SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
         onPressed: null,
         child: Text(
          'Stok Habis',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
         ),
        ),
       ),
      )
     : Container(
       padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
       decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
         BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, -4),
         ),
        ],
       ),
       child: SafeArea(
        child: Column(
         mainAxisSize: MainAxisSize.min,
         children: [
          // Quantity Stepper + Subtotal
          Row(
           children: [
            Container(
             decoration: BoxDecoration(
              border: Border.all(
               color: isDark
                 ? Colors.white24
                 : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(8),
             ),
             child: Row(
              children: [
               InkWell(
                onTap: () {
                 if (_quantity > 1) {
                  setState(() => _quantity--);
                 }
                },
                child: Container(
                 padding: const EdgeInsets.all(8),
                 child: Icon(
                  Icons.remove,
                  size: 18,
                  color: _quantity > 1
                    ? (isDark ? Colors.white : Colors.black)
                    : Colors.grey,
                 ),
                ),
               ),
               Container(
                padding: const EdgeInsets.symmetric(
                 horizontal: 16,
                ),
                child: Text(
                 '$_quantity',
                 style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                 ),
                ),
               ),
               InkWell(
                onTap: () {
                 if (_quantity < _stock) {
                  setState(() => _quantity++);
                 } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(
                    content: Text('Melebihi stok tersedia'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                   ),
                  );
                 }
                },
                child: Container(
                 padding: const EdgeInsets.all(8),
                 child: Icon(
                  Icons.add,
                  size: 18,
                  color: _quantity < _stock
                    ? (isDark ? Colors.white : Colors.black)
                    : Colors.grey,
                 ),
                ),
               ),
              ],
             ),
            ),
            const Spacer(),
            Column(
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
              Text(
               'Subtotal',
               style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
               ),
              ),
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
          // Action Buttons Row
          Row(
           children: [
            // Chat Button
            Container(
             margin: const EdgeInsets.only(right: 8),
             decoration: BoxDecoration(
              border: Border.all(
               color: const Color(
                0xFF0EA5E9,
               ).withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(12),
             ),
             child: IconButton(
              onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(
                 builder: (_) => TokoChatPage(
                  tokoName: 'BUMDes $regionName',
                  tokoDesa: regionName,
                  tokoKecamatan: 'Kec. Bengkalis',
                  productInquiry: {
                   'id': widget.productId,
                   'nama_produk': name,
                   'harga': _price,
                   'image_url': _images.isNotEmpty
                     ? _images[0]
                     : null,
                   'satuan': satuan,
                  },
                 ),
                ),
               );
              },
              icon: const Icon(
               Icons.chat_bubble_outline_rounded,
               color: Color(0xFF0EA5E9),
               size: 20,
              ),
              tooltip: 'Chat Toko BUMDes',
             ),
            ),
            // Add to Cart
            Expanded(
             child: OutlinedButton.icon(
              onPressed: () async {
               bool success = await _cartService.addToCart(
                widget.productId,
                _quantity,
               );
               if (mounted) {
                if (success) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                   content: Text(
                    'Ditambahkan ke keranjang!',
                   ),
                   backgroundColor: Color(0xFF10B981),
                   duration: Duration(seconds: 1),
                   behavior: SnackBarBehavior.floating,
                  ),
                 );
                } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                   content: Text('Gagal menambahkan'),
                   backgroundColor: Colors.red,
                   behavior: SnackBarBehavior.floating,
                  ),
                 );
                }
               }
              },
              icon: const Icon(
               Icons.shopping_cart_outlined,
               size: 18,
              ),
              label: const Text(
               'Keranjang',
               style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
               foregroundColor: const Color(0xFF0EA5E9),
               side: const BorderSide(color: Color(0xFF0EA5E9)),
               padding: const EdgeInsets.symmetric(vertical: 14),
               shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
               ),
              ),
             ),
            ),
            const SizedBox(width: 8),
            // Buy Now
            Expanded(
             child: ElevatedButton.icon(
              onPressed: () async {
               bool success = await _cartService.addToCart(
                widget.productId,
                _quantity,
               );
               if (mounted && success) {
                Navigator.push(
                 context,
                 MaterialPageRoute(
                  builder: (_) => const CartPage(),
                 ),
                );
               }
              },
              icon: const Icon(
               Icons.flash_on_rounded,
               size: 18,
               color: Colors.white,
              ),
              label: const Text(
               'Beli Langsung',
               style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
               ),
              ),
              style: ElevatedButton.styleFrom(
               backgroundColor: const Color(0xFF0EA5E9),
               padding: const EdgeInsets.symmetric(vertical: 14),
               shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
               ),
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



 Widget _buildDetailedReviewCard(Map<String, dynamic> review, bool isDark) {
  final String name = review['user_name'] ?? review['name'] ?? 'Warga';
  final String? avatarUrl = review['user_avatar'];
  final int rating = review['rating'] is int
    ? review['rating']
    : int.tryParse(review['rating']?.toString() ?? '5') ?? 5;
  final String dateStr = review['created_at'] ?? review['date'] ?? 'Baru saja';
  final String comment = review['comment'] ?? '';
  final String? reply = review['reply'];
  final String? repliedAt = review['replied_at'];

  return Container(
   padding: const EdgeInsets.all(14),
   decoration: BoxDecoration(
    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(
     color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
    ),
   ),
   child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
     // Header (Avatar, Name, Date, Rating)
     Row(
      children: [
       CircleAvatar(
        radius: 16,
        backgroundColor: const Color(
         0xFF0EA5E9,
        ).withValues(alpha: 0.15),
        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
          ? NetworkImage(avatarUrl)
          : null,
        child: (avatarUrl == null || avatarUrl.isEmpty)
          ? Text(
            name.isNotEmpty ? name[0] : 'W',
            style: const TextStyle(
             fontSize: 13,
             fontWeight: FontWeight.bold,
             color: Color(0xFF0EA5E9),
            ),
           )
          : null,
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
           dateStr,
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
         rating,
         (index) => const Icon(
          Icons.star_rounded,
          size: 14,
          color: Color(0xFFF59E0B),
         ),
        ),
       ),
      ],
     ),

     if (comment.isNotEmpty) ...[
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

     // Admin Desa Reply Section
     if (reply != null && reply.isNotEmpty) ...[
      const SizedBox(height: 10),
      Container(
       width: double.infinity,
       padding: const EdgeInsets.all(10),
       decoration: BoxDecoration(
        color: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
         color: isDark ? Colors.white12 : const Color(0xFFBBF7D0),
        ),
       ),
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Row(
          children: [
           const Icon(
            Icons.storefront_rounded,
            size: 14,
            color: Color(0xFF16A34A),
           ),
           const SizedBox(width: 5),
           Text(
            'Respon Penjual (Admin Desa)',
            style: TextStyle(
             fontSize: 11,
             fontWeight: FontWeight.bold,
             color: isDark
               ? const Color(0xFF4ADE80)
               : const Color(0xFF15803D),
            ),
           ),
           if (repliedAt != null) ...[
            const Spacer(),
            Text(
             repliedAt,
             style: TextStyle(
              fontSize: 9.5,
              color: isDark ? Colors.white38 : Colors.grey[500],
             ),
            ),
           ],
          ],
         ),
         const SizedBox(height: 4),
         Text(
          reply,
          style: TextStyle(
           fontSize: 12,
           height: 1.35,
           color: isDark
             ? Colors.white70
             : const Color(0xFF166534),
          ),
         ),
        ],
       ),
      ),
     ],
    ],
   ),
  );
 }

 Widget _buildOtherProductItem(
  Map<String, dynamic> prod,
  bool isDark,
  NumberFormat formatCurrency,
 ) {
  final name = prod['nama_produk'] ?? prod['name'] ?? '';
  final double price = prod['harga'] != null
    ? double.tryParse(prod['harga'].toString()) ?? 0
    : (prod['price'] != null
       ? double.tryParse(prod['price'].toString()) ?? 0
       : 0);
  final String? imageUrl =
    prod['image_url'] ??
    (prod['images'] is List && prod['images'].isNotEmpty
      ? prod['images'][0]
      : null);
  final int prodId = prod['id'] is int
    ? prod['id']
    : int.tryParse(prod['id']?.toString() ?? '0') ?? 0;

  return GestureDetector(
   onTap: () {
    Navigator.pushReplacement(
     context,
     MaterialPageRoute(builder: (_) => PasarDetailPage(productId: prodId)),
    );
   },
   child: Container(
    width: 135,
    decoration: BoxDecoration(
     color: isDark ? const Color(0xFF1E293B) : Colors.white,
     borderRadius: BorderRadius.circular(12),
     border: Border.all(
      color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
     ),
    ),
    child: Column(
     crossAxisAlignment: CrossAxisAlignment.start,
     children: [
      // Image
      ClipRRect(
       borderRadius: const BorderRadius.vertical(
        top: Radius.circular(12),
       ),
       child: imageUrl != null
         ? Image.network(
           imageUrl,
           width: 135,
           height: 95,
           fit: BoxFit.cover,
           errorBuilder: (_, _, _) => Container(
            width: 135,
            height: 95,
            color: Colors.grey[200],
            child: const Icon(
             Icons.shopping_bag,
             color: Colors.grey,
            ),
           ),
          )
         : Container(
           width: 135,
           height: 95,
           color: Colors.grey[200],
           child: const Icon(Icons.shopping_bag, color: Colors.grey),
          ),
      ),
      // Info
      Padding(
       padding: const EdgeInsets.all(8),
       child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
         Text(
          name,
          style: const TextStyle(
           fontSize: 11.5,
           fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
         ),
         const SizedBox(height: 3),
         Text(
          formatCurrency.format(price),
          style: const TextStyle(
           fontSize: 12,
           fontWeight: FontWeight.w900,
           color: Color(0xFF0EA5E9),
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
       Text(
        title,
        style: const TextStyle(
         fontWeight: FontWeight.bold,
         fontSize: 13,
        ),
       ),
       const SizedBox(height: 2),
       Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
       ),
      ],
     ),
    ),
   ],
  );
 }
}
