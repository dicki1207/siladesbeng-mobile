import 'dart:io';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
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
import 'package:siladesbeng_mobile/features/assistant/assistant_page.dart';
import 'package:siladesbeng_mobile/widgets/premium_header.dart';
import 'package:siladesbeng_mobile/features/store/store_page.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onNavigateToProfile;
  final VoidCallback onNavigateToNews;

  const HomePage({
    super.key,
    required this.onNavigateToProfile,
    required this.onNavigateToNews,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ShowcaseView _showcaseView;

  // Showcase Tour Keys
  final GlobalKey _keyNotif = GlobalKey();
  final GlobalKey _keySearch = GlobalKey();
  final GlobalKey _keyUnitPelayanan = GlobalKey();
  final GlobalKey _keyAsisten = GlobalKey();

  List<dynamic> _banners = [];
  List<dynamic> _announcements = [];
  List<dynamic> _unitPelayanan = [];
  List<dynamic> _availableServices = [];
  List<Map<String, dynamic>> _pasarDaerahProducts = [];
  // _isLoading removed — fallback data renders instantly
  double _assistantX = -1;
  double _assistantY = -1;
  final TextEditingController _searchController = TextEditingController();

  String _userName = 'Tamu';
  String? _userImagePath;
  String? _userImageUrl;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _showcaseView = ShowcaseView.register(scope: 'home');
    _unitPelayanan = _getDefaultUnitPelayanan();
    _pasarDaerahProducts = [];
    _announcements = [];
    _loadProfileData();
    _fetchPublicData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartShowcase(
);
    });
  }

  Future<void> _checkAndStartShowcase(
) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenTour = prefs.getBool('has_seen_home_tour') ?? false;
      if (!hasSeenTour && mounted) {
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          _showcaseView.startShowCase([
            _keySearch,
            _keyNotif,
            _keyUnitPelayanan,
            _keyAsisten,
          ]);
          await prefs.setBool('has_seen_home_tour', true);
        }
      }
    } catch (e) {
      debugPrint('Home showcase error: $e');
    }
  }

  void _replayHomeTour() {
    _showcaseView.startShowCase([
      _keySearch,
      _keyNotif,
      _keyUnitPelayanan,
      _keyAsisten,
    ]);
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final isLoggedIn = token != null;
    final name = isLoggedIn
        ? (prefs.getString('profile_name') ?? 'Pengguna')
        : 'Tamu';
    final imagePath = prefs.getString('profile_image');
    final imageUrl = prefs.getString('profile_image_url');
    if (mounted) {
      setState(() {
        _isLoggedIn = isLoggedIn;
        _userName = name;
        _userImagePath = imagePath;
        _userImageUrl = imageUrl;
      });
    }
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



  Widget _buildElementImage(
    String path, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
  }) {
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
        errorBuilder: (c, e, s) => Icon(
          Icons.miscellaneous_services,
          size: width != null ? width * 0.7 : 40,
          color: Colors.blue,
        ),
      );
    }
    return Image.network(
      cleanPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (c, e, s) => Icon(
        Icons.broken_image,
        size: width != null ? width * 0.7 : 40,
        color: Colors.grey.withAlpha(100),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadProfileData();
  }

  Future<void> _fetchPublicData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final headers = token != null ? {'Authorization': 'Bearer $token'} : null;

      // ==========================================
      // LOAD APIs INDEPENDENTLY (TIDAK SALING BLOCK)
      // ==========================================

      // 1. Fetch Banners
      http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/banners'))
          .then((res) {
            if (!mounted) return;
            if (res.statusCode == 200 && res.body.trim().startsWith('{')) {
              try {
                final List rawBanners = json.decode(res.body)['data'] ?? [];
                setState(() {
                  _banners = rawBanners.map((item) {
                    if (item is Map<String, dynamic> &&
                        item['image_url'] != null) {
                      String imgUrl = item['image_url'].toString();
                      imgUrl = imgUrl.replaceAll(
                        'http://localhost:8000',
                        ApiConfig.baseUrl,
                      );
                      imgUrl = imgUrl.replaceAll(
                        'http://localhost',
                        ApiConfig.baseUrl,
                      );
                      imgUrl = imgUrl.replaceAll(
                        'http://127.0.0.1:8000',
                        ApiConfig.baseUrl,
                      );
                      imgUrl = imgUrl.replaceAll(
                        'http://127.0.0.1',
                        ApiConfig.baseUrl,
                      );
                      item['image_url'] = imgUrl;
                    }
                    return item;
                  }).toList();
                });
              } catch (_) {}
            }
          })
          .catchError((_) {});

      // 2. Fetch Announcements
      http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/announcements'))
          .then((res) {
            if (!mounted) return;
            if (res.statusCode == 200 && res.body.trim().startsWith('{')) {
              try {
                final List data = json.decode(res.body)['data'] ?? [];
                if (data.isNotEmpty) {
                  final validData = data
                      .where((item) => !(item['title']?.toString().toLowerCase().contains('testing') ?? false))
                      .map((item) {
                    if (item is Map<String, dynamic> &&
                        item['image'] != null) {
                      String img = item['image'].toString();
                      img = img.replaceAll(
                        'http://localhost:8000',
                        ApiConfig.baseUrl,
                      );
                      img = img.replaceAll(
                        'http://localhost',
                        ApiConfig.baseUrl,
                      );
                      img = img.replaceAll(
                        'http://127.0.0.1:8000',
                        ApiConfig.baseUrl,
                      );
                      img = img.replaceAll(
                        'http://127.0.0.1',
                        ApiConfig.baseUrl,
                      );
                      item['image'] = img;
                    }
                    return item;
                  }).toList();
                    setState(() {
                    _announcements = validData;
                  });
                } else {
                  setState(() {
                    _announcements = [];
                  });
                }
              } catch (_) {
                setState(() {
                  _announcements = [];
                });
              }
            }
          })
          .catchError((_) {
            if (mounted) {
              setState(() {
                _announcements = [];
              });
            }
          });

      // 3. Fetch Services
      http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/services'))
          .then((res) {
            if (!mounted) return;
            if (res.statusCode == 200 && res.body.trim().startsWith('{')) {
              try {
                final List rawServices = json.decode(res.body)['data'] ?? [];
                setState(() {
                  _availableServices = rawServices.map((item) {
                    if (item is Map<String, dynamic> && item['image'] != null) {
                      String img = item['image'].toString();
                      img = img.replaceAll(
                        'http://localhost:8000',
                        ApiConfig.baseUrl,
                      );
                      img = img.replaceAll(
                        'http://localhost',
                        ApiConfig.baseUrl,
                      );
                      img = img.replaceAll(
                        'http://127.0.0.1:8000',
                        ApiConfig.baseUrl,
                      );
                      img = img.replaceAll(
                        'http://127.0.0.1',
                        ApiConfig.baseUrl,
                      );
                      item['image'] = img;
                    }
                    return item;
                  }).toList();
                });
              } catch (_) {}
            }
          })
          .catchError((_) {});

      // 4. Fetch Unit Pelayanan
      http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/unit-pelayanan'),
            headers: headers,
          )
          .then((res) {
            if (!mounted) return;
            if (res.statusCode == 200 && res.body.trim().startsWith('{')) {
              try {
                final List data = json.decode(res.body)['data'] ?? [];
                setState(() {
                  _unitPelayanan = data.length >= 4
                      ? data
                      : _getDefaultUnitPelayanan();
                });
              } catch (_) {
                setState(() => _unitPelayanan = _getDefaultUnitPelayanan());
              }
            } else {
              setState(() => _unitPelayanan = _getDefaultUnitPelayanan());
            }
          })
          .catchError((_) {
            if (mounted) {
              setState(() => _unitPelayanan = _getDefaultUnitPelayanan());
            }
          });

      // 5. Fetch Pasar Daerah
      http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/pasar-daerah/products'))
          .then((res) {
            if (!mounted) return;
            if (res.statusCode == 200 && res.body.trim().startsWith('{')) {
              try {
                final Map<String, dynamic> data = json.decode(res.body);
                if (data['status'] == 'success') {
                  final list = List<Map<String, dynamic>>.from(data['data'])
                      .where((item) => !(item['nama_produk']?.toString().toLowerCase().contains('seman') ?? false))
                      .toList();
                  setState(() {
                    _pasarDaerahProducts = list;
                  });
                }
              } catch (_) {
                setState(() {
                  _pasarDaerahProducts = [];
                });
              }
            }
          })
          .catchError((_) {
            if (mounted) {
              setState(() {
                _pasarDaerahProducts = [];
              });
            }
          });

      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _unitPelayanan = _getDefaultUnitPelayanan();
      });
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
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Row(
              children: [
                Icon(Icons.block, color: Colors.red, size: 30.sp),
                SizedBox(width: 10.w),
                Text(
                  'Akses Dibatasi!',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Text(
              'Anda terdeteksi telah pindah domisili, silakan ajukan mutasi terlebih dahulu.',
              style: TextStyle(fontSize: 15.sp),
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
      } else if (actionName == 'Sewa Mobil' ||
          actionName == 'Sewa Kendaraan' ||
          actionName == 'Penyewaan Kendaraan' ||
          actionName == 'Ambulans & Bus') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CarRentalPage()),
        );
      } else if (actionName == 'Sewa Fasilitas' ||
          actionName == 'Fasilitas Umum') {
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
    return 'Selamat Siang'; // Sementara untuk pengeditan poster
  }

  @override
  void dispose() {
    // _showcaseView.unregister(); // Prevent unregister on route replace race condition
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
                child: RefreshIndicator(
                  onRefresh: _fetchPublicData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PremiumHeader(
                          bottomPadding: 12.0,
                          child: Column(
                            children: [_buildTopProfile(), _buildSearchBar()],
                          ),
                        ),
                        _buildHeroBanner(),
                        _buildUnitPelayanan(),
                        _buildBumdesStoreMini(),
                        _buildKabarDaerah(),
                        const SizedBox(
                          height: 120,
                        ), // Spacing leluasa untuk clearing bottom nav & assistant
                      ],
                    ),
                  ),
                ),
              ),

              // Floating Tanya Assistant (Draggable)
              Positioned(
                left: _assistantX,
                top: _assistantY,
                child: Showcase(
                  titleTextStyle: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.2),
                  descTextStyle: TextStyle(fontSize: 12.0.sp, fontWeight: FontWeight.w400, color: Color(0xFF475569), height: 1.35),
                  key: _keyAsisten,
                  title: 'Tanya Asisten AI',
                  description: 'Butuh bantuan seputar layanan desa? Ketuk asisten pintar ini untuk bertanya apa saja.',
                  targetShapeBorder: const CircleBorder(),
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
                        bottom: 65.h,
                        right: (_assistantX > constraints.maxWidth / 2)
                            ? 0
                            : null,
                        left: (_assistantX <= constraints.maxWidth / 2)
                            ? 0
                            : null,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          child: DefaultTextStyle(
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
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
                            padding: EdgeInsets.all(4.w),
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
                                errorBuilder: (ctx, err, stack) => Icon(
                                  Icons.smart_toy,
                                  size: 50.sp,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: EdgeInsets.all(6.w),
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
                              child: Text(
                                '1',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
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
            ),
          ],
        );
      },
      ),
    );
  }

  Widget _buildTopProfile() {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onNavigateToProfile,
            child: Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withAlpha(80),
                  width: 1.5,
                ),
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
                  child: (_isLoggedIn && _userImagePath != null)
                      ? Image.file(
                          File(_userImagePath!),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 22.sp,
                          ),
                        )
                      : (_isLoggedIn && _userImageUrl != null)
                      ? Image.network(
                          _userImageUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 22.sp,
                          ),
                        )
                      : Icon(Icons.person, color: Colors.white, size: 22.sp),
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${_getGreeting()}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    fontSize: 11.5.sp,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  _userName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 15.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          Showcase(
            titleTextStyle: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.2),
            descTextStyle: TextStyle(fontSize: 12.0.sp, fontWeight: FontWeight.w400, color: Color(0xFF475569), height: 1.35),
            key: _keyNotif,
            title: 'Notifikasi & Info Masuk',
            description: 'Lihat info pengumuman desa, pembaruan laporan, dan status pesanan Pasar Daerah Anda di sini.',
            targetShapeBorder: const CircleBorder(),
            child: GestureDetector(
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
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(35),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withAlpha(45),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                  Positioned(
                    top: 1.h,
                    right: 1.w,
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
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: _replayHomeTour,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(35),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withAlpha(45),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.help_outline_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackBanner() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 5.0.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A8A), const Color(0xFF0F172A)]
              : [const Color(0xFF2FA2F1), const Color(0xFF0284C7)],
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
              size: 130.sp,
              color: Colors.white.withAlpha(30),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(18.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'PORTAL LAYANAN DESA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Sila DesBeng Digital',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  'Pelayanan administrasi cepat, transparan & terpadu.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: 12.sp,
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
    // 2 banner statis dari web (sama seperti beranda web)
    final List<String> staticBanners = [
      '${ApiConfig.baseUrl}/User/img/elemen/kuncislide1r.png',
      '${ApiConfig.baseUrl}/User/img/elemen/kuncislide2r.png',
    ];

    // Gabungkan: statis dulu, lalu dari API
    final List<Map<String, dynamic>> allBanners = [
      ...staticBanners.map((url) => {'image_url': url, 'is_static': true}),
      ..._banners,
    ];

    return Container(
      margin: EdgeInsets.only(top: 10.h, bottom: 6.h),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 168.0,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 4),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          autoPlayCurve: Curves.fastOutSlowIn,
          enlargeCenterPage: true,
          enlargeFactor: 0.18,
          viewportFraction: 0.94,
        ),
        items: allBanners.map((banner) {
          final imageUrl = banner['image_url'] != null
              ? banner['image_url'].toString()
              : banner['image'] != null
                  ? '${ApiConfig.baseUrl}/storage/${banner['image']}'
                  : '';

          return Builder(
            builder: (BuildContext context) {
              return Container(
                width: MediaQuery.of(context).size.width,
                margin: EdgeInsets.symmetric(horizontal: 4.0.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  color: Colors.grey.withAlpha(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.fill,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (ctx, err, stack) => _buildFallbackBanner(),
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
    return Showcase(
      titleTextStyle: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.2),
      descTextStyle: TextStyle(fontSize: 12.0.sp, fontWeight: FontWeight.w400, color: Color(0xFF475569), height: 1.35),
      key: _keySearch,
      title: 'Pencarian Cepat',
      description: 'Ketik nama layanan desa, barang Pasar Daerah, atau kabar desa untuk mencari langsung.',
      targetBorderRadius: BorderRadius.circular(20.r),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(35),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withAlpha(50), width: 1),
        ),
        child: TextField(
          controller: _searchController,
          style: TextStyle(color: Colors.white, fontSize: 12.5.sp),
          cursorColor: Colors.white,
          onSubmitted: (value) {
            _performSearch(value);
          },
          decoration: InputDecoration(
            hintText: 'Cari layanan desa, pasar, kabar...',
            hintStyle: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 12.sp,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 9.h,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.white.withAlpha(200),
              size: 18.sp,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: Colors.white70,
                      size: 16.sp,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
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
        margin: EdgeInsets.only(top: 30.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Showcase(
      titleTextStyle: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.2),
      descTextStyle: TextStyle(fontSize: 12.0.sp, fontWeight: FontWeight.w400, color: Color(0xFF475569), height: 1.35),
      key: _keyUnitPelayanan,
      title: 'Layanan Desa & BUMDes',
      description: 'Pusat layanan digital desa: Pelaporan warga, belanja Pasar Daerah, beli Gas, hingga sewa alat/mobil.',
      targetBorderRadius: BorderRadius.circular(20.r),
      child: Container(
        margin: EdgeInsets.only(
          top: 10.h,
        ), // Jarak atas diperkecil agar lebih dekat dengan banner
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24.w,
            ), // Samakan margin dengan elemen lain
            child: Row(
              children: [
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
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                if (item['color'] == 'teal') cardColor = Colors.teal;

                String imgPath =
                    item['imageUrl']?.toString() ??
                    item['image']?.toString() ??
                    '';
                String fallbackAsset = 'assets/images/F2.png';
                final titleLower = (item['title'] ?? '')
                    .toString()
                    .toLowerCase();
                if (titleLower.contains('pasar') ||
                    titleLower.contains('toko') ||
                    imgPath.contains('PasarDaerah')) {
                  fallbackAsset = 'assets/images/PasarDaerah.png';
                } else if (titleLower.contains('gas') ||
                    imgPath.contains('F2')) {
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
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: cardColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(16.r),
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
                      SizedBox(height: 8.h),
                      Text(
                        item['title'],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
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
    ),
    );
  }

  Widget _buildBumdesStoreMini() {
    // We no longer use mock products here, we use _pasarDaerahProducts.
    // If it's empty, we won't show the horizontal list.
    if (_pasarDaerahProducts.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(top: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Populer',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _checkLoginAndProceed('Toko BUMDes');
                  },
                  child: Text(
                    'Lihat Semua',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 175,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: _pasarDaerahProducts.length > 5
                  ? 5
                  : _pasarDaerahProducts.length,
              itemBuilder: (context, index) {
                final product = _pasarDaerahProducts[index];

                String name = product['nama_produk'] ?? 'Tanpa Nama';
                dynamic rawPrice = product['harga'] ?? 0;
                double price = (rawPrice is String)
                    ? (double.tryParse(rawPrice) ?? 0)
                    : (rawPrice as num).toDouble();
                String imageUrl = product['image_url'] ?? '';
                String satuan = product['satuan'] != null ? '/ ${product['satuan']}' : '';

                return GestureDetector(
                  onTap: () => _checkLoginAndProceed('Toko BUMDes'),
                  child: Container(
                    width: 140,
                    margin: EdgeInsets.only(right: 12.w, bottom: 4.h),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16.r),
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
                        Stack(
                          children: [
                            Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16.r),
                                ),
                              ),
                              child: imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16.r),
                                      ),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.storefront,
                                                  color: Colors.grey,
                                                ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.storefront,
                                      color: Colors.grey,
                                    ),
                            ),
                            Positioned(
                              top: 6.h,
                              right: 6.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(6.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(20),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_fire_department_rounded,
                                      color: Colors.white,
                                      size: 11.sp,
                                    ),
                                    SizedBox(width: 2.w),
                                    Text(
                                      'HOT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.all(8.0.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                '${NumberFormat.currency(
                                  locale: 'id',
                                  symbol: 'Rp',
                                  decimalDigits: 0,
                                ).format(price)} $satuan'.trim(),
                                style: TextStyle(
                                  color: Color(0xFF0EA5E9),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5.sp,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKabarDaerah() {
    return Container(
      margin: EdgeInsets.only(top: 30.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Pengumuman dan agenda terbaru',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  widget.onNavigateToNews();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Semua',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 10.sp,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: _announcements.isEmpty ? 60 : 220,
            child: _announcements.isEmpty
                ? _buildEmptyNewsState(context)
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
                              builder: (context) =>
                                  NewsDetailPage(newsItem: ann),
                            ),
                          );
                        },
                        child: _buildTerbaruCard(
                          ann['title']?.toString() ?? 'Tidak ada judul',
                          ann['image']?.toString() ??
                              'https://cdn-icons-png.flaticon.com/512/3176/3176298.png',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNewsState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Text(
        'Belum ada informasi terbaru saat ini.',
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.grey[600],
          fontSize: 14.sp,
        ),
      ),
    );
  }

  Widget _buildTerbaruCard(String title, String imageUrl) {
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: 16.w, bottom: 8.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20.r),
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            child: _buildElementImage(
              imageUrl,
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.w),
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
                        ).textTheme.bodyMedium!.copyWith(fontSize: 10.sp),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        child: Text(
                          'Baru',
                          style: TextStyle(
                            fontSize: 8.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
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
