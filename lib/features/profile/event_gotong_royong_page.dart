import 'package:flutter/material.dart';
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
    setState(() => _isLoading = true);
    final data = await _eventService.getEvents();
    if (!mounted) return;
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
        };
      }).toList();
      _isLoading = false;
    });
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
                size: 20,
              ),
              const SizedBox(width: 10),
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
            borderRadius: BorderRadius.circular(12),
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
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response['status'] == 'success') {
      _titleController.clear();
      _scheduleController.clear();
      _locationController.clear();
      _noteController.clear();
      _tabController.animateTo(0);
      await _loadEvents();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.celebration_rounded, color: Colors.white, size: 22),
              SizedBox(width: 10),
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
            borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
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
          ? const Color(0xFF090D16)
          : const Color(0xFFF4F6FA),
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
                  : const Color(0xFF1E3A8A),
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(isDark ? 25 : 35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 16,
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
                                  const Color(0xFF2563EB),
                                  const Color(0xFF1D4ED8),
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
                      left: 20,
                      right: 20,
                      top: MediaQuery.of(context).padding.top + 52,
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pengumuman & Agenda',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Pusat kegiatan, gotong royong & info warga',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
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
                preferredSize: const Size.fromHeight(54),
                child: Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF090D16)
                        : const Color(0xFFF4F6FA),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(11),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withAlpha(80),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark
                          ? Colors.white60
                          : const Color(0xFF64748B),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                      dividerColor: Colors.transparent,
                      tabs: [
                        const Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_note_rounded, size: 16),
                              SizedBox(width: 6),
                              Text('Daftar Kegiatan'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.history_rounded, size: 16),
                              const SizedBox(width: 6),
                              const Text('Riwayat'),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(50),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_events.where((e) => e['isJoined'] == true).length}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
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
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Buat Agenda',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
      color: const Color(0xFF2563EB),
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
                            padding: const EdgeInsets.only(right: 8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: FilterChip(
                                label: Text(filter),
                                selected: active,
                                showCheckmark: false,
                                avatar: active
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                                labelStyle: TextStyle(
                                  color: active
                                      ? Colors.white
                                      : (isDark
                                            ? Colors.white70
                                            : const Color(0xFF475569)),
                                  fontSize: 12,
                                  fontWeight: active
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                ),
                                backgroundColor: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                selectedColor: const Color(0xFF2563EB),
                                side: BorderSide(
                                  color: active
                                      ? const Color(0xFF2563EB)
                                      : (isDark
                                            ? Colors.white10
                                            : const Color(0xFFE2E8F0)),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: active ? 2 : 0,
                                shadowColor: const Color(
                                  0xFF2563EB,
                                ).withAlpha(80),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Agenda & Pengumuman Aktif',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF2563EB,
                      ).withAlpha(isDark ? 35 : 20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${filteredEvents.length} Kegiatan',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
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
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF2563EB,
                          ).withAlpha(isDark ? 25 : 15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.event_busy_rounded,
                          size: 48,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum Ada Kegiatan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tidak ada pengumuman kegiatan di "$_selectedFilter". Jadilah yang pertama membuat agenda!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _showCreateAgendaModal(context, isDark),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Buat Agenda Baru'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131C2E) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: (tipeConfig['color'] as Color).withAlpha(
                              isDark ? 25 : 15,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(17),
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
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: tipeConfig['color'] as Color,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  tipeConfig['icon'] as IconData,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item['tipe'],
                                style: TextStyle(
                                  color: tipeConfig['color'] as Color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              if (item['wilayah'].toString().isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
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
                                        size: 12,
                                        color: isDark
                                            ? Colors.white54
                                            : const Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item['wilayah'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Card Body
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                item['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Schedule Row
                              if (item['jadwal'].toString().isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_rounded,
                                        size: 14,
                                        color: Color(0xFF2563EB),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item['jadwal'],
                                          style: TextStyle(
                                            fontSize: 12,
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
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        size: 14,
                                        color: Color(0xFFEF4444),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item['lokasi'],
                                          style: TextStyle(
                                            fontSize: 12,
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
                                const SizedBox(height: 4),
                                Text(
                                  item['note'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white60
                                        : const Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],

                              const SizedBox(height: 14),
                              Divider(
                                height: 1,
                                color: isDark
                                    ? Colors.white10
                                    : const Color(0xFFF1F5F9),
                              ),
                              const SizedBox(height: 12),

                              // Footer: Participants & Join Button
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withAlpha(isDark ? 30 : 15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.people_alt_rounded,
                                          size: 15,
                                          color: Color(0xFF10B981),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          '${item['participants']} Siap Hadir',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5,
                                            color: Color(0xFF10B981),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _handleToggleJoin(realIndex),
                                    icon: Icon(
                                      isJoined
                                          ? Icons.check_circle_rounded
                                          : Icons.handshake_rounded,
                                      size: 15,
                                    ),
                                    label: Text(
                                      isJoined
                                          ? 'Telah Terdaftar'
                                          : 'Ikut Hadir',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withAlpha(isDark ? 50 : 35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history_edu_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${joinedEvents.length} Kegiatan Terdaftar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Riwayat partisipasi agenda dan gotong royong Anda',
                            style: TextStyle(
                              fontSize: 11.5,
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
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF2563EB,
                          ).withAlpha(isDark ? 25 : 15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.history_toggle_off_rounded,
                          size: 48,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum Ada Riwayat Partisipasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Pilih kegiatan pada tab "Daftar Kegiatan" dan tekan tombol "Ikut Hadir" untuk berpartisipasi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: () => _tabController.animateTo(0),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Jelajahi Kegiatan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131C2E) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withAlpha(isDark ? 35 : 15),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(17),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: Color(0xFF10B981),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Terdaftar Mengikuti',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF059669),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: (tipeConfig['color'] as Color)
                                      .withAlpha(isDark ? 40 : 25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item['tipe'],
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: tipeConfig['color'] as Color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'],
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _buildEventMetaRow(
                                icon: Icons.calendar_month_rounded,
                                text: item['jadwal'],
                                isDark: isDark,
                              ),
                              const SizedBox(height: 6),
                              _buildEventMetaRow(
                                icon: Icons.place_rounded,
                                text: '${item['lokasi']} (${item['wilayah']})',
                                isDark: isDark,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Koordinator: ${item['koordinator']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? Colors.white54
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () =>
                                        _handleToggleJoin(realIndex),
                                    icon: const Icon(
                                      Icons.cancel_outlined,
                                      size: 14,
                                      color: Colors.redAccent,
                                    ),
                                    label: const Text(
                                      'Batal Ikut',
                                      style: TextStyle(
                                        fontSize: 11,
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
  void _showCreateAgendaModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF090D16) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
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
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
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
                          fontSize: 16.5,
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
                Expanded(child: _buildRedesignedCreationForm(isDark)),
              ],
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // FORM COMPONENT FOR AGENDA CREATION
  // ═══════════════════════════════════════════════════════════════════
  Widget _buildRedesignedCreationForm(bool isDark) {
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
            const SizedBox(height: 10),
            Row(
              children: _tipeOptions.map((opt) {
                final bool isSelected = _formTipe == opt['label'];
                final color = opt['color'] as Color;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => setState(() => _formTipe = opt['label']),
                      borderRadius: BorderRadius.circular(14),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withAlpha(isDark ? 40 : 20)
                              : (isDark
                                    ? const Color(0xFF131C2E)
                                    : Colors.white),
                          borderRadius: BorderRadius.circular(14),
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
                              padding: const EdgeInsets.all(8),
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
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.white60
                                          : const Color(0xFF64748B)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              opt['label'],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
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

            const SizedBox(height: 22),

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
                  const SizedBox(height: 12),

                  // Judul Field
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 13.5,
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
                  const SizedBox(height: 14),

                  // Catatan / Keterangan Field
                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
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

            const SizedBox(height: 18),

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
                  const SizedBox(height: 12),

                  // Dropdown Scope
                  DropdownButtonFormField<String>(
                    initialValue: _targetScope,
                    style: TextStyle(
                      fontSize: 13.5,
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
                      if (val != null) setState(() => _targetScope = val);
                    },
                  ),

                  if (_targetScope != 'Seluruh Desa (Umum)') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRw,
                      style: TextStyle(
                        fontSize: 13.5,
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
                          setState(() {
                            _selectedRw = val;
                            _selectedRt = _rtOptions[val]?.first ?? 'RT 01';
                          });
                        }
                      },
                    ),
                  ],

                  if (_targetScope == 'Spesifik Lingkungan RT') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRt,
                      style: TextStyle(
                        fontSize: 13.5,
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
                        if (val != null) setState(() => _selectedRt = val);
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 18),

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
                  const SizedBox(height: 12),

                  // Jadwal with Auto Picker Button
                  TextFormField(
                    controller: _scheduleController,
                    style: const TextStyle(
                      fontSize: 13,
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
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: _pickDateTime,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 4,
                        ),
                        child: Text(
                          '📅 Buka Kalender & Waktu',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Lokasi
                  TextFormField(
                    controller: _locationController,
                    style: const TextStyle(
                      fontSize: 13,
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _quickLocations.map((loc) {
                      return InkWell(
                        onTap: () =>
                            setState(() => _locationController.text = loc),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_location_alt_outlined,
                                size: 11,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                loc,
                                style: TextStyle(
                                  fontSize: 10.5,
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

            const SizedBox(height: 30),

            // ── 5. SUBMIT BUTTON ──
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withAlpha(100),
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
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Publikasikan Sekarang',
                            style: TextStyle(
                              fontSize: 14.5,
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
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildCardWrapper({required Widget child, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C2E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
          size: 14,
          color: isDark ? Colors.white60 : const Color(0xFF64748B),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
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
        fontSize: 12,
        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
      ),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
      ),
    );
  }
}
