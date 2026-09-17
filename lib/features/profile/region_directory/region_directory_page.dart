import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:siladesbeng_mobile/core/theme.dart';
import 'package:siladesbeng_mobile/services/region_directory_service.dart';
import 'package:siladesbeng_mobile/widgets/custom_cached_image.dart';

class RegionDirectoryPage extends StatefulWidget {
  final int? initialRegionId;

  const RegionDirectoryPage({super.key, this.initialRegionId});

  @override
  State<RegionDirectoryPage> createState() => _RegionDirectoryPageState();
}

class _RegionDirectoryPageState extends State<RegionDirectoryPage> {
  final RegionDirectoryService _service = RegionDirectoryService();

  bool _isLoadingHierarchy = true;
  bool _isLoadingProfile = true;

  Map<String, dynamic>? _kabupaten;
  List<dynamic> _kecamatans = [];

  Map<String, dynamic>? _selectedKecamatan;
  Map<String, dynamic>? _selectedDesa;

  Map<String, dynamic>? _currentRegion;
  List<dynamic> _structure = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingHierarchy = true;
    });

    final hierarchyData = await _service.getHierarchy();
    if (!mounted) return;

    if (hierarchyData != null) {
      setState(() {
        _kabupaten = hierarchyData['kabupaten'];
        _kecamatans = hierarchyData['kecamatans'] ?? [];
        _isLoadingHierarchy = false;
      });

      // Jika ada initialRegionId, coba temukan dan set selection
      if (widget.initialRegionId != null) {
        _findAndSelectRegion(widget.initialRegionId!);
      } else {
        // Default ke Kabupaten Bengkalis
        if (_kabupaten != null && _kabupaten!['id'] != null) {
          _fetchProfile(_kabupaten!['id']);
        }
      }
    } else {
      setState(() {
        _isLoadingHierarchy = false;
        _isLoadingProfile = false;
      });
    }
  }

  void _findAndSelectRegion(int targetId) {
    if (_kabupaten != null && _kabupaten!['id'] == targetId) {
      _resetToKabupaten();
      return;
    }

    for (var kec in _kecamatans) {
      if (kec['id'] == targetId) {
        setState(() {
          _selectedKecamatan = kec;
          _selectedDesa = null;
        });
        _fetchProfile(targetId);
        return;
      }
      final desas = kec['desas'] as List<dynamic>? ?? [];
      for (var desa in desas) {
        if (desa['id'] == targetId) {
          setState(() {
            _selectedKecamatan = kec;
            _selectedDesa = desa;
          });
          _fetchProfile(targetId);
          return;
        }
      }
    }

    // Fallback jika tidak ketemu
    if (_kabupaten != null && _kabupaten!['id'] != null) {
      _fetchProfile(_kabupaten!['id']);
    }
  }

  Future<void> _fetchProfile(int regionId) async {
    setState(() {
      _isLoadingProfile = true;
    });

    final profileData = await _service.getProfile(regionId);
    if (!mounted) return;

    if (profileData != null) {
      var structure = (profileData['structure'] as List<dynamic>?) ?? [];
      if (structure.isEmpty) {
        final fallback = _service.generateFallbackProfile(
          regionId,
          regionName: _selectedDesa?['name'] ?? _selectedKecamatan?['name'],
          regionType: _selectedDesa != null ? 'desa' : (_selectedKecamatan != null ? 'kecamatan' : 'kabupaten'),
        );
        structure = (fallback['structure'] as List<dynamic>?) ?? [];
      }
      setState(() {
        _currentRegion = profileData['region'];
        _structure = structure;
        _isLoadingProfile = false;
      });
    } else {
      final fallback = _service.generateFallbackProfile(
        regionId,
        regionName: _selectedDesa?['name'] ?? _selectedKecamatan?['name'],
        regionType: _selectedDesa != null ? 'desa' : (_selectedKecamatan != null ? 'kecamatan' : 'kabupaten'),
      );
      setState(() {
        _currentRegion = fallback['region'];
        _structure = (fallback['structure'] as List<dynamic>?) ?? [];
        _isLoadingProfile = false;
      });
    }
  }

  void _resetToKabupaten() {
    setState(() {
      _selectedKecamatan = null;
      _selectedDesa = null;
    });
    if (_kabupaten != null && _kabupaten!['id'] != null) {
      _fetchProfile(_kabupaten!['id']);
    }
  }

  void _onKecamatanChanged(Map<String, dynamic>? newKec) {
    if (newKec == null) {
      _resetToKabupaten();
      return;
    }
    setState(() {
      _selectedKecamatan = newKec;
      _selectedDesa = null;
    });
    _fetchProfile(newKec['id']);
  }

  void _onDesaChanged(Map<String, dynamic>? newDesa) {
    if (newDesa == null) {
      // Kembali ke level kecamatan
      setState(() {
        _selectedDesa = null;
      });
      if (_selectedKecamatan != null) {
        _fetchProfile(_selectedKecamatan!['id']);
      }
      return;
    }
    setState(() {
      _selectedDesa = newDesa;
    });
    _fetchProfile(newDesa['id']);
  }

  Future<void> _launchWhatsApp(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/${clean.replaceAll('+', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = AppTheme.primaryLight;
    final accentBlue = AppTheme.accentLight;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        title: Text(
          'Profil & Struktur Wilayah',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Segarkan',
            onPressed: () {
              if (_selectedDesa != null) {
                _fetchProfile(_selectedDesa!['id']);
              } else if (_selectedKecamatan != null) {
                _fetchProfile(_selectedKecamatan!['id']);
              } else if (_kabupaten != null) {
                _fetchProfile(_kabupaten!['id']);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: primaryBlue,
        onRefresh: () async {
          if (_selectedDesa != null) {
            await _fetchProfile(_selectedDesa!['id']);
          } else if (_selectedKecamatan != null) {
            await _fetchProfile(_selectedKecamatan!['id']);
          } else if (_kabupaten != null) {
            await _fetchProfile(_kabupaten!['id']);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. FILTER WILAYAH SECTION
              _buildFilterSection(isDark, primaryBlue),

              // 2. HEADER BANNER WILAYAH
              _buildRegionHeaderCard(isDark, primaryBlue, accentBlue),

              SizedBox(height: 16.h),

              // 3. BAGAN STRUKTUR ORGANISASI (BERDASARKAN PANGKAT / LEVEL)
              _isLoadingProfile
                  ? _buildLoadingSkeleton(isDark)
                  : _buildStructureSection(isDark, primaryBlue),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget Filter Wilayah Modern (Full Width Stacked Cards & Bottom Sheet Picker)
  Widget _buildFilterSection(bool isDark, Color primaryBlue) {
    final isKabupatenActive = _selectedKecamatan == null && _selectedDesa == null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.tune_rounded, size: 18.sp, color: primaryBlue),
                  SizedBox(width: 8.w),
                  Text(
                    'Pilih Lingkup Wilayah',
                    style: GoogleFonts.inter(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              if (!isKabupatenActive)
                InkWell(
                  onTap: _resetToKabupaten,
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: primaryBlue.withAlpha(isDark ? 45 : 20),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restart_alt_rounded, size: 14.sp, color: primaryBlue),
                        SizedBox(width: 4.w),
                        Text(
                          'Tingkat Kabupaten',
                          style: GoogleFonts.inter(
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            color: primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),

          // 1. Selector Kecamatan (Full Width - Tidak Terpotong)
          InkWell(
            onTap: _isLoadingHierarchy ? null : () => _showKecamatanPicker(context, isDark, primaryBlue),
            borderRadius: BorderRadius.circular(14.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: _selectedKecamatan != null
                      ? primaryBlue
                      : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(7.w),
                    decoration: BoxDecoration(
                      color: (_selectedKecamatan != null ? primaryBlue : Colors.grey).withAlpha(25),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.apartment_rounded,
                      size: 18.sp,
                      color: _selectedKecamatan != null ? primaryBlue : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wilayah Kecamatan',
                          style: GoogleFonts.inter(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          _selectedKecamatan != null
                              ? (_selectedKecamatan!['name'] ?? '')
                              : (_isLoadingHierarchy ? 'Memuat wilayah...' : '🏛️ Tingkat Kabupaten Bengkalis'),
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: _selectedKecamatan != null ? FontWeight.w700 : FontWeight.w600,
                            color: _selectedKecamatan != null
                                ? (isDark ? Colors.white : const Color(0xFF1E293B))
                                : primaryBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.unfold_more_rounded, size: 18.sp, color: primaryBlue),
                ],
              ),
            ),
          ),

          SizedBox(height: 8.h),

          // 2. Selector Desa (Full Width - Aktif jika kecamatan dipilih)
          InkWell(
            onTap: _selectedKecamatan == null ? null : () => _showDesaPicker(context, isDark, primaryBlue),
            borderRadius: BorderRadius.circular(14.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
              decoration: BoxDecoration(
                color: _selectedKecamatan == null
                    ? (isDark ? Colors.white.withAlpha(5) : const Color(0xFFF1F5F9).withAlpha(150))
                    : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: _selectedDesa != null
                      ? primaryBlue
                      : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(7.w),
                    decoration: BoxDecoration(
                      color: (_selectedDesa != null ? primaryBlue : Colors.grey).withAlpha(25),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 18.sp,
                      color: _selectedDesa != null
                          ? primaryBlue
                          : (_selectedKecamatan != null ? (isDark ? Colors.white60 : const Color(0xFF64748B)) : Colors.grey),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Desa / Kelurahan',
                          style: GoogleFonts.inter(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          _selectedDesa != null
                              ? (_selectedDesa!['name'] ?? '')
                              : (_selectedKecamatan == null
                                  ? 'Pilih kecamatan terlebih dahulu'
                                  : '📍 Kantor Kecamatan (Pemerintahan Kecamatan)'),
                          style: GoogleFonts.inter(
                            fontSize: 13.sp,
                            fontWeight: _selectedDesa != null ? FontWeight.w700 : FontWeight.w500,
                            color: _selectedDesa != null
                                ? (isDark ? Colors.white : const Color(0xFF1E293B))
                                : (_selectedKecamatan != null ? primaryBlue : (isDark ? Colors.white38 : const Color(0xFF94A3B8))),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 18.sp,
                    color: _selectedKecamatan == null ? Colors.grey : primaryBlue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Sheet Pemilihan Kecamatan dengan Search Bar Lengkap
  void _showKecamatanPicker(BuildContext context, bool isDark, Color primaryBlue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _kecamatans.where((k) {
              final name = (k['name'] ?? '').toString().toLowerCase();
              return name.contains(query.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pilih Kecamatan',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: TextField(
                      onChanged: (val) {
                        setModalState(() {
                          query = val;
                        });
                      },
                      style: GoogleFonts.inter(
                        fontSize: 13.5.sp,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari kecamatan di Kab. Bengkalis...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                        prefixIcon: Icon(Icons.search_rounded, color: primaryBlue, size: 20.sp),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      children: [
                        if (query.isEmpty || 'kabupaten bengkalis'.contains(query.toLowerCase()))
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            tileColor: _selectedKecamatan == null
                                ? primaryBlue.withAlpha(isDark ? 40 : 20)
                                : Colors.transparent,
                            leading: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: primaryBlue.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.apartment_rounded, color: primaryBlue, size: 20.sp),
                            ),
                            title: Text(
                              '🏛️ Tingkat Kabupaten Bengkalis',
                              style: GoogleFonts.inter(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w700,
                                color: _selectedKecamatan == null ? primaryBlue : (isDark ? Colors.white : const Color(0xFF1E293B)),
                              ),
                            ),
                            subtitle: Text(
                              'Pemerintah Kabupaten Bengkalis',
                              style: GoogleFonts.inter(
                                fontSize: 11.5.sp,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              ),
                            ),
                            trailing: _selectedKecamatan == null
                                ? Icon(Icons.check_circle_rounded, color: primaryBlue, size: 20.sp)
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              _resetToKabupaten();
                            },
                          ),
                        if (query.isEmpty) Divider(height: 16.h, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ...filtered.map((kec) {
                          final isSelected = _selectedKecamatan != null && _selectedKecamatan!['id'] == kec['id'];
                          final desas = (kec['desas'] as List<dynamic>?) ?? [];

                          return Container(
                            margin: EdgeInsets.only(bottom: 6.h),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              tileColor: isSelected
                                  ? primaryBlue.withAlpha(isDark ? 40 : 20)
                                  : Colors.transparent,
                              leading: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.holiday_village_rounded, color: isSelected ? primaryBlue : (isDark ? Colors.white70 : const Color(0xFF475569)), size: 20.sp),
                              ),
                              title: Text(
                                kec['name'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5.sp,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected ? primaryBlue : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                ),
                              ),
                              subtitle: Text(
                                '${desas.length} Desa / Kelurahan',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5.sp,
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle_rounded, color: primaryBlue, size: 20.sp)
                                  : Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.black26, size: 20.sp),
                              onTap: () {
                                Navigator.pop(context);
                                _onKecamatanChanged(kec as Map<String, dynamic>);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Bottom Sheet Pemilihan Desa dengan Search Bar Lengkap
  void _showDesaPicker(BuildContext context, bool isDark, Color primaryBlue) {
    if (_selectedKecamatan == null) return;

    final availableDesas = (_selectedKecamatan!['desas'] is List)
        ? _selectedKecamatan!['desas'] as List<dynamic>
        : <dynamic>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = availableDesas.where((d) {
              final name = (d['name'] ?? '').toString().toLowerCase();
              return name.contains(query.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.cardDark : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilih Desa / Kelurahan',
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                _selectedKecamatan!['name'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 12.sp,
                                  color: primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: TextField(
                      onChanged: (val) {
                        setModalState(() {
                          query = val;
                        });
                      },
                      style: GoogleFonts.inter(
                        fontSize: 13.5.sp,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari desa di kecamatan ini...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13.sp,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                        prefixIcon: Icon(Icons.search_rounded, color: primaryBlue, size: 20.sp),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      children: [
                        if (query.isEmpty || 'kantor kecamatan'.contains(query.toLowerCase()))
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                            tileColor: _selectedDesa == null
                                ? primaryBlue.withAlpha(isDark ? 40 : 20)
                                : Colors.transparent,
                            leading: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: primaryBlue.withAlpha(25),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.location_city_rounded, color: primaryBlue, size: 20.sp),
                            ),
                            title: Text(
                              '📍 Kantor Kecamatan (Semua Desa)',
                              style: GoogleFonts.inter(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w700,
                                color: _selectedDesa == null ? primaryBlue : (isDark ? Colors.white : const Color(0xFF1E293B)),
                              ),
                            ),
                            subtitle: Text(
                              'Tingkat Pemerintahan Kecamatan',
                              style: GoogleFonts.inter(
                                fontSize: 11.5.sp,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              ),
                            ),
                            trailing: _selectedDesa == null
                                ? Icon(Icons.check_circle_rounded, color: primaryBlue, size: 20.sp)
                                : null,
                            onTap: () {
                              Navigator.pop(context);
                              _onDesaChanged(null);
                            },
                          ),
                        if (query.isEmpty) Divider(height: 16.h, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ...filtered.map((desa) {
                          final isSelected = _selectedDesa != null && _selectedDesa!['id'] == desa['id'];

                          return Container(
                            margin: EdgeInsets.only(bottom: 6.h),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                              tileColor: isSelected
                                  ? primaryBlue.withAlpha(isDark ? 40 : 20)
                                  : Colors.transparent,
                              leading: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.place_rounded, color: isSelected ? primaryBlue : (isDark ? Colors.white70 : const Color(0xFF475569)), size: 20.sp),
                              ),
                              title: Text(
                                desa['name'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5.sp,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isSelected ? primaryBlue : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                ),
                              ),
                              subtitle: Text(
                                'Pemerintahan Desa / Kelurahan',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5.sp,
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle_rounded, color: primaryBlue, size: 20.sp)
                                  : null,
                              onTap: () {
                                Navigator.pop(context);
                                _onDesaChanged(desa as Map<String, dynamic>);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Banner Wilayah Aktif
  Widget _buildRegionHeaderCard(bool isDark, Color primaryBlue, Color accentBlue) {
    final regionName = _currentRegion?['name'] ?? _kabupaten?['name'] ?? 'Pemerintah Kabupaten Bengkalis';
    final regionType = _currentRegion?['type'] ?? 'kabupaten';
    final services = (_currentRegion?['active_services'] as List<dynamic>?) ?? [];
    final contactPhone = _currentRegion?['contact_phone'] as String?;

    String subtitle = 'Bagan Struktur Organisasi dan Tata Kerja Pemerintahan';
    if (regionType == 'desa') {
      subtitle = 'Struktur Pengurus & Perangkat Desa';
    } else if (regionType == 'kecamatan') {
      subtitle = 'Struktur Tata Kelola Kecamatan';
    } else {
      subtitle = 'Pemerintah Tingkat Kabupaten Bengkalis';
    }

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0369A1), // Sky dark
            primaryBlue,
            const Color(0xFF38BDF8), // Sky light
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withAlpha(70),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Badge Wilayah
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(45),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(color: Colors.white.withAlpha(80), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6.w),
                Text(
                  regionType.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),

          // Nama Wilayah
          Text(
            regionName,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 4.h),

          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: Colors.white.withAlpha(220),
            ),
          ),

          // Layanan Aktif Chips
          if (services.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              alignment: WrapAlignment.center,
              children: services.map((s) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(35),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    s.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Tombol Kontak / WhatsApp jika ada
          if (contactPhone != null && contactPhone.isNotEmpty) ...[
            SizedBox(height: 14.h),
            ElevatedButton.icon(
              onPressed: () => _launchWhatsApp(contactPhone),
              icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Color(0xFF10B981)),
              label: Text(
                'Hubungi Kantor Wilayah',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Normalisasi struktur agar pimpinan puncak (Level 1) terpisah dari wakil
  List<dynamic> _normalizeStructure(List<dynamic> rawStructure) {
    if (rawStructure.isEmpty) return [];

    List<dynamic> normalized = [];
    for (var group in rawStructure) {
      final level = group['level'] ?? 1;
      final levelName = group['level_name'] ?? 'Tingkat $level';
      final members = List<dynamic>.from(group['members'] ?? []);

      // Cek apakah di Level 1 ada wakil yang tercampur (misal Bupati & Wakil Bupati sama-sama level 1)
      if (level == 1 && members.length > 1) {
        final mainLeaders = <dynamic>[];
        final deputyLeaders = <dynamic>[];

        for (var m in members) {
          final pos = (m['position'] ?? '').toString().toLowerCase();
          if (pos.contains('wakil') || pos.contains('sekretaris')) {
            deputyLeaders.add(m);
          } else {
            mainLeaders.add(m);
          }
        }

        if (mainLeaders.isNotEmpty && deputyLeaders.isNotEmpty) {
          normalized.add({
            'level': 1,
            'level_name': levelName.contains('Daerah')
                ? 'Kepala Daerah'
                : (levelName.contains('Desa') ? 'Kepala Desa' : 'Pucuk Pimpinan'),
            'members': mainLeaders,
          });
          normalized.add({
            'level': 2,
            'level_name': levelName.contains('Daerah')
                ? 'Wakil Kepala Daerah'
                : 'Wakil Pimpinan / Pendamping',
            'members': deputyLeaders,
          });
          continue;
        }
      }

      normalized.add(group);
    }
    return normalized;
  }

  /// Bagian Struktur Organisasi Berdasarkan Tingkat / Pangkat (Level Piramida)
  Widget _buildStructureSection(bool isDark, Color primaryBlue) {
    final normalizedStructure = _normalizeStructure(_structure);

    if (normalizedStructure.isEmpty) {
      return _buildEmptyState(isDark, primaryBlue);
    }

    return Column(
      children: normalizedStructure.map((levelGroup) {
        final level = levelGroup['level'] ?? 1;
        final levelName = levelGroup['level_name'] ?? 'Tingkat $level';
        final members = (levelGroup['members'] as List<dynamic>?) ?? [];

        final isTopLeaderLevel = (level == 1);
        final isDeputyLevel = (level == 2);

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Badge Pangkat / Level Header
              _buildLevelHeader(isDark, level, levelName, primaryBlue),

              SizedBox(height: 12.h),

              // Pejabat Cards
              // Level 1: Pimpinan Utama (Bupati / Kades) tampil di paling atas (Center, Full Card)
              if (isTopLeaderLevel)
                ...members.map((member) => Center(
                  child: Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    width: 235.w,
                    height: 295.h,
                    child: _buildMemberCard(isDark, member, primaryBlue, isTopLeader: true),
                  ),
                ))
              // Level 2 (Wakil): Jika 1 orang, tampil di tengah di bawah pimpinan utama
              else if (members.length == 1)
                Center(
                  child: SizedBox(
                    width: 215.w,
                    height: 275.h,
                    child: _buildMemberCard(isDark, members.first, primaryBlue, isDeputy: isDeputyLevel),
                  ),
                )
              // Level 3 dst: Grid 2 Kolom yang rapi
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    return _buildMemberCard(isDark, members[index], primaryBlue);
                  },
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Header Level Pangkat
  Widget _buildLevelHeader(bool isDark, int level, String levelName, Color primaryBlue) {
    Color badgeColor;
    IconData badgeIcon;

    switch (level) {
      case 1:
        badgeColor = const Color(0xFFD97706); // Amber / Gold untuk Pimpinan Puncak
        badgeIcon = Icons.military_tech_rounded;
        break;
      case 2:
        badgeColor = const Color(0xFF0284C7); // Biru Utama untuk Wakil / Pendamping
        badgeIcon = Icons.stars_rounded;
        break;
      case 3:
        badgeColor = const Color(0xFF0EA5E9); // Sky blue
        badgeIcon = Icons.workspace_premium_rounded;
        break;
      default:
        badgeColor = const Color(0xFF64748B); // Slate
        badgeIcon = Icons.group_rounded;
        break;
    }

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: badgeColor.withAlpha(isDark ? 45 : 25),
            shape: BoxShape.circle,
          ),
          child: Icon(badgeIcon, size: 16.sp, color: badgeColor),
        ),
        SizedBox(width: 8.w),
        Text(
          levelName.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  badgeColor.withAlpha(120),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Card Pejabat / Perangkat Desa (Desain Piramida & Pimpinan Paling Atas)
  Widget _buildMemberCard(
    bool isDark,
    dynamic member,
    Color primaryBlue, {
    bool isTopLeader = false,
    bool isDeputy = false,
  }) {
    final name = member['name'] ?? 'Pejabat Wilayah';
    final position = member['position'] ?? 'Perangkat';
    String photoUrl = member['photo_url'] ?? '';
    if (photoUrl.startsWith('http://siladesbeng')) {
      photoUrl = photoUrl.replaceFirst('http://', 'https://');
    }

    const accentGold = Color(0xFFD97706);
    final cardBorderColor = isTopLeader
        ? accentGold.withAlpha(isDark ? 160 : 120)
        : (isDeputy
            ? primaryBlue.withAlpha(isDark ? 140 : 100)
            : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: cardBorderColor,
          width: isTopLeader ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isTopLeader
                ? accentGold.withAlpha(isDark ? 45 : 25)
                : Colors.black.withAlpha(isDark ? 40 : 12),
            blurRadius: isTopLeader ? 14 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Frame Foto Berlekuk Artistik
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14.r),
                      topRight: Radius.circular(28.r),
                      bottomLeft: Radius.circular(28.r),
                      bottomRight: Radius.circular(14.r),
                    ),
                    border: Border.all(
                      color: isTopLeader
                          ? accentGold.withAlpha(isDark ? 120 : 80)
                          : primaryBlue.withAlpha(isDark ? 80 : 40),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(13.r),
                      topRight: Radius.circular(27.r),
                      bottomLeft: Radius.circular(27.r),
                      bottomRight: Radius.circular(13.r),
                    ),
                    child: photoUrl.isNotEmpty
                        ? CustomCachedImage(
                            photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: isDark ? Colors.grey[850] : Colors.grey[100],
                              child: Icon(
                                Icons.person_rounded,
                                size: isTopLeader ? 54.sp : 48.sp,
                                color: (isTopLeader ? accentGold : primaryBlue).withAlpha(120),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person_rounded,
                            size: isTopLeader ? 54.sp : 48.sp,
                            color: (isTopLeader ? accentGold : primaryBlue).withAlpha(120),
                          ),
                  ),
                ),
              ),

              // Detail Nama & Jabatan
              Padding(
                padding: EdgeInsets.fromLTRB(10.w, 4.h, 10.w, 12.h),
                child: Column(
                  children: [
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: isTopLeader ? 13.5.sp : 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: (isTopLeader ? accentGold : primaryBlue).withAlpha(isDark ? 35 : 20),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        position,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: isTopLeader
                              ? (isDark ? Colors.amber[300] : const Color(0xFFB45309))
                              : primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Lencana Mahkota Pimpinan Puncak
          if (isTopLeader)
            Positioned(
              top: 6.h,
              right: 6.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withAlpha(100),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium_rounded, size: 12.sp, color: Colors.white),
                    SizedBox(width: 3.w),
                    Text(
                      'PIMPINAN',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
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

  /// Empty state jika suatu desa belum input struktur
  Widget _buildEmptyState(bool isDark, Color primaryBlue) {
    final regionName = _currentRegion?['name'] ?? 'Wilayah ini';

    return Container(
      margin: EdgeInsets.all(24.w),
      padding: EdgeInsets.all(28.w),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(18.w),
            decoration: BoxDecoration(
              color: primaryBlue.withAlpha(isDark ? 35 : 20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.groups_outlined,
              size: 48.sp,
              color: primaryBlue,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Bagan Struktur Belum Tersedia',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15.5.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Data bagan struktur dan pengurus untuk $regionName saat ini sedang dalam proses pembaruan oleh pihak pengurus wilayah.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmer skeleton saat berganti wilayah
  Widget _buildLoadingSkeleton(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          Container(
            height: 24.h,
            width: 160.w,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey[300],
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          SizedBox(height: 14.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 0.72,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.grey[200],
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                      height: 12.h,
                      color: isDark ? Colors.white10 : Colors.grey[200],
                    ),
                    Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      width: 60.w,
                      height: 10.h,
                      color: isDark ? Colors.white10 : Colors.grey[200],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
