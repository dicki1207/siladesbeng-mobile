// ignore_for_file: use_build_context_synchronously
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'cart_page.dart';
import 'pasar_detail_page.dart';
import 'pasar_favorite_page.dart';
import 'package:siladesbeng_mobile/services/pasar_product_service.dart';
import 'package:siladesbeng_mobile/services/pasar_cart_service.dart';
import 'package:siladesbeng_mobile/services/pasar_favorite_service.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  late final ShowcaseView _showcaseView;
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _cartKey = GlobalKey();

  final PasarProductService _pasarProductService = PasarProductService();
  final PasarCartService _pasarCartService = PasarCartService();
  final PasarFavoriteService _pasarFavService = PasarFavoriteService();

  String _selectedCategory = 'Semua';
  String _selectedSort = 'latest';
  String _selectedKecamatan = 'Semua Kecamatan';
  String _selectedDesa = 'Semua Desa';
  String _searchQuery = '';
  List<String> _categories = [
    'Semua',
    'Hasil Tani & Bumi',
    'Pangan & Olahan',
    'Material & Bangunan',
    'Kerajinan & Kesenian',
    'Lainnya',
  ];
  bool _isLoading = true;
  List<Map<String, dynamic>> _apiProducts = [];
  List<int> _favProductIds = [];
  int _cartCount = 0;

  final TextEditingController _searchController = TextEditingController();

  final List<String> _kecamatanList = [
    'Semua Kecamatan',
    'Kec. Bengkalis',
    'Kec. Bantan',
    'Kec. Bukit Batu',
    'Kec. Siak Kecil',
    'Kec. Mandau',
    'Kec. Pinggir',
    'Kec. Rupat',
  ];

  final Map<String, List<String>> _desaPerKecamatan = {
    'Semua Kecamatan': ['Semua Desa'],
    'Kec. Bengkalis': [
      'Semua Desa',
      'Desa Air Putih',
      'Desa Damai',
      'Desa Kelapapati',
      'Desa Kelebuk',
      'Desa Kelemantan',
      'Desa Kelemantan Barat',
      'Desa Ketam Putih',
      'Desa Kuala Alam',
      'Desa Meskom',
      'Desa Palkun',
      'Desa Pangkalan Batang',
      'Desa Pangkalan Batang Barat',
      'Desa Pedekik',
      'Desa Pematang Duku',
      'Desa Pematang Duku Timur',
      'Desa Penampi',
      'Desa Penebal',
      'Desa Prapat Tunggal',
      'Desa Sebauk',
      'Desa Sungai Alam',
      'Desa Sekodi',
      'Desa Senderak',
      'Desa Senggoro',
      'Desa Simpang Ayam',
      'Desa Sungai Batang',
      'Desa Teluk Latak',
      'Desa Tameran',
      'Desa Wonosari',
      'Kelurahan Bengkalis Kota',
      'Kelurahan Damon',
      'Kelurahan Rimba Sekampung',
    ],
    'Kec. Bantan': [
      'Semua Desa',
      'Desa Bantan Tengah',
      'Desa Bantan Air',
      'Desa Bantan Tua',
      'Desa Teluk Pambang',
      'Desa Selat Baru',
      'Desa Teluk Lancar',
      'Desa Kembung Luar',
      'Desa Jangkang',
      'Desa Muntai',
      'Desa Resam Lapis',
      'Desa Berancah',
      'Desa Ulu Pulau',
      'Desa Mentayan',
      'Desa Pambang Pesisir',
      'Desa Sukamaju',
      'Desa Pambang Baru',
      'Desa Kembung Baru',
      'Desa Pasiran',
      'Desa Bantan Sari',
      'Desa Bantan Timur',
      'Desa Teluk Papal',
      'Desa Muntai Barat',
      'Desa Deluk',
    ],
    'Kec. Bukit Batu': [
      'Semua Desa',
      'Desa Sejangat',
      'Desa Dompas',
      'Desa Pangkalan Jambi',
      'Desa Sungai Selari',
      'Desa Buruk Bakul',
      'Desa Bukit Kerikil',
      'Desa Sukajadi',
      'Desa Batang Duku',
      'Desa Pakning Asal',
      'Kelurahan Sungai Pakning',
    ],
    'Kec. Mandau': [
      'Semua Desa',
      'Desa Bathin Betuah',
      'Desa Harapan Baru',
      'Kelurahan Air Jamban',
      'Kelurahan Babussalam',
      'Kelurahan Balik Alam',
      'Kelurahan Batang Serosa',
      'Kelurahan Duri Barat',
      'Kelurahan Duri Timur',
      'Kelurahan Gajah Sakti',
      'Kelurahan Pematang Pudu',
      'Kelurahan Talang Mandi',
    ],
    'Kec. Rupat': [
      'Semua Desa',
      'Desa Darul Aman',
      'Desa Dungun Baru',
      'Desa Hutan Panjang',
      'Desa Makeruh',
      'Desa Pancur Jaya',
      'Desa Pangkalan Nyirih',
      'Desa Pangkalan Pinang',
      'Desa Parit Kebumen',
      'Desa Sri Tanjung',
      'Desa Sukarjo Mesim',
      'Desa Sungai Cingam',
      'Desa Teluk Lecah',
      'Kelurahan Batu Panjang',
      'Kelurahan Pergam',
      'Kelurahan Tanjung Kapal',
      'Kelurahan Terkul',
    ],
    'Kec. Rupat Utara': [
      'Semua Desa',
      'Desa Tanjung Medang',
      'Desa Teluk Rhu',
      'Desa Tanjung Punak',
      'Desa Titi Akar',
      'Desa Kadur',
      'Desa Hutan Ayu',
      'Desa Suka Damai',
      'Desa Puteri Sembilan',
    ],
    'Kec. Siak Kecil': [
      'Semua Desa',
      'Desa Lubuk Muda',
      'Desa Tanjung Belit',
      'Desa Sumber Jaya',
      'Desa Sungai Siput',
      'Desa Sepotong',
      'Desa Lubuk Garam',
      'Desa Lubuk Gaung',
      'Desa Tanjung Damai',
      'Desa Langkat',
      'Desa Sadar Jaya',
      'Desa Sungai Linau',
      'Desa Muara Dua',
      'Desa Bandar Jaya',
      'Desa Tanjung Datuk',
      'Desa Liang Banir',
      'Desa Koto Raja',
      'Desa Sungai Nibung',
    ],
    'Kec. Pinggir': [
      'Semua Desa',
      'Desa Balai Pungut',
      'Desa Muara Basung',
      'Desa Pinggir',
      'Desa Semunai',
      'Desa Sungai Meranti',
      'Desa Tengganau',
      'Desa Buluh Apo',
      'Desa Pangkalan Libut',
      'Kelurahan Balai Raja',
      'Kelurahan Titian Antui',
    ],
    'Kec. Bandar Laksamana': [
      'Semua Desa',
      'Desa Parit I Api Api',
      'Desa Temiang',
      'Desa Api Api',
      'Desa Tenggayun',
      'Desa Sepahat',
      'Desa Bukit Kerikil',
      'Desa Tanjung Leban',
    ],
    'Kec. Talang Muandau': [
      'Semua Desa',
      'Desa Beringin',
      'Desa Koto Pait Beringin',
      'Desa Kuala Penaso',
      'Desa Melibur',
      'Desa Serai Wangi',
      'Desa Tasik Serai',
      'Desa Tasik Serai Barat',
      'Desa Tasik Serai Timur',
      'Desa Tasik Tebing Serai',
    ],
    'Kec. Bathin Solapan': [
      'Semua Desa',
      'Desa Air Kulim',
      'Desa Balai Makam',
      'Desa Bathin Sobanga',
      'Desa Boncah Mahang',
      'Desa Buluh Manis',
      'Desa Bumbung',
      'Desa Kesumboampai',
      'Desa Pamesi',
      'Desa Pematang Obo',
      'Desa Petani',
      'Desa Sebangar',
      'Desa Simpang Padang',
      'Desa Tambusai Batang Dui',
    ],
  };

  @override
  void initState() {
    super.initState();
    _showcaseView = ShowcaseView.register();
    _fetchData();
    _fetchCartCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartShowcase(
);
    });
  }

  Future<void> _checkAndStartShowcase(
) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenTour = prefs.getBool('has_seen_store_tour') ?? false;

      if (!hasSeenTour && mounted) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          _showcaseView.startShowCase([
            _searchKey,
            _categoryKey,
            _cartKey,
          ]);
          await prefs.setBool('has_seen_store_tour', true);
        }
      }
    } catch (e) {
      debugPrint('Showcase error: $e');
    }
  }

  void _replayTour() {
    _showcaseView.startShowCase([
      _searchKey,
      _categoryKey,
      _cartKey,
    ]);
  }

  @override
  void dispose() {
    // _showcaseView.unregister(); // Prevent unregister on route replace race condition
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCartCount() async {
    final count = await _pasarProductService.getCartCount();
    if (mounted) {
      setState(() => _cartCount = count);
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      final categories = await _pasarProductService.getCategories();
      final products = await _pasarProductService.getProducts(
        category: _selectedCategory,
        search: _searchQuery,
        sort: _selectedSort,
      );

      // Client-side region filter
      List<Map<String, dynamic>> filtered = products;
      if (_selectedDesa != 'Semua Desa') {
        filtered = filtered.where((p) {
          final region = p['region'] is Map
              ? p['region']['name']?.toString() ?? ''
              : '';
          final lokasi = p['lokasi']?.toString() ?? '';
          return region.toLowerCase().contains(_selectedDesa.toLowerCase()) ||
              lokasi.toLowerCase().contains(_selectedDesa.toLowerCase());
        }).toList();
      } else if (_selectedKecamatan != 'Semua Kecamatan') {
        filtered = filtered.where((p) {
          final lokasi = p['lokasi']?.toString() ?? '';
          return lokasi.toLowerCase().contains(
            _selectedKecamatan.toLowerCase(),
          );
        }).toList();
      }

      final favIds = await _pasarFavService.getFavoriteProductIds();

      if (mounted) {
        setState(() {
          if (categories.isNotEmpty) _categories = categories;
          _apiProducts = filtered.isNotEmpty ? filtered : products;
          _favProductIds = favIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Unified Filter specifically for Wilayah & Urutkan Harga
  void _showFilterBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF0EA5E9);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String tempKecamatan = _selectedKecamatan;
        String tempDesa = _selectedDesa;
        String tempSort = _selectedSort;
        String tempCategory = _selectedCategory;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final List<String> currentDesaList =
                _desaPerKecamatan[tempKecamatan] ?? ['Semua Desa'];

            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24.r),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20.w,
                right: 20.w,
                top: 16.h,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(7.w),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: primaryColor,
                                size: 18.sp,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Filter & Urutan Produk',
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              tempCategory = 'Semua';
                              tempKecamatan = 'Semua Kecamatan';
                              tempDesa = 'Semua Desa';
                              tempSort = 'latest';
                            });
                          },
                          icon: Icon(Icons.refresh_rounded, size: 14.sp, color: Colors.redAccent),
                          label: Text(
                            'Reset',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),

                    // 1. Kategori Produk
                    Row(
                      children: [
                        Icon(
                          Icons.category_rounded,
                          size: 18.sp,
                          color: primaryColor,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '1. Kategori Produk',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = tempCategory == cat;
                        return ChoiceChip(
                          showCheckmark: false,
                          avatar: null,
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: primaryColor.withValues(
                            alpha: isDark ? 0.25 : 0.15,
                          ),
                          backgroundColor: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? (isDark ? Colors.white : primaryColor)
                                : (isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569)),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 12.sp,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? primaryColor
                                : (isDark
                                      ? Colors.white12
                                      : const Color(0xFFCBD5E1)),
                            width: isSelected ? 1.4 : 1,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => tempCategory = cat);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 18.h),

                    // 2. Wilayah Kecamatan (Antar-Kecamatan)
                    Row(
                      children: [
                        Icon(
                          Icons.location_city_rounded,
                          size: 18.sp,
                          color: primaryColor,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '2. Wilayah Kecamatan (Kab. Bengkalis)',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _kecamatanList.map((kec) {
                        final isSelected = tempKecamatan == kec;
                        return ChoiceChip(
                          showCheckmark: false,
                          avatar: null,
                          label: Text(kec),
                          selected: isSelected,
                          selectedColor: primaryColor.withValues(
                            alpha: isDark ? 0.25 : 0.15,
                          ),
                          backgroundColor: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? (isDark ? Colors.white : primaryColor)
                                : (isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569)),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 12.sp,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? primaryColor
                                : (isDark
                                      ? Colors.white12
                                      : const Color(0xFFCBD5E1)),
                            width: isSelected ? 1.4 : 1,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                tempKecamatan = kec;
                                tempDesa = 'Semua Desa';
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),

                    // Sub-wilayah Desa (Muncul saat memilih kecamatan spesifik)
                    if (tempKecamatan != 'Semua Kecamatan') ...[
                      SizedBox(height: 14.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF059669).withValues(alpha: 0.3)
                                : const Color(0xFFA7F3D0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.holiday_village_rounded,
                                  size: 17.sp,
                                  color: Color(0xFF10B981),
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text(
                                    'Pilih Desa di $tempKecamatan',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFF065F46),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: currentDesaList.map((desa) {
                                final isSelected = tempDesa == desa;
                                return ChoiceChip(
                                  showCheckmark: false,
                                  avatar: null,
                                  label: Text(desa),
                                  selected: isSelected,
                                  selectedColor: const Color(
                                    0xFF10B981,
                                  ).withValues(
                                    alpha: isDark ? 0.28 : 0.18,
                                  ),
                                  backgroundColor: isDark
                                      ? const Color(0xFF1E293B)
                                      : Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? (isDark
                                              ? Colors.white
                                              : const Color(0xFF059669))
                                        : (isDark
                                              ? Colors.white70
                                              : const Color(0xFF475569)),
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 11.5.sp,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  side: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFF10B981)
                                        : (isDark
                                              ? Colors.white12
                                              : const Color(0xFFD1D5DB)),
                                    width: isSelected ? 1.4 : 1,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setModalState(() => tempDesa = desa);
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: 20.h),

                    // 3. Urutan Harga / Waktu (3 Equal Columns Card)
                    Row(
                      children: [
                        Icon(
                          Icons.swap_vert_rounded,
                          size: 18.sp,
                          color: primaryColor,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '3. Urutkan Berdasarkan',
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        _buildSortCard(
                          label: 'Terbaru',
                          sublabel: 'Rilis terbaru',
                          icon: Icons.access_time_filled_rounded,
                          value: 'latest',
                          groupValue: tempSort,
                          onChanged: (val) =>
                              setModalState(() => tempSort = val),
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        SizedBox(width: 8.w),
                        _buildSortCard(
                          label: 'Termurah',
                          sublabel: 'Harga terendah',
                          icon: Icons.trending_down_rounded,
                          value: 'price_asc',
                          groupValue: tempSort,
                          onChanged: (val) =>
                              setModalState(() => tempSort = val),
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        SizedBox(width: 8.w),
                        _buildSortCard(
                          label: 'Termahal',
                          sublabel: 'Harga tertinggi',
                          icon: Icons.trending_up_rounded,
                          value: 'price_desc',
                          groupValue: tempSort,
                          onChanged: (val) =>
                              setModalState(() => tempSort = val),
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                      ],
                    ),

                    SizedBox(height: 26.h),

                    // Apply Button
                    Container(
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14.r),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0284C7).withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = tempCategory;
                            _selectedKecamatan = tempKecamatan;
                            _selectedDesa = tempDesa;
                            _selectedSort = tempSort;
                          });
                          Navigator.pop(context);
                          _fetchData();
                        },
                        icon: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18.sp,
                        ),
                        label: Text(
                          'Terapkan Filter & Urutan',
                          style: TextStyle(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortCard({
    required String label,
    required String sublabel,
    required IconData icon,
    required String value,
    required String groupValue,
    required ValueChanged<String> onChanged,
    required bool isDark,
    required Color primaryColor,
  }) {
    final isSelected = value == groupValue;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: isDark ? 0.22 : 0.1)
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(7.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: isDark ? 0.35 : 0.2)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFEDF2F7)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18.sp,
                  color: isSelected
                      ? (isDark ? Colors.white : primaryColor)
                      : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : primaryColor)
                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                sublabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? (isDark
                            ? primaryColor.withValues(alpha: 0.9)
                            : primaryColor)
                      : (isDark ? Colors.white38 : Colors.grey[500]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF0EA5E9);

    final hasActiveRegionFilter =
        _selectedKecamatan != 'Semua Kecamatan' ||
        _selectedDesa != 'Semua Desa';
    final hasActiveSortFilter = _selectedSort != 'latest';
    final hasRegionOrSortFilter = hasActiveRegionFilter || hasActiveSortFilter;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1120)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Pasar Daerah',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFF2563EB),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline_rounded,
              color: Colors.white,
              size: 22.sp,
            ),
            tooltip: 'Panduan Halaman',
            onPressed: _replayTour,
          ),
        ],
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
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
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchData();
          await _fetchCartCount();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Search Bar with Filter, Favorit, and Keranjang Buttons
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: [
                    // Search Input
                    Expanded(
                      child: Showcase(
                        titleTextStyle: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.2),
                        descTextStyle: TextStyle(fontSize: 12.0.sp, fontWeight: FontWeight.w400, color: Color(0xFF475569), height: 1.35),
                        key: _searchKey,
                        title: 'Pencarian & Filter Wilayah',
                        description:
                            'Cari produk BUMDes, sembako, dan gunakan tombol filter untuk memilih Kecamatan/Desa.',
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Cari produk BUMDes, sembako...',
                            hintStyle: TextStyle(
                              fontSize: 13.sp,
                              color: isDark ? Colors.white38 : Colors.grey[500],
                            ),
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: Stack(
                              alignment: Alignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.tune_rounded,
                                    color: hasRegionOrSortFilter ? primaryColor : null,
                                  ),
                                  onPressed: _showFilterBottomSheet,
                                  tooltip: 'Filter Wilayah & Urutkan',
                                ),
                                if (hasRegionOrSortFilter)
                                  Positioned(
                                    top: 10.h,
                                    right: 10.w,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white10
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: BorderSide(
                                color: isDark
                                    ? Colors.white10
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: const BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            contentPadding: EdgeInsets.symmetric(vertical: 0.h),
                          ),
                          onSubmitted: (value) {
                            setState(() => _searchQuery = value);
                            _fetchData();
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),

                    // Favorit Button
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.03,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14.r),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PasarFavoritePage(),
                              ),
                            ).then((_) {
                              _fetchData();
                              _fetchCartCount();
                            });
                          },
                          child: Icon(
                            Icons.favorite_outline_rounded,
                            size: 22.sp,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),

                    // Keranjang Button with Badge
                    Showcase(
                      titleTextStyle: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.2),
                      descTextStyle: TextStyle(fontSize: 12.0.sp, fontWeight: FontWeight.w400, color: Color(0xFF475569), height: 1.35),
                      key: _cartKey,
                      title: 'Keranjang Belanja',
                      description:
                          'Periksa barang belanjaan Anda dan lanjutkan ke proses pemesanan & pembayaran.',
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.03,
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14.r),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CartPage(),
                                ),
                              );
                              _fetchCartCount();
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 22.sp,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF64748B),
                                ),
                                if (_cartCount > 0)
                                  Positioned(
                                    top: 6.h,
                                    right: 6.w,
                                    child: Container(
                                      padding: EdgeInsets.all(3.5.w),
                                      decoration: const BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        _cartCount > 99 ? '99+' : '$_cartCount',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Active Filter Badges (Kecamatan / Desa / Urutan)
            if (hasRegionOrSortFilter)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (hasActiveRegionFilter)
                          InputChip(
                            avatar: Icon(
                              Icons.location_on_rounded,
                              size: 14.sp,
                              color: Color(0xFF0284C7),
                            ),
                            label: Text(
                              _selectedDesa != 'Semua Desa'
                                  ? '$_selectedDesa ($_selectedKecamatan)'
                                  : _selectedKecamatan,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                            backgroundColor: const Color(
                              0xFF0284C7,
                            ).withValues(alpha: 0.12),
                            side: BorderSide(
                              color: const Color(
                                0xFF0284C7,
                              ).withValues(alpha: 0.3),
                            ),
                            onDeleted: () {
                              setState(() {
                                _selectedKecamatan = 'Semua Kecamatan';
                                _selectedDesa = 'Semua Desa';
                              });
                              _fetchData();
                            },
                          ),
                        if (hasActiveSortFilter) ...[
                          SizedBox(width: 6.w),
                          InputChip(
                            avatar: Icon(
                              Icons.sort_rounded,
                              size: 14.sp,
                              color: primaryColor,
                            ),
                            label: Text(
                              _selectedSort == 'price_asc'
                                  ? 'Termurah'
                                  : 'Tertinggi',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            backgroundColor: primaryColor.withValues(
                              alpha: 0.12,
                            ),
                            side: BorderSide(
                              color: primaryColor.withValues(alpha: 0.3),
                            ),
                            onDeleted: () {
                              setState(() => _selectedSort = 'latest');
                              _fetchData();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

            // 3. Quick Category Horizontal Pills (Specifically for Kategori Produk)
            SliverToBoxAdapter(
              child: Showcase(
                titleTextStyle: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.2),
                descTextStyle: TextStyle(fontSize: 12.0.sp, fontWeight: FontWeight.w400, color: Color(0xFF475569), height: 1.35),
                key: _categoryKey,
                title: 'Kategori Produk',
                description:
                    'Pilih kategori produk BUMDes seperti Hasil Tani, Pangan, Kerajinan, dll.',
                child: Container(
                  height: 38,
                  margin: EdgeInsets.only(top: 4.h, bottom: 8.h),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(width: 8.w),
                    itemBuilder: (context, i) {
                    final cat = _categories[i];
                    final isSelected = _selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      showCheckmark: false,
                      avatar: null,
                      selectedColor: primaryColor.withValues(alpha: 0.18),
                      backgroundColor: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? primaryColor
                            : (isDark
                                  ? Colors.white70
                                  : const Color(0xFF475569)),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 12.sp,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? primaryColor
                            : (isDark
                                  ? Colors.white12
                                  : const Color(0xFFE2E8F0)),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat);
                          _fetchData();
                        }
                      },
                    );
                  },
                ),
              ),
            ),
          ),

            // 4. Products Grid Immediately at the Top!
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_apiProducts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 70.sp,
                        color: isDark ? Colors.white24 : Colors.grey[300],
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Belum ada produk',
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Produk di kategori atau wilayah ini belum tersedia.',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey[500],
                          fontSize: 12.5.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.70,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = _apiProducts[index];
                    return _buildProductCard(product, isDark);
                  }, childCount: _apiProducts.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, bool isDark) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final String name = product['nama_produk'] ?? product['name'] ?? '';
    final double price = product['harga'] != null
        ? double.tryParse(product['harga'].toString()) ?? 0
        : (product['price'] != null
              ? double.tryParse(product['price'].toString()) ?? 0
              : 0);
    final String? imageUrl =
        product['image_url'] ??
        (product['images'] is List && product['images'].isNotEmpty
            ? product['images'][0]
            : null);
    final int productId = product['id'] is int
        ? product['id']
        : int.tryParse(product['id']?.toString() ?? '0') ?? 0;
    final String lokasi = product['region'] is Map
        ? product['region']['name']?.toString() ?? ''
        : (product['lokasi']?.toString() ?? 'Bengkalis');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PasarDetailPage(productId: productId),
          ),
        ).then((_) => _fetchCartCount());
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Image + Village Tag + Heart Toggle
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16.r),
                    ),
                    child: imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            memCacheWidth: 500,
                            placeholder: (ctx, url) => Container(color: Colors.grey[200]),
                            errorWidget: (ctx, url, err) => const Icon(Icons.broken_image, color: Colors.grey),
                          )
                        : Container(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : Colors.grey[200],
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  // Village Tag
                  Positioned(
                    top: 6.h,
                    left: 6.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.store_rounded,
                            color: Colors.white,
                            size: 10.sp,
                          ),
                          SizedBox(width: 3.w),
                          Text(
                            lokasi,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Heart Toggle Button
                  Positioned(
                    top: 6.h,
                    right: 6.w,
                    child: GestureDetector(
                      onTap: () async {
                        final isNowFav = await _pasarFavService
                            .toggleProductFavorite(productId);
                        if (mounted) {
                          setState(() {
                            if (isNowFav) {
                              _favProductIds.add(productId);
                            } else {
                              _favProductIds.remove(productId);
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isNowFav
                                    ? '❤️ $name ditambahkan ke Favorit'
                                    : '$name dihapus dari Favorit',
                              ),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _favProductIds.contains(productId)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 15.sp,
                          color: _favProductIds.contains(productId)
                              ? Colors.redAccent
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info Content
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 13.sp,
                        color: Color(0xFFF59E0B),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        '4.9',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF334155),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '(48)',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    currencyFormat.format(price),
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0EA5E9),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final success = await _pasarCartService.addToCart(
                          productId,
                          1,
                        );
                        if (mounted && success) {
                          _fetchCartCount();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ditambahkan ke keranjang!'),
                              backgroundColor: Color(0xFF10B981),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.add_shopping_cart, size: 14.sp),
                      label: Text(
                        '+ Keranjang',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0EA5E9),
                        side: const BorderSide(
                          color: Color(0xFF0EA5E9),
                          width: 1.2,
                        ),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
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
}
