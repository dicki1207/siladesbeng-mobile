import 'package:flutter/material.dart';
import 'package:siladesbeng_mobile/core/verification_guard.dart';
import 'package:siladesbeng_mobile/widgets/custom_cached_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../common/unit_service_chat_page.dart';

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

  /// Ambil nilai pertama yang benar-benar ada dari beberapa kemungkinan nama
  /// field. Bentuk payload tiap modul (gas/mobil/fasilitas/alat) berbeda, dan
  /// spek yang datanya tidak ada sengaja dilewat — bukan diisi tebakan.
  String? _pick(List<String> keys, {String prefix = '', String suffix = ''}) {
    for (final key in keys) {
      final raw = item[key];
      if (raw == null) continue;
      final value = raw.toString().trim();
      if (value.isEmpty || value == '-' || value == 'null' || value == '0') {
        continue;
      }
      return '$prefix$value$suffix';
    }
    return null;
  }

  void _addSpec(
    List<Map<String, dynamic>> list,
    IconData icon,
    String label,
    String? value,
  ) {
    if (value == null) return;
    list.add({'icon': icon, 'label': label, 'value': value});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final title = item['name'] ?? item['jenis_gas'] ?? item['title'] ?? 'Tanpa Nama';
    final price = item['price'] ?? item['harga_satuan'] ?? item['harga_sewa'] ?? 0;
    final description = item['description'] ?? item['deskripsi'];

    int stock = 0;
    final bool hasStockField = item['stok'] != null || item['stock'] != null;
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

    // Berat tabung gas dibaca dari data, atau disimpulkan dari judul kalau
    // judulnya memang menyebut ukuran. Kalau dua-duanya tidak ada, dibiarkan
    // kosong supaya tidak mengarang ukuran tabung.
    String? detectedWeight = _pick(['berat', 'weight', 'ukuran']);
    if (detectedWeight == null) {
      final lowerTitle = title.toString().toLowerCase();
      if (lowerTitle.contains('12kg') || lowerTitle.contains('12 kg')) {
        detectedWeight = '12 kg';
      } else if (lowerTitle.contains('5.5kg') ||
          lowerTitle.contains('5.5 kg') ||
          lowerTitle.contains('5,5')) {
        detectedWeight = '5.5 kg';
      } else if (lowerTitle.contains('3kg') || lowerTitle.contains('3 kg')) {
        detectedWeight = '3 kg';
      }
    }

    // Spesifikasi dibangun dari data yang benar-benar dikirim API. Sebelumnya
    // blok ini berisi teks tetap ("7 Penumpang", "Manual / Matic", "200 m2")
    // yang muncul untuk unit apa pun, jadi bisa menyesatkan penyewa.
    final List<Map<String, dynamic>> specList = [];
    if (category == 'Beli Gas') {
      _addSpec(specList, Icons.scale_rounded, 'Berat Bersih', detectedWeight);
      _addSpec(
        specList,
        Icons.inventory_2_outlined,
        'Ketersediaan',
        stock > 0 ? '$stock Tabung' : (hasStockField ? 'Stok Kosong' : null),
      );
    } else if (category == 'Sewa Mobil') {
      _addSpec(
        specList,
        Icons.airline_seat_recline_normal_rounded,
        'Kapasitas',
        _pick(['kapasitas', 'capacity', 'jumlah_kursi', 'seats'],
            suffix: ' Penumpang'),
      );
      _addSpec(
        specList,
        Icons.settings_outlined,
        'Transmisi',
        _pick(['transmisi', 'transmission']),
      );
      _addSpec(
        specList,
        Icons.local_gas_station_outlined,
        'Bahan Bakar',
        _pick(['bahan_bakar', 'jenis_bbm', 'fuel_type', 'fuel']),
      );
      _addSpec(
        specList,
        Icons.confirmation_number_outlined,
        'Plat Nomor',
        _pick(['plat_nomor', 'nomor_plat', 'plat', 'no_polisi']),
      );
      _addSpec(
        specList,
        Icons.calendar_today_rounded,
        'Tahun',
        _pick(['tahun', 'year', 'tahun_kendaraan']),
      );
    } else if (category == 'Fasilitas Umum') {
      _addSpec(
        specList,
        Icons.groups_outlined,
        'Kapasitas',
        _pick(['kapasitas', 'capacity', 'daya_tampung'], suffix: ' Orang'),
      );
      _addSpec(
        specList,
        Icons.aspect_ratio_rounded,
        'Luas Area',
        _pick(['luas', 'luas_area', 'area'], suffix: ' m²'),
      );
      _addSpec(
        specList,
        Icons.place_outlined,
        'Lokasi',
        _pick(['lokasi', 'alamat', 'location']),
      );
    } else {
      _addSpec(
        specList,
        Icons.verified_outlined,
        'Kondisi Alat',
        _pick(['kondisi', 'condition']),
      );
      _addSpec(
        specList,
        Icons.straighten_rounded,
        'Satuan',
        _pick(['satuan', 'unit']),
      );
      _addSpec(
        specList,
        Icons.inventory_2_outlined,
        'Ketersediaan',
        stock > 0 ? '$stock Unit' : (hasStockField ? 'Stok Kosong' : null),
      );
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
                          : CustomCachedImage(
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

                  // Sembunyikan seluruh blok kalau tidak ada spek yang
                  // datanya tersedia, daripada menampilkan kartu kosong.
                  if (specList.isNotEmpty) ...[
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
                      children: specList.take(3).map((spec) {
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
                  ],

                  SizedBox(height: 24.h),



                  if (description != null && description.toString().trim().isNotEmpty) ...[
                    SizedBox(height: 24.h),
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
                      description.toString(),
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        color: isDark ? Colors.white60 : Colors.grey[700],
                        height: 1.55,
                      ),
                    ),
                  ],
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
              // Chat Button (Sama seperti Pasar Daerah)
              Container(
                margin: EdgeInsets.only(right: 12.w),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: IconButton(
                  onPressed: () {
                    String serviceType = 'penyewaan';
                    String chatTitle = 'Layanan Pesan Alat';
                    final catLower = category.toLowerCase();
                    if (catLower.contains('gas')) {
                      serviceType = 'gas';
                      chatTitle = 'Layanan Pesan Gas';
                    } else if (catLower.contains('mobil') || catLower.contains('kendaraan')) {
                      serviceType = 'mobil';
                      chatTitle = 'Layanan Pesan Mobil';
                    } else if (catLower.contains('fasilitas') || catLower.contains('gedung') || catLower.contains('lapangan')) {
                      serviceType = 'fasilitas_umum';
                      chatTitle = 'Layanan Pesan Fasilitas';
                    }

                    int? regId;
                    if (item['region_id'] is int) {
                      regId = item['region_id'];
                    } else if (item['region_id'] != null) {
                      regId = int.tryParse(item['region_id'].toString());
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UnitServiceChatPage(
                          serviceType: serviceType,
                          title: chatTitle,
                          itemInquiry: title,
                          itemImage: imageUrl,
                          itemPrice: price.toString(),
                          itemUnit: item['satuan'] ?? item['unit'] ?? (category == 'Beli Gas' ? '/ tabung' : '/ hari'),
                          regionId: regId,
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: primaryColor,
                    size: 20.sp,
                  ),
                  tooltip: 'Chat Petugas Layanan',
                ),
              ),

              // Price Summary
              Expanded(
                flex: 40,
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
                  onPressed: () async {
                    final canProceed = await VerificationGuard.ensureVerified(
                      context,
                      serviceName: category.toLowerCase().contains('gas')
                          ? 'layanan pemesanan Gas'
                          : 'layanan penyewaan',
                    );
                    if (!canProceed || !context.mounted) return;

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
