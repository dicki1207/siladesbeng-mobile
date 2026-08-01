import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'rental_booking_page.dart';
import 'item_detail_page.dart';
import 'package:siladesbeng_mobile/services/rental_service.dart';

class CarRentalPage extends StatefulWidget {
  const CarRentalPage({super.key});

  @override
  State<CarRentalPage> createState() => _CarRentalPageState();
}

class _CarRentalPageState extends State<CarRentalPage> {
  List<dynamic> _rentals = [];
  bool _isLoading = true;
  final RentalService _rentalService = RentalService();

  @override
  void initState() {
    super.initState();
    _fetchRentals();
  }

  List<Map<String, dynamic>> _getMockCars() {
    return [
      {
        'id': 1,
        'name': 'Avanza Veloz 2022',
        'price': 350000,
        'image': 'assets/images/mobil.png',
        'description':
            'Toyota Avanza Veloz terbaru dengan performa handal dan interior yang luas. Sangat cocok untuk perjalanan keluarga.',
      },
      {
        'id': 2,
        'name': 'Honda Brio RS 2023',
        'price': 300000,
        'image': 'assets/images/mobil.png',
        'description':
            'City car lincah dan irit bahan bakar, cocok untuk keliling kota dengan gaya modis.',
      },
      {
        'id': 3,
        'name': 'Mitsubishi Xpander',
        'price': 400000,
        'image': 'assets/images/mobil.png',
        'description':
            'Kenyamanan MPV premium dengan suspensi empuk, siap menemani perjalanan jarak jauh Anda.',
      },
    ];
  }

  Future<void> _fetchRentals() async {
    final data = await _rentalService.getMobilItems();
    if (!mounted) return;
    setState(() {
      _rentals = data.isNotEmpty ? data : _getMockCars();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _fetchRentals,
          color: Theme.of(context).primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 130.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF1E88E5),
                iconTheme: const IconThemeData(color: Colors.white),
                title: const Text(
                  'Penyewaan Kendaraan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
                shape: const ContinuousRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(60),
                    bottomRight: Radius.circular(60),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                      gradient: LinearGradient(
                        colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 50.0,
                          left: 24,
                          right: 24,
                        ),
                        child: Center(
                          child: Text(
                            'Temukan kendaraan terbaik untuk perjalanan Anda',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
                              childAspectRatio: 0.65,
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
      ),
    );
  }

  Widget _buildPremiumRentalCard(dynamic item, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    double priceVal = 0;
    if (item['price'] != null) {
      if (item['price'] is String) {
        priceVal = double.tryParse(item['price'].toString()) ?? 0;
      } else if (item['price'] is num) {
        priceVal = (item['price'] as num).toDouble();
      }
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
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 120,
                            width: double.infinity,
                            color: isDark ? Colors.grey[850] : Colors.white,
                            padding: const EdgeInsets.all(12),
                            child: (item['image'].toString().startsWith('assets/') || item['image'].toString().contains('mobil.png'))
                                ? Image.asset(
                                    'assets/images/mobil.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (ctx, err, stack) => const Icon(
                                      Icons.directions_car,
                                      size: 50,
                                      color: Colors.blueGrey,
                                    ),
                                  )
                                : Image.network(
                                    item['image'],
                                    fit: BoxFit.contain,
                                    errorBuilder: (ctx, err, stack) => const Icon(
                                      Icons.directions_car,
                                      size: 50,
                                      color: Colors.blueGrey,
                                    ),
                                  ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Tersedia',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['name'] ?? 'Tanpa Nama',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Harga Sewa',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    priceVal == 0
                                        ? 'Gratis'
                                        : formatCurrency.format(priceVal),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).primaryColor,
                                          Theme.of(
                                            context,
                                          ).primaryColor.withAlpha(200),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Detail',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
