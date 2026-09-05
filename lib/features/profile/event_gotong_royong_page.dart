import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';
import 'package:siladesbeng_mobile/services/event_service.dart';

class EventGotongRoyongPage extends StatefulWidget {
  const EventGotongRoyongPage({super.key});

  @override
  State<EventGotongRoyongPage> createState() => _EventGotongRoyongPageState();
}

class _EventGotongRoyongPageState extends State<EventGotongRoyongPage> {
  String _selectedFilter = 'Semua';
  final EventService _eventService = EventService();

  // Form State
  final _formKey = GlobalKey<FormState>();
  String _formTipe = 'Gotong Royong';
  String _targetScope = 'Tingkat RW / Dusun';
  String _selectedRw = 'RW 01 - Dusun Mawar';
  String _selectedRt = 'RT 01';
  bool _isSubmitting = false;

  final _titleController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _locationController = TextEditingController();
  final _noteController = TextEditingController();
  File? _posterImage;

  final List<String> _scopeList = [
    'Seluruh Desa (Umum)',
    'Tingkat RW / Dusun',
    'Spesifik Lingkungan RT',
  ];

  final List<String> _rwList = [
    'RW 01 - Dusun Mawar',
    'RW 02 - Dusun Melati',
    'RW 03 - Dusun Kenanga',
    'RW 04 - Dusun Dahlia',
  ];

  final Map<String, List<String>> _rtOptions = {
    'RW 01 - Dusun Mawar': ['RT 01', 'RT 02', 'RT 03', 'RT 04'],
    'RW 02 - Dusun Melati': ['RT 01', 'RT 02', 'RT 03', 'RT 04', 'RT 05'],
    'RW 03 - Dusun Kenanga': ['RT 01', 'RT 02', 'RT 03'],
    'RW 04 - Dusun Dahlia': ['RT 01', 'RT 02', 'RT 03', 'RT 04'],
  };

  final List<Map<String, dynamic>> _tipeOptions = [
    {
      'label': 'Gotong Royong',
      'icon': Icons.volunteer_activism_rounded,
      'desc': 'Kerja bakti & kebersihan',
      'color': const Color(0xFF10B981),
      'gradient': [const Color(0xFF059669), const Color(0xFF10B981)],
    },
    {
      'label': 'Acara / Event',
      'icon': Icons.festival_rounded,
      'desc': 'Kegiatan warga & pesta',
      'color': const Color(0xFF8B5CF6),
      'gradient': [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)],
    },
    {
      'label': 'Pengumuman',
      'icon': Icons.campaign_rounded,
      'desc': 'Informasi penting / rapat',
      'color': const Color(0xFFF59E0B),
      'gradient': [const Color(0xFFD97706), const Color(0xFFF59E0B)],
    },
  ];

  final List<String> _quickLocations = [
    'Pos Ronda RT',
    'Balai Pertemuan Desa',
    'Masjid Jami’',
    'Lapangan Desa',
  ];

  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  String? _resolvePosterUrl(dynamic raw) {
    if (raw == null || raw.toString().trim().isEmpty) return null;
    final str = raw.toString().trim();
    if (str.startsWith('http://') || str.startsWith('https://')) {
      final uri = Uri.tryParse(str);
      if (uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
        final baseUri = Uri.parse(ApiConfig.baseUrl);
        return uri
            .replace(
              scheme: baseUri.scheme,
              host: baseUri.host,
              port: baseUri.port,
            )
            .toString();
      }
      return str;
    }
    final clean = str.startsWith('/') ? str.substring(1) : str;
    if (clean.startsWith('storage/')) {
      return '${ApiConfig.baseUrl}/$clean';
    }
    return '${ApiConfig.baseUrl}/storage/$clean';
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });
    final data = await _eventService.getEvents();
    if (!mounted) return;
    if (data.isNotEmpty) {
      setState(() {
        _events = data.map<Map<String, dynamic>>((item) {
          final String tipe = item['tipe'] ?? 'gotong_royong';
          String tipeLabel = 'Gotong Royong';
          if (tipe == 'rapat' || tipe == 'pengumuman') {
            tipeLabel = 'Pengumuman';
          } else if (tipe == 'kegiatan_sosial' || tipe == 'acara') {
            tipeLabel = 'Acara / Event';
          }

          return {
            'id': item['id'],
            'title': item['judul'] ?? '',
            'wilayah':
                '${item['rw'] ?? ''} ${item['rt'] != null ? '- ${item['rt']}' : ''}'
                    .trim(),
            'tipe': tipeLabel,
            'koordinator': item['koordinator'] ?? '',
            'jadwal': item['jadwal'] ?? '',
            'lokasi': item['lokasi'] ?? '',
            'note': item['catatan'] ?? '',
            'posterUrl': _resolvePosterUrl(item['poster_url'] ?? item['poster_path']),
            'participants': item['jumlah_peserta'] ?? 0,
            'isJoined': item['is_joined'] ?? false,
            'isCreator': item['is_creator'] ?? false,
          };
        }).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _events = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _scheduleController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Pelaksanaan',
      confirmText: 'Lanjut Pilih Jam',
      cancelText: 'Batal',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2FA2F1),
              primary: const Color(0xFF2FA2F1),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 8, minute: 0),
        helpText: 'Pilih Waktu / Jam',
        confirmText: 'Simpan',
        cancelText: 'Batal',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF2FA2F1),
                primary: const Color(0xFF2FA2F1),
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        final days = [
          'Senin',
          'Selasa',
          'Rabu',
          'Kamis',
          'Jumat',
          'Sabtu',
          'Minggu',
        ];
        final months = [
          'Januari',
          'Februari',
          'Maret',
          'April',
          'Mei',
          'Juni',
          'Juli',
          'Agustus',
          'September',
          'Oktober',
          'November',
          'Desember',
        ];
        final dayName = days[date.weekday - 1];
        final monthName = months[date.month - 1];
        final timeStr =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} WIB';
        setState(() {
          _scheduleController.text =
              '$dayName, ${date.day} $monthName ${date.year} • Pukul $timeStr';
        });
      }
    }
  }

  Future<void> _handleToggleJoin(int idx) async {
    final eventId = _events[idx]['id'];
    if (eventId == null) return;

    final response = await _eventService.toggleJoin(eventId);
    if (!mounted) return;

    if (response['status'] == 'success') {
      setState(() {
        _events[idx]['isJoined'] =
            response['joined'] ?? !(_events[idx]['isJoined'] as bool);
        _events[idx]['participants'] =
            response['jumlah_peserta'] ?? _events[idx]['participants'];
      });

      final bool isJoined = _events[idx]['isJoined'] as bool;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isJoined
                    ? Icons.check_circle_rounded
                    : Icons.info_outline_rounded,
                color: Colors.white,
                size: 20.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  isJoined
                      ? 'Terima kasih! Anda tercatat siap hadir.'
                      : 'Partisipasi kehadiran dibatalkan.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: isJoined
              ? const Color(0xFF10B981)
              : const Color(0xFF475569),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    }
  }

  Future<void> _handleSubmitEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    String tipeApi = 'gotong_royong';
    if (_formTipe == 'Acara / Event') tipeApi = 'kegiatan_sosial';
    if (_formTipe == 'Pengumuman') tipeApi = 'rapat';

    final response = await _eventService.store(
      judul: _titleController.text.trim(),
      tipe: tipeApi,
      targetScope: _targetScope,
      rw: _selectedRw,
      rt: _targetScope == 'Spesifik Lingkungan RT' ? _selectedRt : null,
      jadwal: _scheduleController.text.trim(),
      lokasi: _locationController.text.trim(),
      catatan: _noteController.text.trim(),
      posterPath: _posterImage?.path,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response['status'] == 'success') {
      _titleController.clear();
      _scheduleController.clear();
      _locationController.clear();
      _noteController.clear();
      _posterImage = null;
      Navigator.pop(context);
      await _loadEvents();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 22.sp),
              SizedBox(width: 10.w),
              const Expanded(
                child: Text(
                  'Pengumuman berhasil dipublikasikan ke warga!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Gagal membuat pengumuman'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter Logic
    List<Map<String, dynamic>> filteredEvents;
    if (_selectedFilter == 'Semua') {
      filteredEvents = _events;
    } else if (_selectedFilter == 'Diikuti Saya') {
      filteredEvents = _events.where((e) => e['isJoined'] == true).toList();
    } else {
      filteredEvents = _events
          .where((e) => (e['wilayah'] as String).contains(_selectedFilter))
          .toList();
    }

    final int joinedCount =
        _events.where((e) => e['isJoined'] == true).length;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1120)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFF2FA2F1),
        elevation: 0,
        scrolledUnderElevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
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
            // Ambient light circle 1 (Top Right)
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(22),
                ),
              ),
            ),
            // Ambient light circle 2 (Bottom Left)
            Positioned(
              bottom: -25,
              left: -15,
              child: Container(
                width: 90.w,
                height: 90.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(14),
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(isDark ? 25 : 35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 16.sp,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.campaign_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    'Pengumuman & Agenda',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16.sp,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              'Pusat kegiatan, gotong royong & info warga',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withAlpha(200),
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        color: const Color(0xFF2FA2F1),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Stat Summary Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
                child: Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF131C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 25 : 6),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Total Agenda
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2FA2F1)
                                    .withAlpha(isDark ? 35 : 20),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.event_note_rounded,
                                color: const Color(0xFF2FA2F1),
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_events.length}',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    'Total Agenda',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white60
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 32.h,
                        width: 1,
                        color: isDark
                            ? Colors.white12
                            : const Color(0xFFE2E8F0),
                      ),
                      SizedBox(width: 12.w),
                      // Diikuti Saya
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withAlpha(isDark ? 35 : 20),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.how_to_reg_rounded,
                                color: const Color(0xFF10B981),
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$joinedCount',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    'Diikuti Saya',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white60
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Horizontal Filter Chips Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 6.h),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      'Semua',
                      'Diikuti Saya',
                      'RW 01',
                      'RW 02',
                      'RW 03',
                      'RW 04',
                    ].map((filter) {
                      final bool active = _selectedFilter == filter;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (filter == 'Diikuti Saya') ...[
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 14.sp,
                                  color: active
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white70
                                          : const Color(0xFF10B981)),
                                ),
                                SizedBox(width: 5.w),
                              ],
                              Text(filter),
                              if (filter == 'Diikuti Saya' && joinedCount > 0) ...[
                                SizedBox(width: 5.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 1.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: active
                                        ? Colors.white.withAlpha(50)
                                        : const Color(0xFF10B981).withAlpha(30),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Text(
                                    '$joinedCount',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      color: active
                                          ? Colors.white
                                          : const Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          selected: active,
                          showCheckmark: false,
                          avatar: null,
                          labelStyle: TextStyle(
                            color: active
                                ? Colors.white
                                : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF475569)),
                            fontSize: 12.sp,
                            fontWeight:
                                active ? FontWeight.bold : FontWeight.w600,
                          ),
                          backgroundColor: isDark
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          selectedColor: const Color(0xFF2FA2F1),
                          side: BorderSide(
                            color: active
                                ? const Color(0xFF2FA2F1)
                                : (isDark
                                    ? Colors.white10
                                    : const Color(0xFFE2E8F0)),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          elevation: active ? 2 : 0,
                          shadowColor: const Color(0xFF2FA2F1).withAlpha(80),
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 3.h,
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedFilter = filter),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            // Header Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedFilter == 'Diikuti Saya'
                          ? 'Agenda yang Diikuti'
                          : 'Daftar Agenda & Kegiatan',
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF334155),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2FA2F1)
                            .withAlpha(isDark ? 35 : 20),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        '${filteredEvents.length} Kegiatan',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2FA2F1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content List
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF2FA2F1)),
                ),
              )
            else if (filteredEvents.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(22.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2FA2F1)
                                .withAlpha(isDark ? 25 : 15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _selectedFilter == 'Diikuti Saya'
                                ? Icons.how_to_reg_outlined
                                : Icons.event_busy_rounded,
                            size: 48.sp,
                            color: const Color(0xFF2FA2F1),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          _selectedFilter == 'Diikuti Saya'
                              ? 'Belum Ada Agenda yang Diikuti'
                              : 'Belum Ada Kegiatan',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          _selectedFilter == 'Diikuti Saya'
                              ? 'Pilih agenda yang tersedia dan klik "Ikut Hadir" untuk mendaftarkan kehadiran Anda.'
                              : 'Tidak ada pengumuman kegiatan di "$_selectedFilter". Jadilah yang pertama membuat agenda!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5.sp,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        if (_selectedFilter == 'Diikuti Saya') ...[
                          SizedBox(height: 16.h),
                          OutlinedButton.icon(
                            onPressed: () =>
                                setState(() => _selectedFilter = 'Semua'),
                            icon: Icon(Icons.list_alt_rounded, size: 16.sp),
                            label: const Text('Lihat Semua Agenda'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2FA2F1),
                              side: const BorderSide(color: Color(0xFF2FA2F1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 80.h),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = filteredEvents[index];
                    final realIndex = _events.indexOf(item);
                    final bool isJoined = item['isJoined'] as bool;
                    final tipeConfig = _tipeOptions.firstWhere(
                      (t) => t['label'] == item['tipe'],
                      orElse: () => _tipeOptions[0],
                    );

                    return Container(
                      margin: EdgeInsets.only(bottom: 14.h),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF131C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(
                          color: isJoined
                              ? const Color(0xFF10B981)
                                  .withAlpha(isDark ? 60 : 40)
                              : (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFE2E8F0)),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 30 : 6),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Ribbon Header
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 10.h,
                            ),
                            decoration: BoxDecoration(
                              color: (tipeConfig['color'] as Color).withAlpha(
                                isDark ? 25 : 15,
                              ),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(17.r),
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color:
                                      (tipeConfig['color'] as Color).withAlpha(30),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(5.w),
                                  decoration: BoxDecoration(
                                    color: tipeConfig['color'] as Color,
                                    borderRadius: BorderRadius.circular(7.r),
                                  ),
                                  child: Icon(
                                    tipeConfig['icon'] as IconData,
                                    size: 13.sp,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  item['tipe'],
                                  style: TextStyle(
                                    color: tipeConfig['color'] as Color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                const Spacer(),
                                if (isJoined)
                                  Container(
                                    margin: EdgeInsets.only(right: 6.w),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 7.w,
                                      vertical: 2.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withAlpha(isDark ? 40 : 25),
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(
                                        color: const Color(0xFF10B981)
                                            .withAlpha(60),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 11.sp,
                                          color: const Color(0xFF10B981),
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'Terdaftar',
                                          style: TextStyle(
                                            fontSize: 10.5.sp,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF10B981),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (item['wilayah'].toString().isNotEmpty)
                                  Flexible(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 3.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E293B)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(6.r),
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.white10
                                              : const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.place_rounded,
                                            size: 11.sp,
                                            color: isDark
                                                ? Colors.white54
                                                : const Color(0xFF64748B),
                                          ),
                                          SizedBox(width: 4.w),
                                          Flexible(
                                            child: Text(
                                              item['wilayah'],
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10.5.sp,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white70
                                                    : const Color(0xFF475569),
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

                          // Poster Banner (jika pengumuman memiliki foto lampiran)
                          if (item['posterUrl'] != null && (item['posterUrl'] as String).isNotEmpty)
                            GestureDetector(
                              onTap: () => _showFullPosterDialog(item['posterUrl'], item['title']),
                              child: Stack(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: item['posterUrl'],
                                    width: double.infinity,
                                    height: 160.h,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 800,
                                    placeholder: (ctx, url) => Container(
                                      height: 160.h,
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF1F5F9),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF2FA2F1),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (ctx, url, err) => const SizedBox.shrink(),
                                  ),
                                  Positioned(
                                    right: 10.w,
                                    bottom: 10.h,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(140),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14.sp),
                                          SizedBox(width: 4.w),
                                          Text(
                                            'Lihat Foto',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.5.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Card Body
                          Padding(
                            padding: EdgeInsets.all(16.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  item['title'],
                                  style: TextStyle(
                                    fontSize: 15.5.sp,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    height: 1.3,
                                  ),
                                ),
                                SizedBox(height: 10.h),

                                // Schedule Row
                                if (item['jadwal'].toString().isNotEmpty)
                                  Container(
                                    margin: EdgeInsets.only(bottom: 8.h),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 7.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_rounded,
                                          size: 13.sp,
                                          color: const Color(0xFF2FA2F1),
                                        ),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: Text(
                                            item['jadwal'],
                                            style: TextStyle(
                                              fontSize: 11.5.sp,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white70
                                                  : const Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Location Row
                                if (item['lokasi'].toString().isNotEmpty)
                                  Container(
                                    margin: EdgeInsets.only(bottom: 8.h),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10.w,
                                      vertical: 7.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on_rounded,
                                          size: 13.sp,
                                          color: const Color(0xFFEF4444),
                                        ),
                                        SizedBox(width: 8.w),
                                        Expanded(
                                          child: Text(
                                            item['lokasi'],
                                            style: TextStyle(
                                              fontSize: 11.5.sp,
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white70
                                                  : const Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Note
                                if (item['note'].toString().isNotEmpty) ...[
                                  SizedBox(height: 2.h),
                                  Text(
                                    item['note'],
                                    style: TextStyle(
                                      fontSize: 11.5.sp,
                                      color: isDark
                                          ? Colors.white60
                                          : const Color(0xFF64748B),
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],

                                SizedBox(height: 12.h),
                                Divider(
                                  height: 1,
                                  color: isDark
                                      ? Colors.white10
                                      : const Color(0xFFF1F5F9),
                                ),
                                SizedBox(height: 12.h),

                                // Footer: Participants & Join Button
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981)
                                            .withAlpha(isDark ? 30 : 15),
                                        borderRadius:
                                            BorderRadius.circular(8.r),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.groups_rounded,
                                            size: 15.sp,
                                            color: const Color(0xFF10B981),
                                          ),
                                          SizedBox(width: 5.w),
                                          Text(
                                            '${item['participants']} Hadir',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11.sp,
                                              color: const Color(0xFF10B981),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (item['isCreator'] == true)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: 6.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2FA2F1)
                                              .withAlpha(isDark ? 40 : 18),
                                          borderRadius:
                                              BorderRadius.circular(10.r),
                                          border: Border.all(
                                            color: const Color(0xFF2FA2F1)
                                                .withAlpha(isDark ? 70 : 40),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.verified_user_rounded,
                                              size: 13.sp,
                                              color: const Color(0xFF2FA2F1),
                                            ),
                                            SizedBox(width: 5.w),
                                            Text(
                                              'Anda Koordinator',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11.sp,
                                                color: const Color(0xFF2FA2F1),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _handleToggleJoin(realIndex),
                                        icon: Icon(
                                          isJoined
                                              ? Icons.check_circle_rounded
                                              : Icons.how_to_reg_rounded,
                                          size: 14.sp,
                                        ),
                                        label: Text(
                                          isJoined
                                              ? 'Terdaftar'
                                              : 'Ikut Hadir',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5.sp,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isJoined
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF2FA2F1),
                                          foregroundColor: Colors.white,
                                          elevation: isJoined ? 0 : 2,
                                          shadowColor: const Color(0xFF2FA2F1)
                                              .withAlpha(100),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12.w,
                                            vertical: 7.h,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.r),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }, childCount: filteredEvents.length),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAgendaModal(context, isDark),
        backgroundColor: const Color(0xFF2FA2F1),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Buat Agenda',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
        ),
      ),
    );
  }

  void _showFullPosterDialog(String imageUrl, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(16.w),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.black87,
                borderRadius: BorderRadius.circular(16.r),
              ),
              padding: EdgeInsets.all(8.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => SizedBox(
                        height: 200.h,
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                      errorWidget: (_, _, _) => Container(
                        height: 150.h,
                        alignment: Alignment.center,
                        child: const Text('Gagal memuat gambar', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                  if (title.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MODAL / SHEET: BUAT PENGUMUMAN & AGENDA BARU
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _pickImageDirect(StateSetter setModalState, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setModalState(() {
          _posterImage = File(pickedFile.path);
        });
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error picking image: \$e");
    }
  }

  Future<void> _pickImage(StateSetter setModalState) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Text(
                  'Unggah Poster / Foto Agenda',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 16.h),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withAlpha(20),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0284C7)),
                  ),
                  title: const Text('Buka Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Ambil foto langsung', style: TextStyle(fontSize: 11)),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(20),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFF10B981)),
                  ),
                  title: const Text('Galeri Foto', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Pilih dari penyimpanan galeri', style: TextStyle(fontSize: 11)),
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source != null) {
      await _pickImageDirect(setModalState, source);
    }
  }

  void _showCreateAgendaModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF090D16) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.88,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, scrollController) {
                return Column(
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                        width: 40.w,
                        height: 4.h,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 4.h, 16.w, 12.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Buat Agenda / Pengumuman',
                            style: TextStyle(
                              fontSize: 16.5.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _buildRedesignedCreationForm(
                        isDark,
                        setModalState,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // FORM COMPONENT FOR AGENDA CREATION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildRedesignedCreationForm(bool isDark, StateSetter setModalState) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 50.h),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. SELECTOR TIPE PENGUMUMAN ──
            _buildSectionHeader(
              title: 'Tipe Informasi / Kegiatan',
              subtitle: 'Pilih jenis publikasi agar warga mudah mengenali',
              isDark: isDark,
            ),
            SizedBox(height: 10.h),
            Row(
              children: _tipeOptions.map((opt) {
                final bool isSelected = _formTipe == opt['label'];
                final color = opt['color'] as Color;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3.w),
                    child: InkWell(
                      onTap: () {
                        setModalState(() => _formTipe = opt['label']);
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(14.r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: EdgeInsets.symmetric(
                          vertical: 12.h,
                          horizontal: 8.w,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withAlpha(isDark ? 40 : 20)
                              : (isDark
                                  ? const Color(0xFF131C2E)
                                  : Colors.white),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : (isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFE2E8F0)),
                            width: isSelected ? 1.8 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withAlpha(50),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? color
                                    : (isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF1F5F9)),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                opt['icon'] as IconData,
                                size: 18.sp,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white60
                                        : const Color(0xFF64748B)),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              opt['label'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? (isDark ? Colors.white : color)
                                    : (isDark
                                        ? Colors.white70
                                        : const Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 22.h),

            // ── 2. CARD: INFORMASI UTAMA ──
            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    title: 'Judul & Detail Agenda',
                    subtitle: 'Tuliskan nama kegiatan yang jelas dan menarik',
                    isDark: isDark,
                  ),
                  SizedBox(height: 12.h),

                  // Judul Field
                  TextFormField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: _inputDecoration(
                      hintText: 'Contoh: Gotong Royong Kebersihan Parit',
                      isDark: isDark,
                      icon: Icons.title_rounded,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Judul wajib diisi'
                        : null,
                  ),
                  SizedBox(height: 14.h),

                  // Catatan / Keterangan Field
                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: _inputDecoration(
                      hintText:
                          'Instruksi tambahan (misal: membawa cangkul/sapu lidi, konsumsi disediakan)...',
                      isDark: isDark,
                      icon: Icons.notes_rounded,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 18.h),

            // ── 3. CARD: CAKUPAN WILAYAH ──
            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    title: 'Target Wilayah Penerima',
                    subtitle:
                        'Tentukan siapa saja warga yang akan melihat info ini',
                    isDark: isDark,
                  ),
                  SizedBox(height: 12.h),

                  // Dropdown Scope
                  DropdownButtonFormField<String>(
                    initialValue: _targetScope,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    dropdownColor: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    decoration: _inputDecoration(
                      hintText: 'Pilih Cakupan Wilayah',
                      isDark: isDark,
                      icon: Icons.public_rounded,
                    ),
                    items: _scopeList
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => _targetScope = val);
                        setState(() {});
                      }
                    },
                  ),

                  if (_targetScope != 'Seluruh Desa (Umum)') ...[
                    SizedBox(height: 12.h),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRw,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      dropdownColor: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      decoration: _inputDecoration(
                        hintText: 'Pilih RW / Dusun',
                        isDark: isDark,
                        icon: Icons.holiday_village_outlined,
                      ),
                      items: _rwList
                          .map(
                            (rw) =>
                                DropdownMenuItem(value: rw, child: Text(rw)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            _selectedRw = val;
                            _selectedRt = _rtOptions[val]?.first ?? 'RT 01';
                          });
                          setState(() {});
                        }
                      },
                    ),
                  ],

                  if (_targetScope == 'Spesifik Lingkungan RT') ...[
                    SizedBox(height: 12.h),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRt,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      dropdownColor: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      decoration: _inputDecoration(
                        hintText: 'Pilih RT',
                        isDark: isDark,
                        icon: Icons.home_work_outlined,
                      ),
                      items: (_rtOptions[_selectedRw] ?? ['RT 01'])
                          .map(
                            (rt) =>
                                DropdownMenuItem(value: rt, child: Text(rt)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => _selectedRt = val);
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 18.h),

            // ── 4. CARD: WAKTU & TEMPAT PELAKSANAAN ──
            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    title: 'Jadwal & Lokasi Titik Temu',
                    subtitle: 'Kapan dan di mana warga harus berkumpul',
                    isDark: isDark,
                  ),
                  SizedBox(height: 12.h),

                  // Jadwal with Auto Picker Button
                  TextFormField(
                    controller: _scheduleController,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: _inputDecoration(
                      hintText: 'Pilih atau ketik jadwal pelaksanaan',
                      isDark: isDark,
                      icon: Icons.calendar_month_rounded,
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.event_available_rounded,
                          color: Color(0xFF2FA2F1),
                        ),
                        tooltip: 'Pilih Tanggal & Jam',
                        onPressed: _pickDateTime,
                      ),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Jadwal wajib diisi'
                        : null,
                  ),
                  SizedBox(height: 6.h),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: _pickDateTime,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 2.h,
                          horizontal: 4.w,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 13.sp,
                              color: const Color(0xFF2FA2F1),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Buka Kalender & Waktu',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2FA2F1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 14.h),

                  // Lokasi
                  TextFormField(
                    controller: _locationController,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: _inputDecoration(
                      hintText: 'Contoh: Halaman Pos Ronda RT 02',
                      isDark: isDark,
                      icon: Icons.place_rounded,
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Lokasi wajib diisi'
                        : null,
                  ),

                  // Quick Suggestion Chips for Location
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: _quickLocations.map((loc) {
                      return InkWell(
                        onTap: () {
                          setModalState(() => _locationController.text = loc);
                          setState(() {});
                        },
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_location_alt_outlined,
                                size: 11.sp,
                                color: const Color(0xFF2FA2F1),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                loc,
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 18.h),

            // ── 5. LAMPIRAN POSTER / GAMBAR ──
            _buildCardWrapper(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    title: 'Poster / Gambar Pendukung',
                    subtitle:
                        'Opsional: Tambahkan foto untuk menarik perhatian warga',
                    isDark: isDark,
                  ),
                  SizedBox(height: 12.h),
                  if (_posterImage == null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _pickImage(setModalState),
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 36.sp,
                                color: const Color(0xFF2FA2F1),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Unggah Poster / Foto Kegiatan',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Ketuk untuk memilih dari Kamera atau Galeri',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: isDark
                                      ? Colors.white60
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: const Color(0xFF2FA2F1).withAlpha(100),
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.file(
                              _posterImage!,
                              width: 60.w,
                              height: 60.h,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Foto / Poster Terpilih',
                                  style: TextStyle(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  _posterImage!.path.split(Platform.pathSeparator).last,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Ganti foto',
                            icon: Icon(
                              Icons.refresh_rounded,
                              color: const Color(0xFF2FA2F1),
                              size: 22.sp,
                            ),
                            onPressed: () => _pickImage(setModalState),
                          ),
                          IconButton(
                            tooltip: 'Hapus foto',
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                              size: 22.sp,
                            ),
                            onPressed: () {
                              setModalState(() {
                                _posterImage = null;
                              });
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            SizedBox(height: 30.h),

            // ── 6. SUBMIT BUTTON ──
            Container(
              width: double.infinity,
              height: 48.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2FA2F1), Color(0xFF0284C7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2FA2F1).withAlpha(100),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmitEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 22.w,
                        height: 22.h,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18.sp),
                          SizedBox(width: 8.w),
                          Text(
                            'Publikasikan Sekarang',
                            style: TextStyle(
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
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

  // ═══════════════════════════════════════════════════════════════════
  // REUSABLE HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14.sp,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.5.sp,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildCardWrapper({required Widget child, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required bool isDark,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 12.sp,
        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
      ),
      prefixIcon: Icon(icon, size: 18.sp, color: const Color(0xFF2FA2F1)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFF2FA2F1), width: 1.8),
      ),
    );
  }
}
