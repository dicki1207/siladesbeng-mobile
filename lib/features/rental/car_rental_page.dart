import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'rental_booking_page.dart';
import 'item_detail_page.dart';
import 'package:siladesbeng_mobile/services/rental_service.dart';
import '../../widgets/product_card_widget.dart';

class CarRentalPage extends StatefulWidget {
  const CarRentalPage({super.key});

  @override
  State<CarRentalPage> createState() => _CarRentalPageState();
}

class _CarRentalPageState extends State<CarRentalPage> {
  late final ShowcaseView _showcaseView;
  final GlobalKey _keyCarItem = GlobalKey();

  List<dynamic> _rentals = [];
  bool _isLoading = true;
  final RentalService _rentalService = RentalService();

  @override
  void initState() {
    super.initState();
    _showcaseView = ShowcaseView.register();
    _fetchRentals();
  }

  @override
  void dispose() {
    _showcaseView.unregister();
    super.dispose();
  }

  Future<void> _checkAndStartShowcase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenTour = prefs.getBool('has_seen_car_rental_tour') ?? false;
      if (!hasSeenTour && mounted && _rentals.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          _showcaseView.startShowCase([_keyCarItem]);
          await prefs.setBool('has_seen_car_rental_tour', true);
        }
      }
    } catch (e) {
      debugPrint('Car showcase error: $e');
    }
  }

  void _replayCarTour() {
    if (_rentals.isNotEmpty) {
      _showcaseView.startShowCase([_keyCarItem]);
    }
  }

  Future<void> _fetchRentals() async {
    final data = await _rentalService.getMobilItems();
    if (!mounted) return;

    // Filter out public facility vehicles (like Ambulans, Bus) from rental cars
    final filteredData = data.where((item) {
      if (item is! Map) return false;
      final name = (item['name'] ?? '').toString().toLowerCase();
      final category = (item['category'] ?? '').toString().toLowerCase();
      
      bool isPublicFacility = name.contains('ambulan') || 
                              name.contains('bus') ||
                              name.contains('jenazah') ||
                              category.contains('ambulan') || 
                              category.contains('fasilitas');
                              
      return !isPublicFacility;
    }).toList();

    setState(() {
      _rentals = filteredData;
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartShowcase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Penyewaan Kendaraan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        centerTitle: true,
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
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'Panduan Sewa Kendaraan',
            onPressed: _replayCarTour,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRentals,
        color: Theme.of(context).primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _isLoading
                ? SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
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
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 40,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(30),
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
                              Image.asset(
                                'assets/images/mobil.png',
                                width: 150,
                                height: 150,
                                errorBuilder: (ctx, err, stack) => Icon(
                                  Icons.directions_car,
                                  size: 100,
                                  color: Colors.blue[600],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                "Belum Ada Mobil",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Mobil untuk disewakan sedang tidak tersedia saat ini atau gagal memuat data dari server.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
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
                              const SizedBox(height: 30),
                              ElevatedButton.icon(
                                onPressed: _fetchRentals,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Muat Ulang'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
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
                    padding: const EdgeInsets.all(16),
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
            const SliverToBoxAdapter(
              child: SizedBox(height: 100), // Bottom navigation spacing
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

    String imageUrl = item['image'] ?? 'assets/images/mobil.png';
    bool isAsset = imageUrl.startsWith('assets/') || imageUrl.contains('mobil.png');
    if (isAsset) imageUrl = 'assets/images/mobil.png';
    
    // Asumsikan status selalu tersedia untuk mobil sementara
    String status = item['status'] ?? 'Tersedia';
    bool isAvailable = status.toLowerCase() == 'tersedia';
    
    int stock = 0;
    if (item['stok'] != null) {
      stock = int.tryParse(item['stok'].toString()) ?? 0;
    } else if (item['stock'] != null) {
      stock = int.tryParse(item['stock'].toString()) ?? 0;
    }

    final cardWidget = TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutQuart,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: ProductCardWidget(
              title: item['name'] ?? 'Mobil Rental',
              category: item['kategori'] ?? 'Penyewaan Kendaraan',
              imageUrl: imageUrl,
              isAssetImage: isAsset,
              price: priceVal,
              priceUnit: '/Hari',
              stockLabel: stock > 0 ? 'Sisa Stok' : '',
              stockValue: stock > 0 ? stock.toString() : '',
              statusText: isAvailable ? 'Tersedia' : 'Disewa',
              statusColor: isAvailable ? const Color(0xFF10B981) : Colors.red,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetailPage(
                      item: item,
                      category: 'Sewa Mobil',
                      bookingPage: RentalBookingPage(
                        item: item,
                        category: 'Sewa Mobil',
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

    if (index == 0) {
      return Showcase(
        key: _keyCarItem,
        title: 'Pilih Mobil BUMDes',
        description: 'Ketuk pada mobil untuk melihat spesifikasi kapasitas, tarif sewa harian, opsi sopir, dan pesan langsung.',
        targetBorderRadius: BorderRadius.circular(20),
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}
