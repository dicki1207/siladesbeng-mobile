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
    _unitPelayanan = _getDefaultUnitPelayanan();
    _pasarDaerahProducts = _getDefaultPopularProducts();
    _announcements = _getDefaultAnnouncements();
    _loadProfileData();
    _fetchPublicData();
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

  List<Map<String, dynamic>> _getDefaultPopularProducts() {
    return [
      {
        'id': 101,
        'nama_produk': 'Tanjak Songket Melayu',
        'harga': 75000,
        'satuan': 'pcs',
        'image_url':
            'https://images.unsplash.com/photo-1606760227091-3dd870d97f1d?auto=format&fit=crop&w=400&q=80',
      },
      {
        'id': 102,
        'nama_produk': 'Tas Anyaman Pandan Desa',
        'harga': 45000,
        'satuan': 'pcs',
        'image_url':
            'https://images.unsplash.com/photo-1590736704728-f4730bb30770?auto=format&fit=crop&w=400&q=80',
      },
      {
        'id': 103,
        'nama_produk': 'Tikar Purun Motif Alami',
        'harga': 60000,
        'satuan': 'lembar',
        'image_url':
            'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=400&q=80',
      },
      {
        'id': 104,
        'nama_produk': 'Kain Tenun Khas Bengkalis',
        'harga': 185000,
        'satuan': 'helai',
        'image_url':
            'https://images.unsplash.com/photo-1617627143750-d86bc21e42bb?auto=format&fit=crop&w=400&q=80',
      },
      {
        'id': 105,
        'nama_produk': 'Kerajinan Batok Kelapa Set',
        'harga': 25000,
        'satuan': 'set',
        'image_url':
            'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&w=400&q=80',
      },
    ];
  }

  List<Map<String, dynamic>> _getDefaultAnnouncements() {
    return [
      {
        'id': 301,
        'title': 'Jadwal Penyaluran BLT Desa Tahap III Tahun 2026',
        'category': 'Pengumuman',
        'type': 'Pengumuman',
        'date': '2026-08-26',
        'desc':
            'Penyaluran Bantuan Langsung Tunai (BLT) dilaksanakan di Kantor Desa mulai pukul 08.30 WIB dengan membawa KTP dan KK asli.',
        'content':
            'Diberitahukan kepada seluruh warga penerima manfaat Bantuan Langsung Tunai Dana Desa bahwa pembagian tahap III akan dilaksanakan di Aula Kantor Desa.',
        'image':
            'https://images.unsplash.com/photo-1450133064473-71024230f91b?auto=format&fit=crop&w=600&q=80',
        'location': 'Kantor Kepala Desa',
        'author': 'Sekretariat Desa',
      },
      {
        'id': 302,
        'title': 'Musyawarah Rencana Pembangunan Desa (Musrenbangdes)',
        'category': 'Pengumuman',
        'type': 'Pengumuman',
        'date': '2026-08-24',
        'desc':
            'Undangan musyawarah terbuka bersama Ketua RT, RW, BPD, dan tokoh masyarakat untuk menetapkan prioritas pembangunan TA 2027.',
        'content':
            'Pemerintah Desa mengundang seluruh perwakilan kelembagaan desa untuk hadir dalam rangka Musyawarah Perencanaan Pembangunan Desa tahun anggaran mendatang.',
        'image':
            'https://images.unsplash.com/photo-1577495508048-b635879837f1?auto=format&fit=crop&w=600&q=80',
        'location': 'Aula Pertemuan Desa',
        'author': 'Badan Permusyawaratan Desa',
      },
      {
        'id': 303,
        'title': 'Layanan Perekaman KTP-el & Akta Kelahiran Keliling',
        'category': 'Pengumuman',
        'type': 'Pengumuman',
        'date': '2026-08-20',
        'desc':
            'Pelayanan jemput bola dokumen kependudukan gratis oleh Disdukcapil bagi seluruh warga di Balai Desa.',
        'content':
            'Warga yang belum memiliki KTP elektronik atau ingin mengurus Akta Kelahiran dan Kartu Identitas Anak dapat langsung mendatangi loket pelayanan keliling.',
        'image':
            'https://images.unsplash.com/photo-1521791136064-7986c2920216?auto=format&fit=crop&w=600&q=80',
        'location': 'Balai Desa Bengkalis',
        'author': 'Disdukcapil & Pemdes',
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
                    _announcements = [
                      ..._getDefaultAnnouncements(),
                      ...validData,
                    ];
                  });
                } else {
                  setState(() {
                    _announcements = _getDefaultAnnouncements();
                  });
                }
              } catch (_) {
                setState(() {
                  _announcements = _getDefaultAnnouncements();
                });
              }
            }
          })
          .catchError((_) {
            if (mounted) {
              setState(() {
                _announcements = _getDefaultAnnouncements();
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

      // 5. Fetch Pasar Daerah (dengan fallback data mockup untuk poster)
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
                    _pasarDaerahProducts = [
                      ..._getDefaultPopularProducts(),
                      ...list,
                    ];
                  });
                }
              } catch (_) {
                setState(() {
                  _pasarDaerahProducts = _getDefaultPopularProducts();
                });
              }
            }
          })
          .catchError((_) {
            if (mounted) {
              setState(() {
                _pasarDaerahProducts = _getDefaultPopularProducts();
              });
            }
          });

      // Matikan indikator loading skeleton utama dengan sangat cepat
      // agar struktur UI tidak ter-block. List yang kosong akan di-handle oleh
      // check if empty/shrink secara elegan di bagian build.
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      setState(() {
        // Fallback untuk Announcement jika gagal loading
        if (_announcements.isEmpty) {
          _announcements = [
            {
              'title': 'Bantuan Sosial 2026',
              'content':
                  'Penyaluran bantuan sosial desa bulan ini untuk seluruh RT/RW...',
            },
            {
              'title': 'Rapat Kerja Bakti Warga',
              'content':
                  'Diadakan di balai desa membahas kebersihan dan ketentraman...',
            },
          ];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onNavigateToProfile,
            child: Container(
              padding: const EdgeInsets.all(2),
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
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 22,
                          ),
                        )
                      : (_isLoggedIn && _userImageUrl != null)
                      ? Image.network(
                          _userImageUrl!,
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
                  _userName,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
      margin: const EdgeInsets.only(top: 10, bottom: 6),
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
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
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
                  borderRadius: BorderRadius.circular(20),
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
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(50), width: 1),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 12.5),
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
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
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
            height: 175,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    margin: const EdgeInsets.only(right: 12, bottom: 4),
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
                        Stack(
                          children: [
                            Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              child: imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16),
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
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(20),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_fire_department_rounded,
                                      color: Colors.white,
                                      size: 11,
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      'HOT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
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
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${NumberFormat.currency(
                                  locale: 'id',
                                  symbol: 'Rp',
                                  decimalDigits: 0,
                                ).format(price)} $satuan'.trim(),
                                style: const TextStyle(
                                  color: Color(0xFF0EA5E9),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
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
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
            child: _buildElementImage(
              imageUrl,
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
            ),
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
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontSize: 14,
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
