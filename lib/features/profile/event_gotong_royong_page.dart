import 'package:flutter/material.dart';

class EventGotongRoyongPage extends StatefulWidget {
  const EventGotongRoyongPage({super.key});

  @override
  State<EventGotongRoyongPage> createState() => _EventGotongRoyongPageState();
}

class _EventGotongRoyongPageState extends State<EventGotongRoyongPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'Semua Wilayah';

  // Form State
  final _formKey = GlobalKey<FormState>();
  String _formTipe = 'Gotong Royong';
  String _targetScope =
      'Tingkat RW / Dusun'; // 'Seluruh Desa', 'Tingkat RW / Dusun', 'Spesifik RT'
  String _selectedRw = 'RW 01 - Dusun Mawar';
  String _selectedRt = 'RT 01';
  bool _hasAttachedPoster = false;

  final _titleController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _locationController = TextEditingController();
  final _noteController = TextEditingController();
  final _coordinatorController = TextEditingController(
    text: 'Pak Pengurus RW / RT',
  );
  final List<String> _selectedEquipment = [];

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

  final List<Map<String, dynamic>> _tipeList = [
    {
      'label': 'Gotong Royong',
      'icon': Icons.group,
      'color': Colors.teal,
      'desc': 'Ajakan aksi kebersamaan & kerja bakti lingkungan',
    },
    {
      'label': 'Acara / Event',
      'icon': Icons.calendar_today,
      'color': Colors.orange,
      'desc': 'Kegiatan desa atau wilayah beserta tanggal & lokasi',
    },
    {
      'label': 'Pengumuman Biasa',
      'icon': Icons.campaign,
      'color': Colors.blue,
      'desc': 'Informasi umum atau imbauan resmi satu arah',
    },
  ];

  final List<String> _equipmentOptions = [
    'Cangkul / Sekop',
    'Sabit / Mesin Potong',
    'Karung Sampah',
    'Sarung Tangan Kerja',
    'Sapu & Lidi',
    'Senter Patroli',
  ];

  // Dummy Active Events & Gotong Royong
  final List<Map<String, dynamic>> _events = [
    {
      'title': 'Gotong Royong Bersihkan Irigasi & Selokan Musim Hujan',
      'wilayah': 'RW 02 - RT 01/03',
      'tipe': 'Gotong Royong',
      'koordinator': 'Pak Haris (Ketua RW 02)',
      'jadwal': 'Minggu, 30 Juli 2026 • 07:00 WIB - Selesai',
      'lokasi': 'Titik Kumpul: Balai Warga RW 02 & Sepanjang Aliran Irigasi',
      'note':
          'Mohon seluruh kepala keluarga dan pemuda meluangkan waktu demi mencegah banjir. Disediakan sarapan pagi, rebusan pisang, dan kopi hangat oleh Ibu-ibu PKK!',
      'equipment': ['Cangkul / Sekop', 'Karung Sampah', 'Sarung Tangan Kerja'],
      'participants': 24,
      'isJoined': false,
      'hasPoster': true,
      'posterUrl': 'https://picsum.photos/seed/irigasi/500/260',
      'color': Colors.teal,
    },
    {
      'title': 'Pengumuman Jadwal Posyandu Balita & Lansia RW 01',
      'wilayah': 'RW 01 (Seluruh RT)',
      'tipe': 'Pengumuman Biasa',
      'koordinator': 'Ibu Siti (Kader Posyandu RW 01)',
      'jadwal': 'Rabu, 2 Agustus 2026 • 08:30 WIB - Selesai',
      'lokasi': 'Posyandu Mawar Indah Raya RW 01',
      'note':
          'Diharapkan kehadiran para ibu yang memiliki balita dan lansia untuk pemeriksaan kesehatan gratis, pemberian vitamin A, dan penimbangan rutin bulan ini.',
      'equipment': [],
      'participants': 12,
      'isJoined': false,
      'hasPoster': false,
      'color': Colors.blue,
    },
    {
      'title': 'Kerja Bakti Pengecatan Gapura & Pembersihan Lingkungan',
      'wilayah': 'RW 01 - RT 02',
      'tipe': 'Gotong Royong',
      'koordinator': 'Pak Budi (Ketua RT 02)',
      'jadwal': 'Sabtu, 5 Agustus 2026 • 07:30 WIB - Selesai',
      'lokasi': 'Gapura Utama Masuk RT 02 / RW 01',
      'note':
          'Persiapan menyambut agenda tahunan desa. Cat dan kuas utama dipersiapkan dari kas RT/RW, warga cukup membantu tenaga dan merapikan taman sekitar.',
      'equipment': ['Sapu & Lidi', 'Sarung Tangan Kerja'],
      'participants': 18,
      'isJoined': true,
      'hasPoster': false,
      'color': Colors.teal,
    },
    {
      'title': 'Festival Budaya & Bazar UMKM Warga Desa Sila-DesBeng',
      'wilayah': 'Seluruh Desa (Umum)',
      'tipe': 'Acara / Event',
      'koordinator': 'Panitia Hari Besar Desa',
      'jadwal': 'Sabtu & Minggu, 12-13 Agustus 2026 • 09:00 WIB',
      'lokasi': 'Alun-Alun Balai Desa Sila-DesBeng',
      'note':
          'Ayo ramaikan pameran produk UMKM lokal dari 4 Dusun, pertunjukan seni anak desa, serta senam sehat bersama hadiah doorprize menarik!',
      'equipment': [],
      'participants': 45,
      'isJoined': false,
      'hasPoster': true,
      'posterUrl': 'https://picsum.photos/seed/bazar/500/260',
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _scheduleController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    _coordinatorController.dispose();
    super.dispose();
  }

  void _handleToggleJoin(int idx) {
    setState(() {
      final bool current = _events[idx]['isJoined'] as bool;
      _events[idx]['isJoined'] = !current;
      if (!current) {
        _events[idx]['participants'] =
            (_events[idx]['participants'] as int) + 1;
      } else {
        _events[idx]['participants'] =
            (_events[idx]['participants'] as int) - 1;
      }
    });

    final bool isJoined = _events[idx]['isJoined'] as bool;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isJoined ? Icons.check_circle : Icons.info_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isJoined
                    ? 'Terima kasih atas kepedulian Anda! Anda tercatat berpartisipasi/siap hadir.'
                    : 'Anda membatalkan partisipasi kehadiran untuk kegiatan ini.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isJoined ? Colors.teal[700] : Colors.blueGrey[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleSubmitEvent() {
    if (!_formKey.currentState!.validate()) return;

    // Determine target label
    String finalWilayah = 'Seluruh Desa (Umum)';
    if (_targetScope == 'Tingkat RW / Dusun') {
      finalWilayah = '${_selectedRw.split(' - ')[0]} (Seluruh RT)';
    } else if (_targetScope == 'Spesifik Lingkungan RT') {
      finalWilayah = '${_selectedRw.split(' - ')[0]} • $_selectedRt';
    }

    Color badgeColor = Colors.teal;
    if (_formTipe == 'Acara / Event') badgeColor = Colors.orange[800]!;
    if (_formTipe == 'Pengumuman Biasa') badgeColor = Colors.blue[700]!;

    final newEvent = {
      'title': _titleController.text.trim(),
      'wilayah': finalWilayah,
      'tipe': _formTipe,
      'koordinator': _coordinatorController.text.isEmpty
          ? 'Pak Pengurus RT/RW'
          : _coordinatorController.text.trim(),
      'jadwal': _scheduleController.text.isEmpty
          ? 'Segera / Sesuai Edaran'
          : _scheduleController.text.trim(),
      'lokasi': _locationController.text.isEmpty
          ? 'Lingkungan Wilayah $finalWilayah'
          : _locationController.text.trim(),
      'note': _noteController.text.trim(),
      'equipment': List<String>.from(_selectedEquipment),
      'participants': 1, // Koordinator terdaftar
      'isJoined': true,
      'hasPoster': _hasAttachedPoster,
      'posterUrl': _hasAttachedPoster
          ? 'https://picsum.photos/seed/baru/500/260'
          : null,
      'color': badgeColor,
    };

    setState(() {
      _events.insert(0, newEvent);
      _titleController.clear();
      _scheduleController.clear();
      _locationController.clear();
      _noteController.clear();
      _selectedEquipment.clear();
      _hasAttachedPoster = false;
      _tabController.index = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.rocket_launch, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '🚀 Broadcast Berhasil! Pengumuman dihantarkan ke seluruh warga di lingkup: $finalWilayah.',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal[800],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Pengumuman & Gotong Royong',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: isDark ? const Color(0xFF10192A) : Colors.teal[800],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          indicatorWeight: 4,
          tabs: const [
            Tab(
              icon: Icon(Icons.cleaning_services_rounded),
              text: 'Info & Aksi Warga',
            ),
            Tab(icon: Icon(Icons.campaign), text: 'Buat Baru (RT/RW)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildEventsTab(), _buildCreationFormTab()],
      ),
    );
  }

  Widget _buildEventsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredEvents = _selectedFilter == 'Semua Wilayah'
        ? _events
        : _events
              .where((e) => (e['wilayah'] as String).contains(_selectedFilter))
              .toList();

    return Column(
      children: [
        // Top Banner & Wilayah Filter
        Container(
          color: isDark ? const Color(0xFF1B2E3D) : Colors.teal[800],
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.broadcast_on_personal,
                    color: Colors.amber[300],
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pusat informasi gotong royong & pengumuman resmi lingkungan RT / RW Anda!',
                      style: TextStyle(
                        color: Colors.white.withAlpha(235),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['Semua Wilayah', 'RW 01', 'RW 02', 'RW 03', 'Desa']
                      .map((filter) {
                        final bool active = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              filter,
                              style: TextStyle(
                                color: active
                                    ? Colors.teal[900]
                                    : Colors.white.withAlpha(230),
                                fontWeight: active
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                            selected: active,
                            selectedColor: Colors.amber,
                            backgroundColor: isDark ? Colors.teal[900] : Colors.teal[700],
                            checkmarkColor: Colors.teal[900],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: active
                                    ? Colors.amber
                                    : Colors.teal[600]!,
                              ),
                            ),
                            onSelected: (_) {
                              setState(() => _selectedFilter = filter);
                            },
                          ),
                        );
                      })
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 70, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada pengumuman atau kegiatan\ndi lingkup "$_selectedFilter"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final item = filteredEvents[index];
                    final realIndex = _events.indexOf(item);
                    final bool isJoined = item['isJoined'] as bool;
                    final List<String> eq =
                        (item['equipment'] as List<dynamic>?)
                                ?.map((e) => e.toString())
                                .toList() ??
                            [];
                    final Color baseColor =
                        (item['color'] as Color?) ?? Colors.teal;
                    final bool hasPoster = item['hasPoster'] == true;

                    return Card(
                      color: isDark ? Theme.of(context).cardColor : Colors.white,
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 20),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Banner
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: baseColor.withAlpha(35),
                              border: Border(
                                bottom: BorderSide(
                                  color: baseColor.withAlpha(50),
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      item['tipe'] == 'Gotong Royong'
                                          ? Icons.group
                                          : item['tipe'] == 'Acara / Event'
                                          ? Icons.calendar_today
                                          : Icons.campaign,
                                      size: 18,
                                      color: isDark ? Colors.teal[300] : baseColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      item['tipe'],
                                      style: TextStyle(
                                        color: isDark ? Colors.teal[200] : baseColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: baseColor,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item['wilayah'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Optional Poster Image
                          if (hasPoster && item['posterUrl'] != null)
                            SizedBox(
                              height: 160,
                              width: double.infinity,
                              child: Image.network(
                                item['posterUrl'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),

                          // Body
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'],
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_pin,
                                      size: 18,
                                      color: isDark ? Colors.teal[300] : Colors.teal[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Koordinator: ${item['koordinator']}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time_filled,
                                      size: 17,
                                      color: isDark ? Colors.orange[300] : Colors.orange[800],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item['jadwal'],
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.orange[300] : Colors.orange[900],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 18,
                                      color: isDark ? Colors.red[400] : Colors.red[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item['lokasi'],
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  item['note'],
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                                    height: 1.45,
                                  ),
                                ),
                                if (eq.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.withAlpha(15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.teal.withAlpha(50),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Perlengkapan Disarankan Bawa:',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.teal[200] : Colors.teal[900],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: eq.map((alat) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isDark ? Colors.teal[700]! : Colors.teal[200]!,
                                                ),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: Colors.black12,
                                                    blurRadius: 2,
                                                    offset: Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                '☑️ $alat',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? Colors.teal[200] : Colors.teal[900],
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 16),
                                Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
                                const SizedBox(height: 6),

                                // Participants counter and Action button
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: baseColor.withAlpha(30),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.groups_rounded,
                                            color: isDark ? Colors.teal[300] : baseColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${item['participants']} Warga',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: isDark ? Colors.teal[200] : baseColor,
                                              ),
                                            ),
                                            const Text(
                                              'Merespons / Hadir',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _handleToggleJoin(realIndex),
                                      icon: Icon(
                                        isJoined
                                            ? Icons.check_circle_outline
                                            : Icons.front_hand,
                                        size: 18,
                                      ),
                                      label: Text(
                                        isJoined
                                            ? 'Terdaftar Hadir'
                                            : 'Saya Siap Hadir!',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isJoined
                                            ? Colors.green[700]
                                            : (isDark ? Colors.teal[600] : baseColor),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        elevation: isJoined ? 1 : 3,
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
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCreationFormTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Guide Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal[700]!, Colors.teal[900]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.tips_and_updates, color: Colors.amber[300], size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Panduan Publikasi Kegiatan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pastikan informasi lengkap dan jadwal valid agar warga dapat mengatur waktu untuk partisipasi aktif.',
                          style: TextStyle(
                            color: Colors.white.withAlpha(225),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 1: TIPE PENGUMUMAN
            const Text(
              '1. Tipe Informasi / Pengumuman:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Column(
              children: _tipeList.map((item) {
                final active = _formTipe == item['label'];
                final color = item['color'] as Color;
                return GestureDetector(
                  onTap: () => setState(() => _formTipe = item['label']),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? (active ? color.withAlpha(45) : Theme.of(context).cardColor)
                          : (active ? color.withAlpha(25) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? color : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        width: active ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: active ? color : (isDark ? Colors.grey[800] : Colors.grey[200]),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'],
                            color: active ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[700]),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['label'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: active ? color : (isDark ? Colors.white : Colors.black87),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['desc'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (active)
                          Icon(Icons.check_circle, color: color, size: 24),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // SECTION 2: TARGET WILAYAH CASCADING (RT / RW)
            const Text(
              '2. Cakupan & Target Wilayah Warga:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _scopeList.map((scope) {
                final active = _targetScope == scope;
                return ChoiceChip(
                  label: Text(scope),
                  selected: active,
                  selectedColor: isDark ? Colors.teal[900] : Colors.teal[100],
                  backgroundColor: isDark ? Theme.of(context).cardColor : Colors.white,
                  labelStyle: TextStyle(
                    color: active ? (isDark ? Colors.teal[200] : Colors.teal[900]) : (isDark ? Colors.white : Colors.black87),
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: active ? (isDark ? Colors.teal[400]! : Colors.teal[700]!) : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                    ),
                  ),
                  onSelected: (_) => setState(() => _targetScope = scope),
                );
              }).toList(),
            ),

            // Cascading RW / RT Dropdowns
            if (_targetScope != 'Seluruh Desa (Umum)') ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.teal.withAlpha(15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.teal.withAlpha(50)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pilih Wilayah RW / Dusun:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.teal[200] : Colors.teal[900],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Theme.of(context).cardColor : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? Colors.teal[700]! : Colors.teal[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedRw,
                          isExpanded: true,
                          dropdownColor: isDark ? Theme.of(context).cardColor : Colors.white,
                          icon: const Icon(Icons.domain, color: Colors.teal),
                          items: _rwList.map((rw) {
                            return DropdownMenuItem(
                              value: rw,
                              child: Text(
                                rw,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedRw = val;
                                _selectedRt = _rtOptions[val]!.first;
                              });
                            }
                          },
                        ),
                      ),
                    ),

                    if (_targetScope == 'Spesifik Lingkungan RT') ...[
                      const SizedBox(height: 14),
                      Text(
                        'Pilih Lingkungan RT:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? Colors.teal[200] : Colors.teal[900],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Theme.of(context).cardColor : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? Colors.teal[700]! : Colors.teal[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRt,
                            isExpanded: true,
                            dropdownColor: isDark ? Theme.of(context).cardColor : Colors.white,
                            icon: const Icon(
                              Icons.gps_fixed,
                              color: Colors.teal,
                            ),
                            items: (_rtOptions[_selectedRw] ?? ['RT 01']).map((
                              rt,
                            ) {
                              return DropdownMenuItem(
                                value: rt,
                                child: Text(
                                  'Lingkungan $rt ($_selectedRw)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedRt = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.blue.withAlpha(35) : Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? Colors.blue[700]! : Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: isDark ? Colors.blue[300] : Colors.blue[800]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Notifikasi ajakan ini akan dikirim secara eksklusif ke HP warga di lingkup wilayah target yang dipilih.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.blue[200] : Colors.blue[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // SECTION 3: JUDUL & KOORDINATOR
            const Text(
              '3. Judul Pengumuman / Event:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Judul pengumuman wajib diisi!'
                  : null,
              decoration: InputDecoration(
                hintText: _formTipe == 'Gotong Royong'
                    ? 'Contoh: Gotong Royong Pembersihan Saluran Air'
                    : 'Contoh: Rapat Evaluasi Keamanan RT / RW',
                filled: true,
                fillColor: isDark ? Theme.of(context).cardColor : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'Koordinator / Penanggung Jawab:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _coordinatorController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person_pin),
                filled: true,
                fillColor: isDark ? Theme.of(context).cardColor : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // SECTION 4: JADWAL & LOKASI
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '4. Tanggal & Jam:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _scheduleController,
                        decoration: InputDecoration(
                          hintText: 'Sabtu, 12 Agt • 07:30',
                          prefixIcon: const Icon(
                            Icons.calendar_today,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: isDark ? Theme.of(context).cardColor : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '5. Lokasi Kegiatan:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          hintText: 'Balai RW / Pos Ronda',
                          prefixIcon: const Icon(
                            Icons.location_on_outlined,
                            size: 19,
                          ),
                          filled: true,
                          fillColor: isDark ? Theme.of(context).cardColor : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // SECTION 5: PERLENGKAPAN (KHUSUS GOTONG ROYONG)
            if (_formTipe == 'Gotong Royong') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.amber.withAlpha(35) : Colors.amber.withAlpha(25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.amber.withAlpha(150) : Colors.amber.withAlpha(100)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.build_circle, color: isDark ? Colors.orange[300] : Colors.orange[800]),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '6. Perlengkapan yang Disarankan Dibawa Warga:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _equipmentOptions.map((eq) {
                        final isChecked = _selectedEquipment.contains(eq);
                        return FilterChip(
                          label: Text(eq),
                          selected: isChecked,
                          selectedColor: Colors.amber,
                          backgroundColor: isDark ? Theme.of(context).cardColor : Colors.white,
                          checkmarkColor: Colors.black87,
                          labelStyle: TextStyle(
                            color: isChecked ? Colors.black87 : (isDark ? Colors.white : Colors.black87),
                            fontWeight: isChecked
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isChecked
                                  ? (isDark ? Colors.orange[400]! : Colors.orange[800]!)
                                  : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedEquipment.add(eq);
                              } else {
                                _selectedEquipment.remove(eq);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // SECTION 6: DESKRIPSI LENGKAP
            Text(
              _formTipe == 'Gotong Royong'
                  ? '7. Catatan / Konsumsi / Pesan Motivasi Warga:'
                  : '6. Deskripsi Lengkap Pengumuman:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              maxLines: 4,
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Deskripsi lengkap wajib diisi!'
                  : null,
              decoration: InputDecoration(
                hintText: _formTipe == 'Gotong Royong'
                    ? 'Contoh: Disediakan sarapan pagi dan kopi oleh ibu-ibu PKK! Mari berpartisipasi demi kenyamanan dan kebersihan lingkungan kita.'
                    : 'Tuliskan detail rincian acara atau isi pengumuman untuk seluruh warga...',
                filled: true,
                fillColor: isDark ? Theme.of(context).cardColor : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 20),

            // SECTION 7: UPLOAD POSTER / GAMBAR (OPSIONAL)
            const Text(
              'Gambar / Poster Resmi (Opsional):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() => _hasAttachedPoster = !_hasAttachedPoster);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _hasAttachedPoster
                          ? '✅ Poster gambar berhasil dilampirkan!'
                          : '🗑️ Poster gambar dibatalkan.',
                    ),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: _hasAttachedPoster ? (isDark ? Colors.teal.withAlpha(35) : Colors.teal[50]) : (isDark ? Theme.of(context).cardColor : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _hasAttachedPoster ? Colors.teal : (isDark ? Colors.grey[700]! : Colors.grey[350]!),
                    width: _hasAttachedPoster ? 2 : 1,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _hasAttachedPoster
                          ? Icons.image
                          : Icons.cloud_upload_outlined,
                      size: 44,
                      color: _hasAttachedPoster
                          ? Colors.teal
                          : (isDark ? Colors.grey[400] : Colors.grey[500]),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _hasAttachedPoster
                          ? 'Poster Terlampir: poster_kegiatan_rw.png (Ketuk untuk ganti/hapus)'
                          : 'Klik untuk memilih gambar poster (JPG/PNG, Maks 2MB)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _hasAttachedPoster
                            ? (isDark ? Colors.teal[200] : Colors.teal[900])
                            : (isDark ? Colors.grey[300] : Colors.grey[700]),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _handleSubmitEvent,
                icon: const Icon(Icons.send_rounded, size: 24),
                label: const Text(
                  'Broadcast & Publikasikan ke Warga',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.teal[600] : Colors.teal[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  shadowColor: Colors.teal.withAlpha(100),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
