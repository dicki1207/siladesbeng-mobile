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

  final List<String> _tipeOptions = [
    'Gotong Royong',
    'Acara / Event',
    'Pengumuman',
  ];

  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          'wilayah': '${item['rw'] ?? ''} ${item['rt'] != null ? '- ${item['rt']}' : ''}'.trim(),
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

  Future<void> _handleToggleJoin(int idx) async {
    final eventId = _events[idx]['id'];
    if (eventId == null) return;

    final response = await _eventService.toggleJoin(eventId);
    if (!mounted) return;

    if (response['status'] == 'success') {
      setState(() {
        _events[idx]['isJoined'] = response['joined'] ?? !(_events[idx]['isJoined'] as bool);
        _events[idx]['participants'] = response['jumlah_peserta'] ?? _events[idx]['participants'];
      });

      final bool isJoined = _events[idx]['isJoined'] as bool;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isJoined
                ? 'Terima kasih! Anda tercatat siap hadir.'
                : 'Partisipasi dibatalkan.',
          ),
          backgroundColor: isJoined ? const Color(0xFF10B981) : const Color(0xFF64748B),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      _tabController.index = 0;
      await _loadEvents();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pengumuman kegiatan berhasil dipublikasikan!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Gagal membuat pengumuman'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pengumuman & Kegiatan',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          tabs: const [
            Tab(text: 'Daftar Kegiatan'),
            Tab(text: 'Buat Pengumuman'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEventsListTab(isDark, primaryColor),
          _buildCleanCreationFormTab(isDark),
        ],
      ),
    );
  }

  // TAB 1: DAFTAR KEGIATAN & PENGUMUMAN
  Widget _buildEventsListTab(bool isDark, Color primaryColor) {
    final filteredEvents = _selectedFilter == 'Semua Wilayah'
        ? _events
        : _events.where((e) => (e['wilayah'] as String).contains(_selectedFilter)).toList();

    return RefreshIndicator(
      onRefresh: _loadEvents,
      color: primaryColor,
      child: Column(
        children: [
          // Filter Chips Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['Semua Wilayah', 'RW 01', 'RW 02', 'RW 03', 'RW 04'].map((filter) {
                  final bool active = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: active,
                      selectedColor: const Color(0xFF2563EB),
                      labelStyle: TextStyle(
                        color: active
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        fontSize: 12,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: active
                              ? const Color(0xFF2563EB)
                              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      elevation: 0,
                      onSelected: (_) => setState(() => _selectedFilter = filter),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withAlpha(15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.event_note_outlined,
                                size: 48,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Belum ada pengumuman kegiatan\ndi wilayah "$_selectedFilter"',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredEvents.length,
                        itemBuilder: (context, index) {
                          final item = filteredEvents[index];
                          final realIndex = _events.indexOf(item);
                          final bool isJoined = item['isJoined'] as bool;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(isDark ? 20 : 6),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Row: Type Badge + Wilayah
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB).withAlpha(15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item['tipe'],
                                          style: const TextStyle(
                                            color: Color(0xFF2563EB),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      if (item['wilayah'].toString().isNotEmpty)
                                        Text(
                                          item['wilayah'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.white54 : Colors.grey[500],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Judul
                                  Text(
                                    item['title'],
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Jadwal & Lokasi
                                  if (item['jadwal'].toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 5),
                                      child: Row(
                                        children: [
                                          Icon(Icons.schedule, size: 14, color: isDark ? Colors.white60 : Colors.grey[600]),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              item['jadwal'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.white70 : const Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  if (item['lokasi'].toString().isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 14, color: isDark ? Colors.white60 : Colors.grey[600]),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            item['lokasi'],
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.white70 : const Color(0xFF475569),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                  if (item['note'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      item['note'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                        height: 1.35,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],

                                  const SizedBox(height: 14),
                                  Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                                  const SizedBox(height: 12),

                                  // Action Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.groups_outlined, size: 18, color: const Color(0xFF2563EB)),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${item['participants']} Warga Hadir',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 34,
                                        child: ElevatedButton(
                                          onPressed: () => _handleToggleJoin(realIndex),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isJoined
                                                ? const Color(0xFF10B981)
                                                : const Color(0xFF2563EB),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          child: Text(
                                            isJoined ? 'Terdaftar Hadir' : 'Siap Hadir',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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

  // TAB 2: BUAT PENGUMUMAN (CLEAN & RINGKAS)
  Widget _buildCleanCreationFormTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tipe Informasi
            Text(
              'Tipe Pengumuman',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _tipeOptions.map((tipe) {
                  final bool isSelected = _formTipe == tipe;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(tipe),
                      selected: isSelected,
                      selectedColor: const Color(0xFF2563EB),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      elevation: 0,
                      onSelected: (_) => setState(() => _formTipe = tipe),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            // 2. Judul Pengumuman
            Text(
              'Judul Kegiatan / Pengumuman',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(fontSize: 13.5),
              decoration: _inputDecoration(
                hintText: 'Contoh: Gotong Royong Kebersihan Lingkungan',
                isDark: isDark,
                icon: Icons.title_rounded,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
            ),

            const SizedBox(height: 16),

            // 3. Cakupan Wilayah
            Text(
              'Target Wilayah',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _targetScope,
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              decoration: _inputDecoration(
                hintText: 'Pilih Cakupan',
                isDark: isDark,
                icon: Icons.public_rounded,
              ),
              items: _scopeList.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
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
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                decoration: _inputDecoration(
                  hintText: 'Pilih RW',
                  isDark: isDark,
                  icon: Icons.holiday_village_outlined,
                ),
                items: _rwList.map((rw) => DropdownMenuItem(value: rw, child: Text(rw))).toList(),
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
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                decoration: _inputDecoration(
                  hintText: 'Pilih RT',
                  isDark: isDark,
                  icon: Icons.home_work_outlined,
                ),
                items: (_rtOptions[_selectedRw] ?? ['RT 01'])
                    .map((rt) => DropdownMenuItem(value: rt, child: Text(rt)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedRt = val);
                },
              ),
            ],

            const SizedBox(height: 16),

            // 4. Jadwal & Waktu
            Text(
              'Jadwal & Waktu Pelaksanaan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _scheduleController,
              style: const TextStyle(fontSize: 13.5),
              decoration: _inputDecoration(
                hintText: 'Contoh: Minggu, 24 Agustus 2026 - Pukul 07.30 WIB',
                isDark: isDark,
                icon: Icons.calendar_month_outlined,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Jadwal wajib diisi' : null,
            ),

            const SizedBox(height: 16),

            // 5. Lokasi Kegiatan
            Text(
              'Lokasi Kumpul / Titik Kegiatan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _locationController,
              style: const TextStyle(fontSize: 13.5),
              decoration: _inputDecoration(
                hintText: 'Contoh: Halaman Depan Pos Ronda RT 02',
                isDark: isDark,
                icon: Icons.pin_drop_outlined,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Lokasi wajib diisi' : null,
            ),

            const SizedBox(height: 16),

            // 6. Keterangan / Catatan Tambahan (Opsional)
            Text(
              'Keterangan Tambahan (Opsional)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13.5),
              decoration: _inputDecoration(
                hintText: 'Tuliskan instruksi atau pesan tambahan untuk warga...',
                isDark: isDark,
                icon: Icons.notes_rounded,
              ),
            ),

            const SizedBox(height: 28),

            // Tombol Publikasi
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmitEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Publikasikan Pengumuman',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required bool isDark,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontSize: 12.5,
        color: isDark ? Colors.white38 : Colors.grey[400],
      ),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF2563EB),
          width: 1.5,
        ),
      ),
    );
  }
}
