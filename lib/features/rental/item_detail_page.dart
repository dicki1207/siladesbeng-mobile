import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class ItemDetailPage extends StatelessWidget {
  final dynamic item;
  final String category;
  final Widget bookingPage;

  const ItemDetailPage({
    super.key,
    required this.item,
    required this.category,
    required this.bookingPage,
  });

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'Rp 0';
    final number = double.tryParse(amount.toString()) ?? 0;
    final formatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final title = item['name'] ?? item['jenis_gas'] ?? item['title'] ?? 'Tanpa Nama';
    final price = item['price'] ?? item['harga_satuan'] ?? item['harga_sewa'] ?? 0;
    final description = item['description'] ??
        item['deskripsi'] ??
        'Produk resmi BUMDes yang siap melayani kebutuhan warga desa dengan kualitas terjamin.';

    int stock = 0;
    if (item['stok'] != null) {
      stock = int.tryParse(item['stok'].toString()) ?? 0;
    } else if (item['stock'] != null) {
      stock = int.tryParse(item['stock'].toString()) ?? 0;
    }

    String imageUrl = item['image_url'] ?? item['image'] ?? item['foto'] ?? 'assets/images/mobil.png';
    if (imageUrl.contains('F2.png')) {
      imageUrl = 'assets/images/F2.png';
    } else if (imageUrl.contains('lapor.png')) {
      imageUrl = 'assets/images/lapor.png';
    } else if (imageUrl.contains('F1.png') || imageUrl.contains('alat.png')) {
      imageUrl = 'assets/images/F1.png';
    } else if (imageUrl.contains('mobil.png')) {
      imageUrl = 'assets/images/mobil.png';
    } else if (imageUrl.contains('fasilitas.png')) {
      imageUrl = 'assets/images/fasilitas.png';
    }

    // Auto-detect weight from gas title if in gas category
    String detectedWeight = '3 kg';
    final lowerTitle = title.toString().toLowerCase();
    if (lowerTitle.contains('12kg') || lowerTitle.contains('12 kg')) {
      detectedWeight = '12 kg';
    } else if (lowerTitle.contains('5.5kg') || lowerTitle.contains('5.5 kg') || lowerTitle.contains('5,5')) {
      detectedWeight = '5.5 kg';
    } else if (lowerTitle.contains('3kg') || lowerTitle.contains('3 kg')) {
      detectedWeight = '3 kg';
    } else if (item['berat'] != null) {
      detectedWeight = item['berat'].toString();
    }

    // Dynamic Specs based on Category
    List<Map<String, dynamic>> specList = [];
    if (category == 'Beli Gas') {
      specList = [
        {
          'icon': Icons.scale_rounded,
          'label': 'Berat Bersih',
          'value': detectedWeight,
        },
        {
          'icon': Icons.inventory_2_outlined,
          'label': 'Ketersediaan',
          'value': stock > 0 ? '$stock Tabung' : 'Stok Kosong',
        },
        {
          'icon': Icons.local_shipping_outlined,
          'label': 'Pengantaran',
          'value': 'Antar / Ambil',
        },
      ];
    } else if (category == 'Sewa Mobil') {
      specList = [
        {
          'icon': Icons.airline_seat_recline_normal_rounded,
          'label': 'Kapasitas',
          'value': '7 Penumpang',
        },
        {
          'icon': Icons.settings_outlined,
          'label': 'Transmisi',
          'value': 'Manual / Matic',
        },
        {
          'icon': Icons.local_gas_station_outlined,
          'label': 'Bahan Bakar',
          'value': 'Bensin',
        },
      ];
    } else if (category == 'Fasilitas Umum') {
      specList = [
        {
          'icon': Icons.groups_outlined,
          'label': 'Kapasitas',
          'value': '100 - 500 Orang',
        },
        {
          'icon': Icons.aspect_ratio_rounded,
          'label': 'Luas Area',
          'value': '200 m²',
        },
        {
          'icon': Icons.local_parking_rounded,
          'label': 'Fasilitas',
          'value': 'Toilet & Parkir',
        },
      ];
    } else {
      specList = [
        {
          'icon': Icons.verified_outlined,
          'label': 'Kondisi Alat',
          'value': 'Siap Pakai',
        },
        {
          'icon': Icons.access_time_rounded,
          'label': 'Durasi Min',
          'value': '1 Hari',
        },
        {
          'icon': Icons.local_shipping_outlined,
          'label': 'Pengantaran',
          'value': 'Tersedia',
        },
      ];
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header Image with Circular Back Button
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 0,
            leading: Padding(
              padding: EdgeInsets.only(left: 12.w),
              child: Center(
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20.sp,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                child: Center(
                  child: Hero(
                    tag: 'product_img_${item['id'] ?? title}',
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                      child: imageUrl.startsWith('assets/')
                          ? Image.asset(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.image_not_supported_outlined,
                                size: 80.sp,
                                color: Colors.grey[400],
                              ),
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.image_not_supported_outlined,
                                size: 80.sp,
                                color: Colors.grey[400],
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Body Content
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Tag & Stock Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      if (stock > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 12.sp, color: Color(0xFF10B981)),
                              SizedBox(width: 4.w),
                              Text(
                                'Stok: $stock Tabung',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 6.h),

                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _formatCurrency(price),
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        category.contains('Sewa') ? '/ Hari' : '/ Tabung',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: isDark ? Colors.white54 : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // Spesifikasi Title
                  Text(
                    'Spesifikasi Produk',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Dynamic Specification Cards Row
                  Row(
                    children: specList.map((spec) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: 8.w),
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                spec['icon'] as IconData,
                                size: 18.sp,
                                color: primaryColor,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                spec['label'] as String,
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  color: isDark ? Colors.white38 : Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                spec['value'] as String,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 24.h),

                  // Notice Box
                  Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18.sp,
                          color: primaryColor,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            category == 'Beli Gas'
                                ? (lowerTitle.contains('3kg') || lowerTitle.contains('3 kg')
                                    ? 'Khusus gas subsidi, Anda dapat menukar tabung kosong langsung saat penerimaan di pangkalan BUMDes.'
                                    : 'Pesanan dapat diantar langsung ke rumah atau diambil secara mandiri di kantor BUMDes.')
                                : 'Layanan sewa didukung oleh BUMDes resmi untuk kemudahan masyarakat desa.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              height: 1.4,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Description
                  Text(
                    'Deskripsi Lengkap',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      color: isDark ? Colors.white60 : Colors.grey[700],
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Sticky Bar (Harga Ringkas + Tombol Pesan)
      bottomSheet: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.15),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Price Summary
              Expanded(
                flex: 45,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Harga',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDark ? Colors.white38 : Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatCurrency(price),
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 14.w),

              // Action Button
              Expanded(
                flex: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 400),
                        pageBuilder: (context, animation, secondaryAnimation) => bookingPage,
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutQuart);
                          return FadeTransition(
                            opacity: curve,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.05, 0.0),
                                end: Offset.zero,
                              ).animate(curve),
                              child: child,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  icon: Icon(
                    (category.toLowerCase().contains('gas'))
                        ? Icons.shopping_bag_outlined
                        : Icons.calendar_month_rounded,
                    size: 18.sp,
                  ),
                  label: Text(
                    (category.toLowerCase().contains('gas'))
                        ? 'Pesan Sekarang'
                        : 'Sewa Sekarang',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
