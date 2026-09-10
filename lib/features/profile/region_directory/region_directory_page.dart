import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:siladesbeng_mobile/core/theme.dart';
import 'package:siladesbeng_mobile/services/region_directory_service.dart';

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
      setState(() {
        _currentRegion = profileData['region'];
        _structure = profileData['structure'] ?? [];
        _isLoadingProfile = false;
      });
    } else {
      setState(() {
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

  /// Widget Filter Dropdown Kecamatan & Desa
  Widget _buildFilterSection(bool isDark, Color primaryBlue) {
    final availableDesas = (_selectedKecamatan != null &&
            _selectedKecamatan!['desas'] is List)
        ? _selectedKecamatan!['desas'] as List<dynamic>
        : <dynamic>[];

    final isKabupatenActive = _selectedKecamatan == null;

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
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: primaryBlue.withAlpha(isDark ? 40 : 20),
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
                            fontWeight: FontWeight.w600,
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

          // Dropdown Row
          Row(
            children: [
              // Dropdown Kecamatan
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _selectedKecamatan != null
                          ? primaryBlue
                          : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      width: 1.2,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      value: _selectedKecamatan,
                      isExpanded: true,
                      hint: Text(
                        _isLoadingHierarchy
                            ? 'Memuat...'
                            : (_kabupaten?['name'] ?? 'Kecamatan'),
                        style: GoogleFonts.inter(
                          fontSize: 12.5.sp,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      dropdownColor: isDark ? AppTheme.cardDark : Colors.white,
                      icon: Icon(Icons.arrow_drop_down_rounded, color: primaryBlue),
                      items: [
                        DropdownMenuItem<Map<String, dynamic>>(
                          value: null,
                          child: Text(
                            '🏢 ${_kabupaten?['name'] ?? 'Semua / Kabupaten'}',
                            style: GoogleFonts.inter(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: primaryBlue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ..._kecamatans.map((kec) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: kec as Map<String, dynamic>,
                            child: Text(
                              kec['name'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 12.5.sp,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: _onKecamatanChanged,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 10.w),

              // Dropdown Desa
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _selectedDesa != null
                          ? primaryBlue
                          : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      width: 1.2,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      value: _selectedDesa,
                      isExpanded: true,
                      hint: Text(
                        _selectedKecamatan == null ? 'Pilih Desa...' : 'Semua Desa',
                        style: GoogleFonts.inter(
                          fontSize: 12.5.sp,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      dropdownColor: isDark ? AppTheme.cardDark : Colors.white,
                      icon: Icon(
                        Icons.arrow_drop_down_rounded,
                        color: _selectedKecamatan == null
                            ? Colors.grey
                            : primaryBlue,
                      ),
                      items: [
                        if (_selectedKecamatan != null)
                          DropdownMenuItem<Map<String, dynamic>>(
                            value: null,
                            child: Text(
                              '📍 Kantor Kecamatan',
                              style: GoogleFonts.inter(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w600,
                                color: primaryBlue,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ...availableDesas.map((desa) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: desa as Map<String, dynamic>,
                            child: Text(
                              desa['name'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 12.5.sp,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: _selectedKecamatan == null ? null : _onDesaChanged,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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

  /// Bagian Struktur Organisasi Berdasarkan Tingkat / Pangkat (Level)
  Widget _buildStructureSection(bool isDark, Color primaryBlue) {
    if (_structure.isEmpty) {
      return _buildEmptyState(isDark, primaryBlue);
    }

    return Column(
      children: _structure.map((levelGroup) {
        final level = levelGroup['level'] ?? 1;
        final levelName = levelGroup['level_name'] ?? 'Tingkat $level';
        final members = (levelGroup['members'] as List<dynamic>?) ?? [];

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Badge Pangkat / Level Header
              _buildLevelHeader(isDark, level, levelName, primaryBlue),

              SizedBox(height: 12.h),

              // Pejabat Cards (1 orang = centered single card, >=2 orang = grid 2 kolom)
              if (members.length == 1)
                Center(
                  child: SizedBox(
                    width: 200.w,
                    child: _buildMemberCard(isDark, members.first, primaryBlue),
                  ),
                )
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
        badgeColor = const Color(0xFF0284C7); // Biru Utama
        badgeIcon = Icons.military_tech_rounded;
        break;
      case 2:
        badgeColor = const Color(0xFF0EA5E9); // Sky blue
        badgeIcon = Icons.stars_rounded;
        break;
      case 3:
        badgeColor = const Color(0xFF38BDF8); // Cyan blue
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

  /// Card Pejabat / Perangkat Desa (Meniru estetika pada web bagan screenshot)
  Widget _buildMemberCard(bool isDark, dynamic member, Color primaryBlue) {
    final name = member['name'] ?? 'Pejabat Wilayah';
    final position = member['position'] ?? 'Perangkat';
    String photoUrl = member['photo_url'] ?? '';
    if (photoUrl.startsWith('http://siladesbeng')) {
      photoUrl = photoUrl.replaceFirst('http://', 'https://');
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Frame Foto Berlekuk Artistik (seperti di web)
          Expanded(
            child: Container(
              margin: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14.r),
                  topRight: Radius.circular(28.r), // Khas lekukan sudut modern web
                  bottomLeft: Radius.circular(28.r),
                  bottomRight: Radius.circular(14.r),
                ),
                border: Border.all(
                  color: primaryBlue.withAlpha(isDark ? 80 : 40),
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
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 400,
                        placeholder: (context, url) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: isDark ? Colors.grey[850] : Colors.grey[100],
                          child: Icon(
                            Icons.person_rounded,
                            size: 48.sp,
                            color: primaryBlue.withAlpha(120),
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person_rounded,
                        size: 48.sp,
                        color: primaryBlue.withAlpha(120),
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
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  position,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
              ],
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
