import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/features/auth/login_page.dart';

class AllServicesPage extends StatefulWidget {
  final List<dynamic> initialServices;

  const AllServicesPage({super.key, required this.initialServices});

  @override
  State<AllServicesPage> createState() => _AllServicesPageState();
}

class _AllServicesPageState extends State<AllServicesPage> {
  List<dynamic> _services = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialServices.isNotEmpty) {
      _services = widget.initialServices;
    } else {
      _fetchServices();
    }
  }

  Future<void> _fetchServices() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(
        Uri.parse('http://10.193.206.148:8000/api/services'),
      ).timeout(const Duration(milliseconds: 2000));
      if (res.statusCode == 200 && res.body.trim().startsWith('{')) {
        if (!mounted) return;
        setState(() {
          _services = json.decode(res.body)['data'] ?? [];
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkLoginAndProceed(String routeName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      Navigator.pop(context, routeName);
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

  Widget _buildPremiumServiceCard(Map<String, dynamic> item) {
    Color typeColor;
    String typeLabel;

    switch (item['type']) {
      case 'gas':
        typeColor = Colors.green;
        typeLabel = 'Gas';
        break;
      case 'mobil':
        typeColor = Colors.blue;
        typeLabel = 'Mobil';
        break;
      case 'fasilitas':
        typeColor = Colors.purple;
        typeLabel = 'Fasilitas';
        break;
      case 'rental':
      default:
        typeColor = Colors.orange;
        typeLabel = 'Sewa Alat';
        break;
    }

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

    return GestureDetector(
      onTap: () {
        if (item['type'] == 'gas') {
          _checkLoginAndProceed('Beli Gas');
        } else if (item['type'] == 'mobil') {
          _checkLoginAndProceed('Sewa Mobil');
        } else if (item['type'] == 'fasilitas') {
          _checkLoginAndProceed('Sewa Fasilitas');
        } else {
          _checkLoginAndProceed('Sewa Alat');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(12),
                    child: Image.network(
                      item['image'] ?? '',
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Icon(
                        Icons.broken_image,
                        color: Colors.grey.withAlpha(100),
                        size: 40,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withAlpha(200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      typeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['name'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      priceVal == 0
                          ? 'Gratis'
                          : formatCurrency.format(priceVal),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).cardColor,
        title: const Text(
          'Semua Layanan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
          ? const Center(child: Text('Tidak ada layanan tersedia.'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.65,
              ),
              itemCount: _services.length,
              itemBuilder: (context, index) {
                return _buildPremiumServiceCard(_services[index]);
              },
            ),
    );
  }
}
