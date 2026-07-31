import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:siladesbeng_mobile/core/theme.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'gas_booking_page.dart';
import '../rental/item_detail_page.dart';

class GasPage extends StatefulWidget {
  const GasPage({super.key});

  @override
  State<GasPage> createState() => _GasPageState();
}

class _GasPageState extends State<GasPage> {
  List<dynamic> _gasItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGas();
  }

  List<Map<String, dynamic>> _getMockGas() {
    return [
      {
        'id': 1,
        'name': 'Gas Melon 3kg',
        'price': 20000,
        'image': 'assets/images/F2.png',
        'description':
            'Gas LPG subsidi ukuran 3kg untuk keperluan rumah tangga. Harga sudah termasuk ongkos kirim standar ke seluruh wilayah desa.',
      },
      {
        'id': 2,
        'name': 'Bright Gas 5.5kg',
        'price': 105000,
        'image': 'assets/images/F2.png',
        'description':
            'Gas LPG Non-Subsidi ukuran 5.5kg dengan teknologi katup ganda, lebih aman dan praktis untuk dapur modern.',
      },
      {
        'id': 3,
        'name': 'Elpiji 12kg',
        'price': 225000,
        'image': 'assets/images/F2.png',
        'description':
            'Tabung gas ukuran besar 12kg, sangat cocok untuk usaha kuliner, restoran, atau keluarga besar.',
      },
    ];
  }

  Future<void> _fetchGas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (mounted) {
          setState(() {
            _gasItems = _getMockGas();
            _isLoading = false;
          });
        }
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.193.206.148:8000/api/gas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (!mounted) return;
          setState(() {
            _gasItems = (data['data'] as List).isNotEmpty
                ? data['data']
                : _getMockGas();
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Gagal mengambil data gas: $e");
    }

    if (!mounted) return;
    setState(() {
      _gasItems = _getMockGas();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(
            height: 400,
            decoration: BoxDecoration(gradient: AppTheme.getGradient(context)),
          ),
          RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _isLoading = true;
              });
              await _fetchGas();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  floating: true,
                  pinned: false,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  title: Text(
                    'Layanan Gas LPG',
                    style: TextStyle(
                      color: (Theme.of(context).textTheme.bodyLarge?.color),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  centerTitle: true,
                  iconTheme: IconThemeData(
                    color: (Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24.0,
                  ),
                  sliver: _isLoading
                      ? const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 50),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF0EA5E9),
                              ),
                            ),
                          ),
                        )
                      : _gasItems.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState())
                      : SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16.0,
                                mainAxisSpacing: 16.0,
                                childAspectRatio: 0.55,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            BuildContext context,
                            int index,
                          ) {
                            return _buildPremiumGasCard(_gasItems[index]);
                          }, childCount: _gasItems.length),
                        ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumGasCard(dynamic item) {
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

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withAlpha(15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ItemDetailPage(
                item: item,
                category: 'Beli Gas',
                bookingPage: GasBookingPage(item: item),
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gambar Section dengan Background Lembut
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Hero(
                  tag: 'gas_img_${item['name']}',
                  child: (item['image'].toString().startsWith('assets/') || item['image'].toString().contains('F2.png'))
                      ? Image.asset(
                          'assets/images/F2.png',
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.propane_tank,
                            color: Colors.grey,
                            size: 50,
                          ),
                        )
                      : Image.network(
                          item['image'],
                          fit: BoxFit.contain, // Mencegah terpotong
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.propane_tank,
                            color: Colors.grey,
                            size: 50,
                          ),
                        ),
                ),
              ),
            ),
            // Detail Section
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).textTheme.bodyLarge?.color ??
                                const Color(0xFF1E293B),
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF10B981).withAlpha(50),
                            ),
                          ),
                          child: Text(
                            formatCurrency.format(priceVal),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Tombol Beli Premium
                    Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withAlpha(60),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemDetailPage(
                                item: item,
                                category: 'Beli Gas',
                                bookingPage: GasBookingPage(item: item),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Pesan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0EA5E9).withAlpha(30),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 80,
                color: Color(0xFF0EA5E9),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Stok Gas Sedang Kosong",
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color:
                    Theme.of(context).textTheme.bodyLarge?.color ??
                    const Color(0xFF0284C7),
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Mohon maaf, stok LPG saat ini habis. Silakan cek kembali nanti atau hubungi BUMDes.",
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
