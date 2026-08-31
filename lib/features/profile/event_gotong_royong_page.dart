import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:siladesbeng_mobile/services/event_service.dart';

class EventGotongRoyongPage extends StatefulWidget {
  const EventGotongRoyongPage({super.key});

  @override
  State<EventGotongRoyongPage> createState() => _EventGotongRoyongPageState();
}

class _EventGotongRoyongPageState extends State<EventGotongRoyongPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'Semua Wilayah';
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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadEvents();
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
    _tabController.dispose();
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
              seedColor: const Color(0xFF2563EB),
              primary: const Color(0xFF2563EB),
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
                seedColor: const Color(0xFF2563EB),
                primary: const Color(0xFF2563EB),
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
                  style: TextStyle(fontWeight: FontWeight.w600),
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
      Navigator.pop(context);
      _tabController.animateTo(0);
      await _loadEvents();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.celebration_rounded, color: Colors.white, size: 22.sp),
              SizedBox(width: 10.w),
              Expanded(
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

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1120)
          : const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 175,
              pinned: true,
              floating: false,
              elevation: 0,
              scrolledUnderElevation: 2,
              backgroundColor: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF2FA2F1),
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
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  const Color(0xFF0F172A),
                                  const Color(0xFF1E293B),
                                ]
                              : [
                                  const Color(0xFF2FA2F1),
                                  const Color(0xFF0284C7),
                                ],
                        ),
                      ),
                    ),
                    // Ambient light circle 1 (Top Right)
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(22),
                        ),
                      ),
                    ),
                    // Ambient light circle 2 (Bottom Left)
                    Positioned(
                      left: -20,
                      bottom: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(14),
                        ),
                      ),
                    ),
                    // Title info in header (positioned with generous breathing room below back button)
                    Positioned(
                      left: 20.w,
                      right: 20.w,
                      top: MediaQuery.of(context).padding.top + 52,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengumuman & Agenda',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'Pusat kegiatan, gotong royong & info warga',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF090D16) : Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24.r),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? Colors.white10
                            : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: UnderlineTabIndicator(
                      borderSide: const BorderSide(
                        width: 3.5,
                        color: Color(0xFF2FA2F1),
                      ),
                      borderRadius: BorderRadius.circular(3.r),
                      insets: EdgeInsets.symmetric(horizontal: 16.w),
                    ),
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: const Color(0xFF2FA2F1),
                    unselectedLabelColor: isDark
                        ? Colors.white60
                        : const Color(0xFF64748B),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.sp,
                      letterSpacing: 0.2,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5.sp,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        height: 48,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_note_rounded, size: 18.sp),
                            SizedBox(width: 8.w),
                            Text('Daftar Kegiatan'),
                          ],
                        ),
                      ),
                      Tab(
                        height: 48,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history_rounded, size: 18.sp),
                            SizedBox(width: 8.w),
                            const Text('Riwayat'),
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 7.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2FA2F1,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                '${_events.where((e) => e['isJoined'] == true).length}',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2FA2F1),
                                ),
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
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildEventsListTab(isDark),
            _buildHistoryEventsTab(isDark),
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

  // ═══════════════════════════════════════════════════════════════════
  // TAB 1: DAFTAR KEGIATAN (MODERN FEED STYLE)
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildEventsListTab(bool isDark) {
    final filteredEvents = _selectedFilter == 'Semua Wilayah'
        ? _events
        : _events
              .where((e) => (e['wilayah'] as String).contains(_selectedFilter))
              .toList();

    return RefreshIndicator(
      onRefresh: _loadEvents,
      color: const Color(0xFF2FA2F1),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Filter Chips Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children:
                      ['Semua Wilayah', 'RW 01', 'RW 02', 'RW 03', 'RW 04'].map(
                        (filter) {
                          final bool active = _selectedFilter == filter;
                          return Padding(
                            padding: EdgeInsets.only(right: 8.w),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: FilterChip(
                                label: Text(filter),
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
                                  fontWeight: active
                                      ? FontWeight.bold
                                      : FontWeight.w600,
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
                                shadowColor: const Color(
                                  0xFF2FA2F1,
                                ).withAlpha(80),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 2.h,
                                ),
                                onSelected: (_) =>
                                    setState(() => _selectedFilter = filter),
                              ),
                            ),
                          );
                        },
                      ).toList(),
                ),
              ),
            ),
          ),

          // Event Count Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Agenda & Pengumuman Aktif',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF2FA2F1,
                      ).withAlpha(isDark ? 35 : 20),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      '${filteredEvents.length} Kegiatan',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2FA2F1),
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
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
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
                          color: const Color(
                            0xFF2563EB,
                          ).withAlpha(isDark ? 25 : 15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event_busy_rounded,
                          size: 48.sp,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Belum Ada Kegiatan',
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
                        'Tidak ada pengumuman kegiatan di "$_selectedFilter". Jadilah yang pertama membuat agenda!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
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
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
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
                            vertical: 12.h,
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
                                color: (tipeConfig['color'] as Color).withAlpha(
                                  30,
                                ),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(6.w),
                                decoration: BoxDecoration(
                                  color: tipeConfig['color'] as Color,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  tipeConfig['icon'] as IconData,
                                  size: 14.sp,
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
                              SizedBox(width: 8.w),
                              if (item['wilayah'].toString().isNotEmpty)
                                Flexible(
                                  child: Align(
                                    alignment: Alignment.centerRight,
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
                                            size: 12.sp,
                                            color: isDark
                                                ? Colors.white54
                                                : const Color(0xFF64748B),
                                          ),
                                          SizedBox(width: 4.w),
                                          Flexible(
                                            child: Text(
                                              item['wilayah'],
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? Colors.white70
                                                    : const Color(0xFF475569),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
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
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  height: 1.3,
                                ),
                              ),
                              SizedBox(height: 12.h),

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
                                        size: 14.sp,
                                        color: Color(0xFF2563EB),
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          item['jadwal'],
                                          style: TextStyle(
                                            fontSize: 12.sp,
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
                                        size: 14.sp,
                                        color: Color(0xFFEF4444),
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          item['lokasi'],
                                          style: TextStyle(
                                            fontSize: 12.sp,
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
                                SizedBox(height: 4.h),
                                Text(
                                  item['note'],
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: isDark
                                        ? Colors.white60
                                        : const Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],

                              SizedBox(height: 14.h),
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
                                      color: const Color(
                                        0xFF10B981,
                                      ).withAlpha(isDark ? 30 : 15),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.people_alt_rounded,
                                          size: 15.sp,
                                          color: Color(0xFF10B981),
                                        ),
                                        SizedBox(width: 5.w),
                                        Text(
                                          '${item['participants']} Siap Hadir',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5.sp,
                                            color: Color(0xFF10B981),
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
                                        color: const Color(
                                          0xFF2563EB,
                                        ).withAlpha(isDark ? 40 : 18),
                                        borderRadius: BorderRadius.circular(10.r),
                                        border: Border.all(
                                          color: const Color(
                                            0xFF2563EB,
                                          ).withAlpha(isDark ? 70 : 40),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.verified_user_rounded,
                                            size: 14.sp,
                                            color: Color(0xFF2563EB),
                                          ),
                                          SizedBox(width: 5.w),
                                          Text(
                                            'Anda Koordinator',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11.5.sp,
                                              color: Color(0xFF2563EB),
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
                                            : Icons.handshake_rounded,
                                        size: 15.sp,
                                      ),
                                      label: Text(
                                        isJoined
                                            ? 'Telah Terdaftar'
                                            : 'Ikut Hadir',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isJoined
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF2563EB),
                                        foregroundColor: Colors.white,
                                        elevation: isJoined ? 0 : 2,
                                        shadowColor: const Color(
                                          0xFF2563EB,
                                        ).withAlpha(100),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14.w,
                                          vertical: 8.h,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // TAB 2: RIWAYAT KEGIATAN & PARTISIPASI WARGA
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildHistoryEventsTab(bool isDark) {
    final joinedEvents = _events.where((e) => e['isJoined'] == true).toList();

    return RefreshIndicator(
      onRefresh: _loadEvents,
      color: const Color(0xFF2563EB),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Stat Summary Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withAlpha(isDark ? 50 : 35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history_edu_rounded,
                        color: Colors.white,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${joinedEvents.length} Kegiatan Terdaftar',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E3A8A),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Riwayat partisipasi agenda dan gotong royong Anda',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF475569),
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

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF2563EB)),
              ),
            )
          else if (joinedEvents.isEmpty)
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
                          color: const Color(
                            0xFF2563EB,
                          ).withAlpha(isDark ? 25 : 15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.history_toggle_off_rounded,
                          size: 48.sp,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Belum Ada Riwayat Partisipasi',
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
                        'Pilih kegiatan pada tab "Daftar Kegiatan" dan tekan tombol "Ikut Hadir" untuk berpartisipasi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: isDark
                              ? Colors.white60
                              : Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 18.h),
                      OutlinedButton.icon(
                        onPressed: () => _tabController.animateTo(0),
                        icon: Icon(Icons.arrow_back_rounded, size: 18.sp),
                        label: const Text('Jelajahi Kegiatan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = joinedEvents[index];
                  final realIndex = _events.indexOf(item);
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
                        color: const Color(
                          0xFF10B981,
                        ).withAlpha(isDark ? 60 : 40),
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
                        // Ribbon
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withAlpha(isDark ? 35 : 15),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(17.r),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16.sp,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'Terdaftar Mengikuti',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF059669),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: (tipeConfig['color'] as Color)
                                      .withAlpha(isDark ? 40 : 25),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  item['tipe'],
                                  style: TextStyle(
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: tipeConfig['color'] as Color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'],
                                style: TextStyle(
                                  fontSize: 15.5.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 10.h),
                              _buildEventMetaRow(
                                icon: Icons.calendar_month_rounded,
                                text: item['jadwal'],
                                isDark: isDark,
                              ),
                              SizedBox(height: 6.h),
                              _buildEventMetaRow(
                                icon: Icons.place_rounded,
                                text: '${item['lokasi']} (${item['wilayah']})',
                                isDark: isDark,
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Koordinator: ${item['koordinator']}',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: isDark
                                          ? Colors.white54
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () =>
                                        _handleToggleJoin(realIndex),
                                    icon: Icon(
                                      Icons.cancel_outlined,
                                      size: 14.sp,
                                      color: Colors.redAccent,
                                    ),
                                    label: Text(
                                      'Batal Ikut',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.redAccent,
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
                }, childCount: joinedEvents.length),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // MODAL / SHEET: BUAT PENGUMUMAN & AGENDA BARU
  // ═══════════════════════════════════════════════════════════════════
  Future<void> _pickImage(StateSetter setModalState) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setModalState(() {
          _posterImage = File(pickedFile.path);
        });
        setState(() {}); // update parent too just in case
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
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
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
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
                Expanded(child: _buildRedesignedCreationForm(isDark, setModalState)),
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 50),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. SELECTOR TIPE PENGUMUMAN (INTERACTIVE CARDS) ──
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
                    style: TextStyle(fontSize: 13.sp),
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
                    ),
                    decoration: _inputDecoration(
                      hintText: 'Pilih atau ketik jadwal pelaksanaan',
                      isDark: isDark,
                      icon: Icons.calendar_month_rounded,
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.event_available_rounded,
                          color: Color(0xFF2563EB),
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
                        child: Text(
                          '📅 Buka Kalender & Waktu',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
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
                    spacing: 6,
                    runSpacing: 6,
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
                                color: Color(0xFF2563EB),
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
                    subtitle: 'Opsional: Tambahkan foto untuk menarik perhatian warga',
                    isDark: isDark,
                  ),
                  SizedBox(height: 12.h),
                  if (_posterImage == null)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Gunakan StatefulBuilder setModalState
                          _pickImage(setModalState);
                        },
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
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 36.sp,
                                color: isDark ? Colors.white60 : Colors.grey[500],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Klik untuk memilih gambar',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.grey[600],
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
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gambar Terpilih',
                                  style: TextStyle(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  _posterImage!.path.split('/').last,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: isDark ? Colors.white70 : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
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

            // ── 5. SUBMIT BUTTON ──
            Container(
              width: double.infinity,
              height: 50,
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
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
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

  Widget _buildEventMetaRow({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14.sp,
          color: isDark ? Colors.white60 : const Color(0xFF64748B),
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ),
      ],
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
      prefixIcon: Icon(icon, size: 18.sp, color: const Color(0xFF2563EB)),
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
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
      ),
    );
  }
}
