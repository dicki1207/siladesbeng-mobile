import 'dart:io';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'package:siladesbeng_mobile/features/auth/login_page.dart'; // Import Full Screen Login Page
import 'package:siladesbeng_mobile/features/notification/notification_page.dart';
import 'package:siladesbeng_mobile/features/rental/tool_package_booking_page.dart';
import 'package:siladesbeng_mobile/features/gas/gas_page.dart';
import 'package:siladesbeng_mobile/features/report/report_page.dart';
import 'package:siladesbeng_mobile/features/rental/facility_rental_page.dart';
import 'package:siladesbeng_mobile/features/rental/car_rental_page.dart';
import 'package:siladesbeng_mobile/features/news/news_detail_page.dart';
import 'package:siladesbeng_mobile/features/home/search_page.dart';
import 'package:siladesbeng_mobile/features/home/all_services_page.dart';
import 'package:siladesbeng_mobile/features/assistant/assistant_page.dart';
import 'package:siladesbeng_mobile/widgets/premium_header.dart';
import 'package:siladesbeng_mobile/features/store/store_page.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onNavigateToProfile;
  final VoidCallback onNavigateToNews;

  const HomePage({super.key, required this.onNavigateToProfile, required this.onNavigateToNews});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _banners = [];
  List<dynamic> _announcements = [];
  List<dynamic> _unitPelayanan = [];
  List<dynamic> _availableServices = [];
  List<Map<String, dynamic>> _pasarDaerahProducts = [];
  bool _isLoading = true;
  double _assistantX = -1;
  double _assistantY = -1;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _unitPelayanan = _getDefaultUnitPelayanan();
    _fetchPublicData();
  }

  List<Map<String, String>> _getDefaultUnitPelayanan() {
    return [
      {
        'action': 'Toko BUMDes',
        'imageUrl': 'assets/images/PasarDaerah.png',
        'color': 'teal',
        'title': 'Pasar Daerah',
      },
      {
        'action': 'Beli Gas',
        'imageUrl': 'assets/images/F2.png',
        'color': 'green',
        'title': 'Pembelian Gas',
      },
      {
        'action': 'Buat Laporan',
        'imageUrl': 'assets/images/lapor.png',
        'color': 'red',
        'title': 'Pelaporan',
      },
      {
        'action': 'Sewa Alat',
        'imageUrl': 'assets/images/F1.png',
        'color': 'orange',
        'title': 'Penyewaan Alat',
      },
      {
        'action': 'Sewa Mobil',
        'imageUrl': 'assets/images/mobil.png',
        'color': 'blue',
        'title': 'Penyewaan Kendaraan',
      },
      {
        'action': 'Sewa Fasilitas',
        'imageUrl': 'assets/images/fasilitas.png',
        'color': 'purple',
        'title': 'Fasilitas Umum',
      },
    ];
  }

  Widget _buildElementImage(String path, {double? width, double? height, BoxFit fit = BoxFit.contain}) {
    String cleanPath = path;
    if (path.contains('F2.png')) {
      cleanPath = 'assets/images/F2.png';
    } else if (path.contains('lapor.png')) {
      cleanPath = 'assets/images/lapor.png';
    } else if (path.contains('F1.png') || path.contains('alat.png')) {
      cleanPath = 'assets/images/F1.png';
    } else if (path.contains('mobil.png')) {
      cleanPath = 'assets/images/mobil.png';
    } else if (path.contains('fasilitas.png')) {
      cleanPath = 'assets/images/fasilitas.png';
    }

    if (cleanPath.startsWith('assets/')) {
      return Image.asset(
        cleanPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (c, e, s) => Icon(Icons.miscellaneous_services, size: width != null ? width * 0.7 : 40, color: Colors.blue),
      );
    }
    return Image.network(
      cleanPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (c, e, s) => Icon(Icons.broken_image, size: width != null ? width * 0.7 : 40, color: Colors.grey.withAlpha(100)),
    );
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {});
  }

  Future<void> _fetchPublicData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final headers = token != null ? {'Authorization': 'Bearer $token'} : null;

      // Gunakan timeout cepat (2.5 detik) agar tidak lama berputar (loading)
      final timeoutDuration = const Duration(milliseconds: 2500);

      final results = await Future.wait([
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/banners')).timeout(timeoutDuration, onTimeout: () => http.Response('{"error": "timeout"}', 408)),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/announcements')).timeout(timeoutDuration, onTimeout: () => http.Response('{"error": "timeout"}', 408)),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/services')).timeout(timeoutDuration, onTimeout: () => http.Response('{"error": "timeout"}', 408)),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/unit-pelayanan'), headers: headers).timeout(timeoutDuration, onTimeout: () => http.Response('{"error": "timeout"}', 408)),
        http.get(Uri.parse('${ApiConfig.baseUrl}/api/pasar-daerah/products')).timeout(timeoutDuration, onTimeout: () => http.Response('{"error": "timeout"}', 408)),
      ]);

      final bannerRes = results[0];
      final annRes = results[1];
      final servicesRes = results[2];
      final unitRes = results[3];
      final pasarDaerahRes = results[4];

      if (!mounted) return;

      setState(() {
        // Parse Banner tanpa mencetak error HTML mentah Laravel ke layar
        if (bannerRes.statusCode == 200 && bannerRes.body.trim().startsWith('{')) {
          try {
            final List rawBanners = json.decode(bannerRes.body)['data'] ?? [];
            _banners = rawBanners.map((item) {
              if (item is Map<String, dynamic> && item['image_url'] != null) {
                String imgUrl = item['image_url'].toString();
                imgUrl = imgUrl.replaceAll('http://localhost:8000', ApiConfig.baseUrl);
                imgUrl = imgUrl.replaceAll('http://localhost', ApiConfig.baseUrl);
                imgUrl = imgUrl.replaceAll('http://127.0.0.1:8000', ApiConfig.baseUrl);
                imgUrl = imgUrl.replaceAll('http://127.0.0.1', ApiConfig.baseUrl);
                item['image_url'] = imgUrl;
              }
              return item;
            }).toList();
          } catch (_) {}
        }

        // Parse Announcement dengan fallback jika kosong atau timeout
        if (annRes.statusCode == 200 && annRes.body.trim().startsWith('{')) {
          try {
            final List data = json.decode(annRes.body)['data'] ?? [];
            if (data.isNotEmpty) {
              // Fix localhost URLs in image fields
              _announcements = data.map((item) {
                if (item is Map<String, dynamic> && item['image'] != null) {
                  String img = item['image'].toString();
                  img = img.replaceAll('http://localhost:8000', ApiConfig.baseUrl);
                  img = img.replaceAll('http://localhost', ApiConfig.baseUrl);
                  img = img.replaceAll('http://127.0.0.1:8000', ApiConfig.baseUrl);
                  img = img.replaceAll('http://127.0.0.1', ApiConfig.baseUrl);
                  item['image'] = img;
                }
                return item;
              }).toList();
            }
          } catch (_) {}
        }


        // Parse Services
        if (_announcements.isEmpty) {
          _announcements = [
            {
              'title': 'Bantuan Sosial 2026',
              'content': 'Penyaluran bantuan sosial desa bulan ini untuk seluruh RT/RW...',
            },
            {
              'title': 'Rapat Kerja Bakti Warga',
              'content': 'Diadakan di balai desa membahas kebersihan dan ketentraman...',
            },
          ];
        }

        // Parse Services
        if (servicesRes.statusCode == 200 && servicesRes.body.trim().startsWith('{')) {
          try {
            final List rawServices = json.decode(servicesRes.body)['data'] ?? [];
            // Fix localhost URLs in image fields
            _availableServices = rawServices.map((item) {
              if (item is Map<String, dynamic> && item['image'] != null) {
                String img = item['image'].toString();
                img = img.replaceAll('http://localhost:8000', ApiConfig.baseUrl);
                img = img.replaceAll('http://localhost', ApiConfig.baseUrl);
                img = img.replaceAll('http://127.0.0.1:8000', ApiConfig.baseUrl);
                img = img.replaceAll('http://127.0.0.1', ApiConfig.baseUrl);
                item['image'] = img;
              }
              return item;
            }).toList();
          } catch (_) {}
        }

        // Parse Unit Pelayanan atau gunakan default
        if (unitRes.statusCode == 200 && unitRes.body.trim().startsWith('{')) {
          try {
            final List data = json.decode(unitRes.body)['data'] ?? [];
            if (data.length >= 4) {
              _unitPelayanan = data;
            } else {
              _unitPelayanan = _getDefaultUnitPelayanan();
            }
          } catch (_) {
            _unitPelayanan = _getDefaultUnitPelayanan();
          }
        } else {
          _unitPelayanan = _getDefaultUnitPelayanan();
        }

        // Parse Pasar Daerah
        if (pasarDaerahRes.statusCode == 200 && pasarDaerahRes.body.trim().startsWith('{')) {
          try {
            final Map<String, dynamic> data = json.decode(pasarDaerahRes.body);
            if (data['status'] == 'success') {
              _pasarDaerahProducts = List<Map<String, dynamic>>.from(data['data']);
            }
          } catch (e) {
            debugPrint('Error parsing Pasar Daerah API: $e');
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;

        if (_announcements.isEmpty) {
          _announcements = [
            {
              'title': 'Bantuan Sosial 2026',
              'content': 'Penyaluran bantuan sosial desa bulan ini...',
            },
            {
              'title': 'Rapat Warga',
              'content': 'Diadakan di balai desa membahas keamanan...',
            },
          ];
        }
        _unitPelayanan = _getDefaultUnitPelayanan();
      });
      // Jangan tampilkan pesan error mentah ke layar user agar tetap mulus
    }
  }

  Future<void> _checkLoginAndProceed(String actionName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final isBlocked = prefs.getBool('is_blocked') ?? false;

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      if (isBlocked) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.block, color: Colors.red, size: 30),
                SizedBox(width: 10),
                Text(
                  'Akses Dibatasi!',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Anda terdeteksi telah pindah domisili, silakan ajukan mutasi terlebih dahulu.',
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onNavigateToProfile();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text(
                  'Ke Profil',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
        return;
      }

      if (actionName == 'Toko BUMDes') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StorePage()),
        );
      } else if (actionName == 'Sewa Alat') {
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
      } else if (actionName == 'Sewa Mobil' || actionName == 'Sewa Kendaraan' || actionName == 'Penyewaan Kendaraan' || actionName == 'Ambulans & Bus') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CarRentalPage(),
          ),
        );
      } else if (actionName == 'Sewa Fasilitas' || actionName == 'Fasilitas Umum') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const FacilityRentalPage(initialTabIndex: 0),
          ),
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
      ).then((success) {
        if (success == true) {
          _fetchPublicData(); // Refresh UI after successful login
        }
      });
    }
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 11) {
      return 'Selamat Pagi';
    } else if (hour < 15) {
      return 'Selamat Siang';
    } else if (hour < 18) {
      return 'Selamat Sore';
    } else {
      return 'Selamat Malam';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (_assistantX == -1) {
            _assistantX = constraints.maxWidth - 100; // default right side
            _assistantY =
                constraints.maxHeight -
                180; // Keep it well above the bottom navigation bar
          }
          return Stack(
            children: [
              SafeArea(
                top: false, // Let PremiumHeader handle the top padding
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _fetchPublicData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PremiumHeader(
                                bottomPadding: 12.0,
                                child: Column(
                                  children: [
                                    _buildTopProfile(),
                                    _buildSearchBar(),
                                  ],
                                ),
                              ),
                              _buildHeroBanner(),
                              _buildUnitPelayanan(),
                              _buildBumdesStoreMini(),
                              _buildAvailableServices(),
                              _buildKabarDaerah(),
                              const SizedBox(height: 120), // Spacing leluasa untuk clearing bottom nav & assistant
                            ],
                          ),
                        ),
                      ),
              ),

              // Floating Tanya Assistant (Draggable)
              Positioned(
                left: _assistantX,
                top: _assistantY,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _assistantX += details.delta.dx;
                      _assistantY += details.delta.dy;

                      // Clamp to screen bounds
                      if (_assistantX < 0) {
                        _assistantX = 0;
                      }
                      if (_assistantX > constraints.maxWidth - 60) {
                        _assistantX = constraints.maxWidth - 60;
                      }
                      if (_assistantY < 0) {
                        _assistantY = 0;
                      }
                      // Prevent it from hiding behind the footer/bottom nav (approx 180px reserved)
                      if (_assistantY > constraints.maxHeight - 180) {
                        _assistantY = constraints.maxHeight - 180;
                      }
                    });
                  },
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AssistantPage(),
                      ),
                    );
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Text Bubble outside the icon bounds
                      Positioned(
                        bottom: 65,
                        right: (_assistantX > constraints.maxWidth / 2)
                            ? 0
                            : null,
                        left: (_assistantX <= constraints.maxWidth / 2)
                            ? 0
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: DefaultTextStyle(
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            child: AnimatedTextKit(
                              animatedTexts: [
                                TypewriterAnimatedText(
                                  'Tanya Asisten',
                                  speed: const Duration(milliseconds: 100),
                                ),
                              ],
                              repeatForever: true,
                              pause: const Duration(milliseconds: 2000),
                              displayFullTextOnTap: true,
                              stopPauseOnTap: true,
                            ),
                          ),
                        ),
                      ),
                      // Icon Stack
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                '${ApiConfig.baseUrl}/User/img/logo/logocb.webp',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.smart_toy,
                                  size: 50,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFEF4444,
                                ), // Red badge color
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Text(
                                '1',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopProfile() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FutureBuilder<SharedPreferences>(
        future: SharedPreferences.getInstance(),
        builder: (context, snapshot) {
          String name = 'Tamu';
          String? imagePath;
          String? imageUrl;
          bool isLoggedIn = false;
          if (snapshot.hasData) {
            final prefs = snapshot.data!;
            isLoggedIn = prefs.getString('auth_token') != null;
            if (isLoggedIn) {
              name = prefs.getString('profile_name') ?? 'Pengguna';
              imagePath = prefs.getString('profile_image');
              imageUrl = prefs.getString('profile_image_url');
            }
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: widget.onNavigateToProfile,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withAlpha(80), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white24,
                    child: ClipOval(
                      child: (isLoggedIn && imagePath != null)
                          ? Image.file(
                              File(imagePath),
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 22,
                              ),
                            )
                          : (isLoggedIn && imageUrl != null)
                          ? Image.network(
                              imageUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 22,
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${_getGreeting()}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationPage(),
                    ),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withAlpha(45),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    Positioned(
                      top: 1,
                      right: 1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF2563EB),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFallbackBanner() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
              : [Theme.of(context).primaryColor, const Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.account_balance_rounded,
              size: 130,
              color: Colors.white.withAlpha(30),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PORTAL LAYANAN DESA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sila DesBeng Digital',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Pelayanan administrasi cepat, transparan & terpadu.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.only(
        top: 8,
        bottom: 4,
      ),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 140.0,
          autoPlay: true,
          enlargeCenterPage: true,
          viewportFraction: 0.9,
          aspectRatio: 2.3,
        ),
        items: _banners.isEmpty
            ? [
                _isLoading
                    ? Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey.withAlpha(40),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 3),
                        ),
                      )
                    : _buildFallbackBanner(),
              ]
            : _banners.map((banner) {
                final imageUrl = banner['image_url'] != null
                    ? banner['image_url'].toString()
                    : banner['image'] != null 
                        ? '${ApiConfig.baseUrl}/storage/${banner['image']}' 
                        : '';

                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey.withAlpha(40),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => _buildFallbackBanner(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withAlpha(50),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
        ),
        cursorColor: Colors.white,
        onSubmitted: (value) {
          _performSearch(value);
        },
        decoration: InputDecoration(
          hintText: 'Cari layanan desa, pasar, kabar...',
          hintStyle: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 12,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withAlpha(200),
            size: 18,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Colors.white70, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
      ),
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    // Sembunyikan keyboard
    FocusScope.of(context).unfocus();

    // Navigasi ke Halaman Pencarian Global
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchPage(
          initialQuery: query,
          unitPelayanan: _unitPelayanan,
          announcements: _announcements,
          banners: _banners,
          services: _availableServices,
        ),
      ),
    );

    // Kosongkan search bar di home setelah navigasi
    _searchController.clear();
  }

  Widget _buildUnitPelayanan() {
    // Data Unit Pelayanan diambil dari API di _unitPelayanan
    if (_unitPelayanan.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 30),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: const EdgeInsets.only(
        top: 10,
      ), // Jarak atas diperkecil agar lebih dekat dengan banner
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
            ), // Samakan margin dengan elemen lain
            child: Row(
              children: [
                Icon(
                  Icons.dashboard_rounded,
                  color: Theme.of(context).primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Unit Pelayanan',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.75,
              ),
              itemCount: _unitPelayanan.length,
              itemBuilder: (context, index) {
                final item = _unitPelayanan[index];
                Color cardColor = Colors.grey;
                if (item['color'] == 'blue') cardColor = Colors.blueAccent;
                if (item['color'] == 'orange') cardColor = Colors.orangeAccent;
                if (item['color'] == 'red') cardColor = Colors.redAccent;
                if (item['color'] == 'green') cardColor = Colors.green;
                if (item['color'] == 'purple') cardColor = Colors.purple;

                String imgPath = item['imageUrl']?.toString() ?? '';
                String fallbackAsset = 'assets/images/F2.png';
                final titleLower =
                    (item['title'] ?? '').toString().toLowerCase();
                if (titleLower.contains('gas') || imgPath.contains('F2')) {
                  fallbackAsset = 'assets/images/F2.png';
                } else if (titleLower.contains('lapor') ||
                    imgPath.contains('lapor')) {
                  fallbackAsset = 'assets/images/lapor.png';
                } else if (titleLower.contains('alat') ||
                    imgPath.contains('F1')) {
                  fallbackAsset = 'assets/images/F1.png';
                } else if (titleLower.contains('ambulans') ||
                    titleLower.contains('mobil') ||
                    imgPath.contains('mobil')) {
                  fallbackAsset = 'assets/images/mobil.png';
                } else if (titleLower.contains('fasilitas') ||
                    titleLower.contains('gedung') ||
                    imgPath.contains('fasilitas')) {
                  fallbackAsset = 'assets/images/fasilitas.png';
                }

                return GestureDetector(
                  onTap: () => _checkLoginAndProceed(item['action']),
                  child: Column(
                    children: [
                      Container(
                        height: 56,
                        width: 56,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cardColor.withAlpha(50)),
                        ),
                        child: imgPath.startsWith('http')
                            ? Image.network(
                                imgPath,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => Image.asset(
                                  fallbackAsset,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) =>
                                      Icon(Icons.apps, color: cardColor),
                                ),
                              )
                            : Image.asset(
                                imgPath,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => Image.asset(
                                  fallbackAsset,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) =>
                                      Icon(Icons.apps, color: cardColor),
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['title'],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBumdesStoreMini() {

    // We no longer use mock products here, we use _pasarDaerahProducts.
    // If it's empty, we won't show the horizontal list.
    if (_pasarDaerahProducts.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.storefront,
                      color: Theme.of(context).primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pasar Daerah',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    _checkLoginAndProceed('Toko BUMDes');
                  },
                  child: Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _pasarDaerahProducts.length > 5 ? 5 : _pasarDaerahProducts.length,
              itemBuilder: (context, index) {
                final product = _pasarDaerahProducts[index];
                
                String name = product['nama_produk'] ?? 'Tanpa Nama';
                dynamic rawPrice = product['harga'] ?? 0;
                double price = (rawPrice is String) ? (double.tryParse(rawPrice) ?? 0) : (rawPrice as num).toDouble();
                String imageUrl = product['image_url'] ?? '';

                return GestureDetector(
                  onTap: () => _checkLoginAndProceed('Toko BUMDes'),
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Expanded(
                          flex: 5,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: imageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    child: Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.handyman, color: Colors.grey),
                                    ),
                                  )
                                : const Icon(Icons.handyman, color: Colors.grey),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0).format(price),
                                  style: const TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableServices() {
    if (_availableServices.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Layanan Tersedia',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllServicesPage(
                          initialServices: _availableServices,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _availableServices.length,
              itemBuilder: (context, index) {
                final item = _availableServices[index];
                return _buildServiceCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> item) {
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
        width: 150,
        margin: const EdgeInsets.only(right: 12, bottom: 8),
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
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Container(
                    height: 100,
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: _buildElementImage(
                      item['image'] ?? '',
                      fit: BoxFit.contain,
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
            // Details Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    priceVal == 0 ? 'Gratis' : formatCurrency.format(priceVal),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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

  Widget _buildKabarDaerah() {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kabar dan Informasi Daerah',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pengumuman dan agenda terbaru',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  widget.onNavigateToNews();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Semua',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 10,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: _announcements.isEmpty
                ? const Center(child: Text("Tidak ada data terbaru"))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _announcements.length,
                    itemBuilder: (context, index) {
                      final ann = _announcements[index];
                      return GestureDetector(
                        onTap: () {
                          if (ann['title'] == 'Tidak ada pengumuman') return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewsDetailPage(newsItem: ann),
                            ),
                          );
                        },
                        child: _buildTerbaruCard(
                          ann['title']?.toString() ?? 'Tidak ada judul',
                          ann['image']?.toString() ?? 'https://cdn-icons-png.flaticon.com/512/3176/3176298.png',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerbaruCard(String title, String imageUrl) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: _buildElementImage(imageUrl, width: double.infinity, height: 120, fit: BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hari ini',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium!.copyWith(fontSize: 10),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'Baru',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium!.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
