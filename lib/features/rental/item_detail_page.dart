import 'package:flutter/material.dart';
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
    final title = item['name'] ?? item['title'] ?? 'Tanpa Nama';
    final price = item['price'] ?? 0;
    final description =
        item['description'] ??
        'Deskripsi detail untuk $title belum tersedia. Silakan hubungi admin untuk informasi lebih lanjut.';
    String imageUrl =
        item['image_url'] ??
        item['image'] ??
        'assets/images/mobil.png';
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

    // Spesifikasi mock berdasarkan kategori
    Map<String, String> specs = {};
    if (category == 'Sewa Mobil') {
      specs = {
        'Kapasitas': '7 Penumpang',
        'Transmisi': 'Otomatis / Manual',
        'Bahan Bakar': 'Bensin',
        'Tahun': '2022/2023',
      };
    } else if (category == 'Fasilitas Umum') {
      specs = {
        'Kapasitas': '100 - 500 Orang',
        'Luas Area': '200 m²',
        'Toilet': 'Tersedia',
        'Parkir': 'Luas',
      };
    } else if (category == 'Sewa Alat') {
      specs = {
        'Kondisi': 'Baik / Terawat',
        'Durasi Min': '1 Hari',
        'Pengantaran': 'Tersedia',
      };
    } else if (category == 'Beli Gas') {
      specs = {
        'Berat Bersih': item['berat'] ?? '3 kg',
        'Kondisi Tabung': 'Tersegel Resmi',
        'Ketersediaan': 'Ready Stock',
        'Pengantaran': 'Langsung Antar',
      };
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'image_${item['id'] ?? title}',
                child: imageUrl.startsWith('assets/')
                    ? Image.asset(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image,
                            size: 100,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.image,
                            size: 100,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Judul dan Harga
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(price) +
                        (category.contains('Sewa') ? ' / Hari' : ''),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Spesifikasi
                  const Text(
                    'Spesifikasi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.0,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    itemCount: specs.length,
                    itemBuilder: (context, index) {
                      String key = specs.keys.elementAt(index);
                      String value = specs.values.elementAt(index);
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              key,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              value,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  // Deskripsi
                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 100), // Spacing for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 450),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Pesan Sekarang',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
