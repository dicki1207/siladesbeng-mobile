import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'rental_booking_page.dart';
import 'item_detail_page.dart';
import 'tool_package_booking_page.dart';
import 'package:siladesbeng_mobile/services/rental_service.dart';
import '../../widgets/product_card_widget.dart';
import '../common/unit_service_chat_page.dart';

class ServiceListPage extends StatefulWidget {
  const ServiceListPage({super.key});

  @override
  State<ServiceListPage> createState() => _ServiceListPageState();
}

class _ServiceListPageState extends State<ServiceListPage> {
  List<dynamic> _rentals = [];
  bool _isLoading = true;
  final RentalService _rentalService = RentalService();

  @override
  void initState() {
    super.initState();
    _fetchRentals();
  }

  Future<void> _fetchRentals() async {
    final data = await _rentalService.getRentalItems();
    if (!mounted) return;
    setState(() {
      _rentals = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Penyewaan Alat',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFF2563EB),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [const Color(0xFF2FA2F1), const Color(0xFF0284C7)],
                ),
              ),
            ),
            // Glowing circle 1 (Top Right)
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(22),
                ),
              ),
            ),
            // Glowing circle 2 (Bottom Left)
            Positioned(
              bottom: -25,
              left: -15,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(14),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.white,
              size: 20.sp,
            ),
            tooltip: 'Chat Sewa Alat',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UnitServiceChatPage(
                    serviceType: 'penyewaan',
                    title: 'Chat Sewa Alat',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRentals,
        color: Theme.of(context).primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 450),
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const ToolPackageBookingPage(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              final curve = CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutQuart,
                              );
                              return FadeTransition(
                                opacity: curve,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.05),
                                    end: Offset.zero,
                                  ).animate(curve),
                                  child: child,
                                ),
                              );
                            },
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[600]!, Colors.blue[900]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withAlpha(50),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.handyman_outlined,
                            color: Colors.white,
                            size: 32.sp,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FITUR BARU & HEMAT!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Pilih Paket Desa atau Rangkai Paket Alat Anda Sendiri',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _isLoading
                ? SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.h,
                        ),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                          ),
                        ),
                      );
                    }, childCount: 5),
                  )
                : _rentals.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.all(24.0.w),
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 40.h,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(30.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withAlpha(20),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CachedNetworkImage(
                                imageUrl: 'http://10.121.197.148:8000/User/img/elemen/F1.png',
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                                memCacheWidth: 500,
                                placeholder: (ctx, url) => Container(color: Colors.grey[200]),
                                errorWidget: (ctx, url, err) => const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                              SizedBox(height: 20.h),
                              Text(
                                "Belum Ada Alat",
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                "Peralatan untuk disewakan sedang tidak tersedia saat ini atau gagal memuat data dari server.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color:
                                      Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withAlpha(150) ??
                                      Colors.grey,
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: 30.h),
                              ElevatedButton.icon(
                                onPressed: _fetchRentals,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Muat Ulang'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                    vertical: 12.h,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.r),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: EdgeInsets.all(16.w),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16.0,
                            crossAxisSpacing: 16.0,
                            childAspectRatio: 0.7,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildPremiumRentalCard(_rentals[index], index),
                        childCount: _rentals.length,
                      ),
                    ),
                  ),
            SliverToBoxAdapter(
              child: SizedBox(height: 100.h), // Bottom navigation spacing
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumRentalCard(dynamic item, int index) {
    double priceVal = 0;
    if (item['price'] != null) {
      if (item['price'] is String) {
        priceVal = double.tryParse(item['price'].toString()) ?? 0;
      } else if (item['price'] is num) {
        priceVal = (item['price'] as num).toDouble();
      }
    }

    String imageUrl = item['image'] ?? 'assets/images/F1.png';
    bool isAsset =
        imageUrl.startsWith('assets/') || imageUrl.contains('F1.png');
    if (isAsset) imageUrl = 'assets/images/F1.png';

    // Asumsikan status selalu tersedia untuk alat sementara
    String status = item['status'] ?? 'Tersedia';
    bool isAvailable = status.toLowerCase() == 'tersedia';

    // Alat biasanya ada stok, kita coba ambil stok jika ada
    int stock = 0;
    if (item['stok'] != null) {
      stock = int.tryParse(item['stok'].toString()) ?? 0;
    } else if (item['stock'] != null) {
      stock = int.tryParse(item['stock'].toString()) ?? 0;
    }

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutQuart,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: ProductCardWidget(
              title: item['name'] ?? 'Alat / Perlengkapan',
              category: item['kategori'] ?? 'Penyewaan Alat',
              imageUrl: imageUrl,
              isAssetImage: isAsset,
              price: priceVal,
              priceUnit: '/Hari',
              stockLabel: stock > 0 ? 'Sisa Stok' : '',
              stockValue: stock > 0 ? stock.toString() : '',
              statusText: isAvailable ? 'Tersedia' : 'Kosong',
              statusColor: isAvailable ? const Color(0xFF10B981) : Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetailPage(
                      item: item,
                      category: 'Sewa Alat',
                      bookingPage: RentalBookingPage(
                        item: item,
                        category: 'Sewa Alat',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
