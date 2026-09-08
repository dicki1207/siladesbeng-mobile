import 'package:flutter/material.dart';
import 'package:siladesbeng_mobile/widgets/custom_cached_image.dart';
import 'package:siladesbeng_mobile/widgets/premium_header.dart';
import 'package:siladesbeng_mobile/features/store/store_page.dart';
import 'package:siladesbeng_mobile/features/news/news_detail_page.dart';
import 'package:siladesbeng_mobile/features/gas/gas_page.dart';
import 'package:siladesbeng_mobile/features/report/report_page.dart';
import 'package:siladesbeng_mobile/features/rental/car_rental_page.dart';
import 'package:siladesbeng_mobile/features/rental/facility_rental_page.dart';
import 'package:siladesbeng_mobile/features/rental/tool_package_booking_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/features/auth/login_page.dart';
import 'package:intl/intl.dart';

class SearchPage extends StatefulWidget {
  final String initialQuery;
  final List unitPelayanan;
  final List announcements;
  final List banners;
  final List services;

  const SearchPage({
    super.key,
    required this.initialQuery,
    required this.unitPelayanan,
    required this.announcements,
    required this.banners,
    required this.services,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController _searchController;
  String _query = '';

  List _filteredUnits = [];
  List _filteredAnnouncements = [];
  List _filteredBanners = [];
  List _filteredServices = [];

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _searchController = TextEditingController(text: _query);
    _performFilter(_query);
  }

  void _performFilter(String query) {
    setState(() {
      _query = query.toLowerCase();
      if (_query.isEmpty) {
        _filteredUnits = [];
        _filteredAnnouncements = [];
        _filteredBanners = [];
        return;
      }

      _filteredUnits = widget.unitPelayanan.where((item) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        final action = (item['action'] ?? '').toString().toLowerCase();
        return title.contains(_query) || action.contains(_query);
      }).toList();

      _filteredAnnouncements = widget.announcements.where((item) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        final content = (item['content'] ?? '').toString().toLowerCase();
        return title.contains(_query) || content.contains(_query);
      }).toList();

      _filteredBanners = widget.banners.where((item) {
        final title = (item['title'] ?? '').toString().toLowerCase();
        final subtitle = (item['subtitle'] ?? '').toString().toLowerCase();
        return title.contains(_query) || subtitle.contains(_query);
      }).toList();

      _filteredServices = widget.services.where((item) {
        final title = (item['name'] ?? '').toString().toLowerCase();
        return title.contains(_query);
      }).toList();
    });
  }

  String _formatCurrency(dynamic price) {
    if (price == null) return 'Gratis';
    double priceVal = 0;
    if (price is String) {
      priceVal = double.tryParse(price) ?? 0;
    } else if (price is num) {
      priceVal = price.toDouble();
    }
    if (priceVal == 0) return 'Gratis';
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(priceVal);
  }

  Future<void> _handleUnitTap(String actionName) async {
    // Akses publik untuk Pasar Daerah (Toko BUMDes)
    if (actionName == 'Toko BUMDes' || actionName.toLowerCase().contains('pasar')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StorePage()),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      if (actionName == 'Sewa Alat') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ToolPackageBookingPage()),
        );
      } else if (actionName == 'Beli Gas') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GasPage()),
        );
      } else if (actionName == 'Buat Laporan' || actionName == 'Pelaporan') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportPage()),
        );
      } else if (actionName == 'Sewa Mobil') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CarRentalPage()),
        );
      } else if (actionName == 'Sewa Fasilitas') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FacilityRentalPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Halaman $actionName belum tersedia.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login terlebih dahulu!')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  Widget _buildUnitIcon(dynamic item) {
    final title = (item['title'] ?? '').toString().toLowerCase();
    final action = (item['action'] ?? '').toString().toLowerCase();
    final imgUrl = (item['imageUrl'] ?? item['image'] ?? '').toString();

    String fallbackAsset = 'assets/images/PasarDaerah.png';
    if (title.contains('pasar') || action.contains('toko') || imgUrl.contains('PasarDaerah')) {
      fallbackAsset = 'assets/images/PasarDaerah.png';
    } else if (title.contains('gas') || action.contains('gas') || imgUrl.contains('F2')) {
      fallbackAsset = 'assets/images/F2.png';
    } else if (title.contains('lapor') || action.contains('lapor')) {
      fallbackAsset = 'assets/images/lapor.png';
    } else if (title.contains('alat') || action.contains('alat') || imgUrl.contains('F1')) {
      fallbackAsset = 'assets/images/F1.png';
    } else if (title.contains('mobil') || action.contains('mobil')) {
      fallbackAsset = 'assets/images/mobil.png';
    } else if (title.contains('fasilitas') || action.contains('fasilitas')) {
      fallbackAsset = 'assets/images/fasilitas.png';
    }

    if (imgUrl.startsWith('http')) {
      return CustomCachedImage(
        imgUrl,
        width: 32,
        height: 32,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) => Image.asset(fallbackAsset, width: 32, height: 32, fit: BoxFit.contain),
      );
    }
    return Image.asset(fallbackAsset, width: 32, height: 32, fit: BoxFit.contain);
  }

  Widget _buildServiceImage(dynamic item) {
    final name = (item['name'] ?? '').toString().toLowerCase();
    final type = (item['type'] ?? '').toString().toLowerCase();
    final imgUrl = (item['image'] ?? '').toString();

    String? fallbackAsset;
    if (name.contains('gas') || type == 'gas' || imgUrl.contains('gas') || imgUrl.contains('F2')) {
      fallbackAsset = 'assets/images/F2.png';
    } else if (name.contains('mobil') || type == 'mobil' || imgUrl.contains('mobil')) {
      fallbackAsset = 'assets/images/mobil.png';
    } else if (name.contains('fasilitas') || type == 'fasilitas' || imgUrl.contains('fasilitas')) {
      fallbackAsset = 'assets/images/fasilitas.png';
    } else if (name.contains('alat') || type == 'alat' || imgUrl.contains('F1')) {
      fallbackAsset = 'assets/images/F1.png';
    }

    if (imgUrl.isNotEmpty && imgUrl.startsWith('http')) {
      return CustomCachedImage(
        imgUrl,
        width: 60,
        height: 60,
        fit: BoxFit.contain,
        errorBuilder: (c, e, s) {
          if (fallbackAsset != null) {
            return Image.asset(fallbackAsset, width: 60, height: 60, fit: BoxFit.contain);
          }
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withAlpha(15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF0284C7), size: 28),
          );
        },
      );
    }

    if (fallbackAsset != null) {
      return Image.asset(fallbackAsset, width: 60, height: 60, fit: BoxFit.contain);
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7).withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF0284C7), size: 28),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildResultSection(
    String title,
    IconData icon,
    List data,
    Widget Function(dynamic item) itemBuilder,
  ) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${data.length}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: data.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) => itemBuilder(data[index]),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasResults =
        _filteredUnits.isNotEmpty ||
        _filteredAnnouncements.isNotEmpty ||
        _filteredBanners.isNotEmpty ||
        _filteredServices.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Blue Premium Header with clean white search bar
          PremiumHeader(
            bottomPadding: 16,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: _performFilter,
                      textAlignVertical: TextAlignVertical.center,
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: const Color(0xFF0284C7),
                      decoration: InputDecoration(
                        hintText: 'Cari layanan, pasar, kabar...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13.5,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF0284C7),
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  color: Colors.grey,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _performFilter('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_rounded, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Ketik untuk mulai mencari',
                          style: TextStyle(color: Colors.grey[500], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : !hasResults
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada hasil untuk "$_query"',
                          style: TextStyle(color: Colors.grey[500], fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        _buildResultSection(
                          'Unit Pelayanan',
                          Icons.widgets_rounded,
                          _filteredUnits,
                          (item) => InkWell(
                            onTap: () => _handleUnitTap(item['action'] ?? ''),
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: _buildUnitIcon(item),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Text(
                                      item['title'] ?? 'Layanan',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _buildResultSection(
                          'Layanan Tersedia',
                          Icons.shopping_bag_rounded,
                          _filteredServices,
                          (item) => InkWell(
                            onTap: () {
                              String actionName = 'Sewa Alat';
                              if (item['type'] == 'gas') {
                                actionName = 'Beli Gas';
                              } else if (item['type'] == 'mobil') {
                                actionName = 'Sewa Mobil';
                              } else if (item['type'] == 'fasilitas') {
                                actionName = 'Sewa Fasilitas';
                              }
                              _handleUnitTap(actionName);
                            },
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _buildServiceImage(item),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'] ?? 'Layanan',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatCurrency(item['price']),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  _buildResultSection(
                    'Berita & Informasi',
                    Icons.article_rounded,
                    _filteredBanners,
                    (item) => InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NewsDetailPage(newsItem: item),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item['image'] != null
                                  ? CustomCachedImage(
                                      item['image'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[300],
                                      ),
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] ?? 'Berita',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['subtitle'] ?? 'Baca selengkapnya...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildResultSection(
                    'Pengumuman',
                    Icons.campaign_rounded,
                    _filteredAnnouncements,
                    (item) => Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.orangeAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.notifications_active,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] ?? 'Pengumuman',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['content'] ?? 'Isi pengumuman...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
