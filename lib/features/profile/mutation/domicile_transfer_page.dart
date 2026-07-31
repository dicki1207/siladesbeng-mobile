import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';

class DomicileTransferPage extends StatefulWidget {
  const DomicileTransferPage({super.key});

  @override
  State<DomicileTransferPage> createState() => _DomicileTransferPageState();
}

class _DomicileTransferPageState extends State<DomicileTransferPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'Semua';
  bool _isLoading = false;

  // Form State
  final _formKey = GlobalKey<FormState>();
  String _tipePermohonan =
      'Pindah Keluar (Akun Saya)'; // or 'Tarik Warga / Lansia'
  final _nameController = TextEditingController(
    text: 'Bagus Prakoso (Akun Saya)',
  );
  final _nikController = TextEditingController(text: '1403010101900001');
  final _kkController = TextEditingController(text: '1403010101900055');
  final _reasonController = TextEditingController();
  final _addressController = TextEditingController(
    text: 'Lingkungan RT 02 / RW 01',
  );

  String _selectedDesaAsal = 'Desa Sila-DesBeng (Desa Kita)';
  String _selectedDesaTujuan = 'Desa Batin Solapan (Kec. Mandau)';
  String _selectedPemohonStatus = 'Mandiri (Diri Sendiri)';
  bool _hasAttachedDoc = false;

  final List<String> _desaList = [
    'Desa Sila-DesBeng (Desa Kita)',
    'Desa Batin Solapan (Kec. Mandau)',
    'Desa Makmur Jaya (Kec. Bantan)',
    'Desa Pinggir (Kec. Pinggir)',
    'Desa Senggoro (Kec. Bengkalis)',
    'Desa Kelapapati (Kec. Bengkalis)',
    'Desa Sukamaju (Kec. Rupat)',
    'Desa Sukaasih (Kec. Bukit Batu)',
  ];

  final List<String> _statusPemohonList = [
    'Mandiri (Diri Sendiri)',
    'Kepala Keluarga / Pasangan',
    'Tarik Data Orang Tua / Lansia',
    'Wali / Kerabat yang Dirawat',
    'Admin RT/RW (Mewakili Warga)',
  ];

  final List<String> _reasonSuggestions = [
    'Pindah Rumah / Kontrakan Baru',
    'Mengikuti Suami/Istri & Keluarga',
    'Perawatan Orang Tua / Lansia di Sini',
    'Penugasan Kerja / Dinas Luar Daerah',
    'Pendidikan / Sekolah / Usaha',
  ];

  // Dummy List matching Web Admin: Menunggu Pelepasan (Keluar), Menunggu Persetujuan (Masuk), Riwayat
  final List<Map<String, dynamic>> _mutationList = [
    {
      'name': 'Bagus Prakoso',
      'nik': '1403010101900001',
      'tabType': 'Keluar', // Keluar, Masuk, Riwayat
      'statusTitle': 'Menunggu Pelepasan (Keluar)',
      'desaAsal': 'Desa Sila-DesBeng',
      'desaTujuan': 'Desa Batin Solapan',
      'pemohon': 'Mandiri (Bagus Prakoso)',
      'alasan':
          'Pindah domisili dikarenakan penugasan pekerjaan baru dan pindah ke kontrakan yang lebih dekat.',
      'lockStatus': 'Gembok NIK Terkunci di Desa Sila-DesBeng',
      'isLocked': true,
      'date': '26 Juli 2026',
      'color': Colors.amber[800]!,
      'bgColor': Colors.amber.withAlpha(25),
    },
    {
      'name': 'Hj. Siti Aminah (Lansia)',
      'nik': '1403040202550089',
      'tabType': 'Masuk',
      'statusTitle': 'Menunggu Persetujuan Desa Lama',
      'desaAsal': 'Desa Makmur Jaya',
      'desaTujuan': 'Desa Sila-DesBeng (Desa Kita)',
      'pemohon': 'Tarik Data Orang Tua / Lansia (Oleh: Budi Santoso)',
      'alasan':
          'Orang tua usia lanjut (Lansia) sekarang pindah menetap dan dirawat oleh anak di lingkungan RT 02 / RW 01 Sila-DesBeng.',
      'lockStatus': 'Menunggu Kepala Desa Makmur Jaya membuka Kunci Gembok NIK',
      'isLocked': true,
      'date': '24 Juli 2026',
      'color': Colors.blue[700]!,
      'bgColor': Colors.blue.withAlpha(25),
    },
    {
      'name': 'Rizky Pratama',
      'nik': '1403020303980055',
      'tabType': 'Riwayat',
      'statusTitle': 'Mutasi Selesai (Handshake Sukses!)',
      'desaAsal': 'Desa Pinggir',
      'desaTujuan': 'Desa Sila-DesBeng (Desa Kita)',
      'pemohon': 'Admin RT 02 / RW 01',
      'alasan':
          'Pindahan domisili resmi telah diverifikasi surat pindah antar kecamatan dan selesai cetak KK baru.',
      'lockStatus': 'Gembok Terbuka • NIK Resmi Aktif di Desa Sila-DesBeng',
      'isLocked': false,
      'date': '15 Juli 2026',
      'color': Colors.green[700]!,
      'bgColor': Colors.green.withAlpha(25),
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
    _nameController.dispose();
    _nikController.dispose();
    _kkController.dispose();
    _reasonController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onTipeChanged(String val) {
    setState(() {
      _tipePermohonan = val;
      if (_tipePermohonan == 'Pindah Keluar (Akun Saya)') {
        _nameController.text = 'Bagus Prakoso (Akun Saya)';
        _nikController.text = '1403010101900001';
        _kkController.text = '1403010101900055';
        _selectedDesaAsal = 'Desa Sila-DesBeng (Desa Kita)';
        _selectedDesaTujuan = 'Desa Batin Solapan (Kec. Mandau)';
        _selectedPemohonStatus = 'Mandiri (Diri Sendiri)';
      } else {
        _nameController.text = '';
        _nikController.text = '';
        _kkController.text = '';
        _selectedDesaAsal = 'Desa Makmur Jaya (Kec. Bantan)';
        _selectedDesaTujuan = 'Desa Sila-DesBeng (Desa Kita)';
        _selectedPemohonStatus = 'Tarik Data Orang Tua / Lansia';
      }
    });
  }

  Future<void> _handleSubmitMutation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Alasan pemindahan domisili wajib diisi!'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('transfer_status', 'pending');

    final bool isKeluar = _tipePermohonan.contains('Keluar');
    final String tabType = isKeluar ? 'Keluar' : 'Masuk';
    final String title = isKeluar
        ? 'Menunggu Pelepasan (Keluar)'
        : 'Menunggu Persetujuan Desa Lama';
    final String lockText = isKeluar
        ? 'Gembok NIK Terkunci • Menunggu persetujuan Admin Desa Sila-DesBeng'
        : 'Menunggu Admin $_selectedDesaAsal membuka Kunci Gembok NIK';
    final Color badgeCol = isKeluar ? Colors.amber[800]! : Colors.blue[700]!;
    final Color bgCol = isKeluar
        ? Colors.amber.withAlpha(25)
        : Colors.blue.withAlpha(25);

    final newMutation = {
      'name': _nameController.text.trim(),
      'nik': _nikController.text.trim(),
      'tabType': tabType,
      'statusTitle': title,
      'desaAsal': _selectedDesaAsal,
      'desaTujuan': _selectedDesaTujuan,
      'pemohon':
          '$_selectedPemohonStatus (${_nameController.text.split(' ')[0]})',
      'alasan': _reasonController.text.trim(),
      'lockStatus': lockText,
      'isLocked': true,
      'date': 'Hari Ini',
      'color': badgeCol,
      'bgColor': bgCol,
    };

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _mutationList.insert(0, newMutation);
      _reasonController.clear();
      _hasAttachedDoc = false;
      _tabController.index = 0;
      _selectedFilter = tabType; // Langsung sorot tab terkait
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnimatedSuccessDialog(
        message: isKeluar
            ? 'Pengajuan Pindah Keluar berhasil dikirim! NIK Anda kini dijadwalkan untuk pelepasan "Kunci Gembok" oleh Kepala Desa Sila-DesBeng menuju Desa Tujuan.'
            : 'Permohonan Tarik Warga (Handshake) berhasil diposting! Sistem sedang mengirim notifikasi ke Kepala Desa Asal agar membuka Kunci Gembok NIK warga tersebut.',
        isLogout: false,
      ),
    );

    await Future.delayed(const Duration(seconds: 4));
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context); // Tutup dialog sukses
    }
  }

  void _handleActionClick(int index) {
    final item = _mutationList[index];
    final type = item['tabType'];

    if (type == 'Keluar') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Batalkan Mutasi?'),
            ],
          ),
          content: Text(
            'Apakah Anda ingin membatalkan permohonan pindah domisili untuk NIK: ${item['nik']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _mutationList.removeAt(index));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Permohonan pindah berhasil dibatalkan.'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text('Ya, Batalkan'),
            ),
          ],
        ),
      );
    } else if (type == 'Masuk') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '🔔 Pengingat Handshake dikirim ke Admin ${item['desaAsal']} untuk memuat persetujuan!',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue[900],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '📄 Mengunduh Surat Bukti Mutasi Domisili & KK Sementara...',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Mutasi Penduduk (Handshake)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          indicatorWeight: 4,
          tabs: const [
            Tab(
              icon: Icon(Icons.swap_horizontal_circle),
              text: 'Status & Riwayat Mutasi',
            ),
            Tab(
              icon: Icon(Icons.person_add_alt_1),
              text: '+ Tarik / Ajukan Pindah',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.blue),
                  const SizedBox(height: 16),
                  Text(
                    'Menyiapkan koneksi Handshake antar Desa...',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[900],
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildStatusListTab(), _buildCreationFormTab()],
            ),
    );
  }

  Widget _buildStatusListTab() {
    List<Map<String, dynamic>> filteredList = _mutationList;
    if (_selectedFilter != 'Semua') {
      filteredList = _mutationList
          .where((item) => item['tabType'] == _selectedFilter)
          .toList();
    }

    final int cKeluar = _mutationList
        .where((e) => e['tabType'] == 'Keluar')
        .length;
    final int cMasuk = _mutationList
        .where((e) => e['tabType'] == 'Masuk')
        .length;
    final int cRiwayat = _mutationList
        .where((e) => e['tabType'] == 'Riwayat')
        .length;

    return Column(
      children: [
        // Blue Info Header & Filter Chips
        Container(
          color: Colors.blue[900],
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.amber,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ini adalah daftar pengajuan mutasi domisili Anda atau warga yang ditarik antar Desa. Kepala Desa asal memegang "Kunci Gembok" NIK.',
                        style: TextStyle(
                          color: Colors.white.withAlpha(240),
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      'Semua (${_mutationList.length})',
                      'Semua',
                    ),
                    _buildFilterChip('Menunggu Pelepasan ($cKeluar)', 'Keluar'),
                    _buildFilterChip('Menunggu Persetujuan ($cMasuk)', 'Masuk'),
                    _buildFilterChip('Riwayat Mutasi ($cRiwayat)', 'Riwayat'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List Content
        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_off_outlined,
                        size: 70,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada data pengajuan pada tab ini.',
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
                  itemCount: filteredList.length,
                  itemBuilder: (context, idx) {
                    final item = filteredList[idx];
                    final realIdx = _mutationList.indexOf(item);
                    final bool isLocked = item['isLocked'] as bool;
                    final Color badgeCol = item['color'] as Color;
                    final Color bgCol = item['bgColor'] as Color;

                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Card(
                      color: isDark ? Theme.of(context).cardColor : Colors.white,
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Header Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            color: bgCol,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      item['tabType'] == 'Keluar'
                                          ? Icons.outbox
                                          : item['tabType'] == 'Masuk'
                                          ? Icons.inbox
                                          : Icons.check_circle,
                                      size: 18,
                                      color: badgeCol,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      item['statusTitle'],
                                      style: TextStyle(
                                        color: badgeCol,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  item['date'],
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
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
                                // Nama & NIK
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['name'],
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'NIK: ${item['nik']}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontFamily: 'monospace',
                                                    fontWeight: FontWeight.w600,
                                                    color: isDark ? Colors.grey[200] : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isLocked
                                          ? Icons.lock
                                          : Icons.lock_open_rounded,
                                      color: isLocked
                                          ? Colors.red[700]
                                          : Colors.green[700],
                                      size: 28,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Route Desa
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.blueGrey[900] : Colors.blueGrey[50],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Desa Asal (Lama):',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              item['desaAsal'],
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.blue,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            const Text(
                                              'Desa Tujuan (Baru):',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            Text(
                                              item['desaTujuan'],
                                              textAlign: TextAlign.end,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Pemohon & Alasan
                                Text(
                                  'Pemohon: ${item['pemohon']}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Alasan: "${item['alasan']}"',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Kunci Gembok Status
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? (isLocked ? Colors.amber[900]!.withAlpha(40) : Colors.green[900]!.withAlpha(40))
                                        : (isLocked ? Colors.amber[50] : Colors.green[50]),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isLocked
                                          ? Colors.amber[300]!
                                          : Colors.green[300]!,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isLocked
                                            ? Icons.key
                                            : Icons.check_circle_outline,
                                        size: 18,
                                        color: isLocked
                                            ? Colors.amber[900]
                                            : Colors.green[800],
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item['lockStatus'],
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? (isLocked ? Colors.amber[200] : Colors.green[200])
                                                : (isLocked ? Colors.amber[950] : Colors.green[900]),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Action Button
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        _handleActionClick(realIdx),
                                    icon: Icon(
                                      item['tabType'] == 'Keluar'
                                          ? Icons.cancel_outlined
                                          : item['tabType'] == 'Masuk'
                                          ? Icons.add_alert_outlined
                                          : Icons.download_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      item['tabType'] == 'Keluar'
                                          ? 'Batalkan Pengajuan'
                                          : item['tabType'] == 'Masuk'
                                          ? 'Ingatkan Admin Desa Lama'
                                          : 'Unduh Bukti Mutasi',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          item['tabType'] == 'Keluar'
                                          ? Colors.red[700]
                                          : item['tabType'] == 'Masuk'
                                          ? Colors.blue[900]
                                          : Colors.green[800],
                                      backgroundColor:
                                          item['tabType'] == 'Keluar'
                                          ? Colors.red[50]
                                          : item['tabType'] == 'Masuk'
                                          ? Colors.blue[50]
                                          : Colors.green[50],
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
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
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String filterValue) {
    final bool active = _selectedFilter == filterValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: active ? Colors.blue[900] : Colors.white,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
        selected: active,
        selectedColor: Colors.amber,
        backgroundColor: Colors.blue[800],
        checkmarkColor: Colors.blue[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: active ? Colors.amber : Colors.blue[600]!),
        ),
        onSelected: (_) {
          setState(() => _selectedFilter = filterValue);
        },
      ),
    );
  }

  Widget _buildCreationFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Guide Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[800]!, Colors.indigo[900]!],
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.handshake_rounded,
                      color: Colors.black87,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Form Handshake & Tarik Warga',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ajukan kepindahan Anda atau Tarik Warga (Lansia/Keluarga/Pindahan) dari Desa lain secara online via Kunci Gembok NIK.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. Tipe Permohonan
            const Text(
              '1. Pilih Tipe Permohonan Mutasi:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildTipeRadioCard(
                    'Pindah Keluar (Akun Saya)',
                    Icons.directions_walk_rounded,
                    Colors.orange[800]!,
                    'Ajukan keluar ke Desa Baru',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTipeRadioCard(
                    'Tarik Warga / Lansia',
                    Icons.person_add_alt_1_rounded,
                    Colors.blue[800]!,
                    'Tarik NIK dari Desa Lama',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Identitas Warga
            const Text(
              '2. Identitas Warga yang Dimutasi:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nameController,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Nama Warga wajib diisi!'
                  : null,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap Warga',
                prefixIcon: const Icon(Icons.person),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nikController,
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                    validator: (v) => (v == null || v.length != 16)
                        ? 'NIK harus 16 digit!'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'NIK Warga (16 Digit)',
                      prefixIcon: const Icon(Icons.badge, color: Colors.blue),
                      suffixIcon: const Icon(
                        Icons.lock_outline,
                        color: Colors.amber,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _kkController,
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                    validator: (v) => (v == null || v.length != 16)
                        ? 'KK harus 16 digit!'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Nomor Kartu Keluarga (KK)',
                      prefixIcon: const Icon(Icons.credit_card),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      counterText: '',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            const Text(
              'Status / Hubungan Pemohon:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPemohonStatus,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.arrow_drop_down_circle,
                    color: Colors.blue,
                  ),
                  items: _statusPemohonList.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedPemohonStatus = val);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 22),

            // 3. Wilayah Domisili
            const Text(
              '3. Handshake Rute Wilayah Domisili:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.withAlpha(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dari Desa / Kelurahan Asal (Lama):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[350]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDesaAsal,
                        isExpanded: true,
                        items: _desaList
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text(
                                  d,
                                  style: const TextStyle(fontSize: 13.5),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedDesaAsal = val);
                          }
                        },
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Icon(
                        Icons.swap_vert_circle,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ),
                  ),

                  const Text(
                    'Menuju Desa / Kelurahan Tujuan (Baru):',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue, width: 1.5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDesaTujuan,
                        isExpanded: true,
                        items: _desaList
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text(
                                  d,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedDesaTujuan = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Lingkungan RT & RW / Dusun Tujuan',
                      hintText: 'Contoh: RT 02 / RW 01 Dusun Mawar',
                      prefixIcon: const Icon(Icons.domain_add),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // 4. Alasan Pindah
            const Text(
              '4. Alasan Pindah Domisili / Tarik Warga:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _reasonSuggestions.map((suggestion) {
                final bool selected = _reasonController.text == suggestion;
                return ActionChip(
                  label: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  backgroundColor: selected ? Colors.blue[800] : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: selected ? Colors.blue[900]! : Colors.grey[300]!,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _reasonController.text = suggestion;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Tuliskan alasan lengkap pemindahan domisili untuk verifikasi Kepala Desa...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // 5. Unggah Dokumen
            const Text(
              '5. Lampirkan Dokumen Pendukung (KTP/KK/Surat RT):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() => _hasAttachedDoc = !_hasAttachedDoc);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _hasAttachedDoc
                          ? '✅ Foto dokumen KTP/KK berhasil dilampirkan!'
                          : '🗑️ Lampiran dibatalkan.',
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 22,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: _hasAttachedDoc ? Colors.green[50] : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _hasAttachedDoc ? Colors.green : Colors.grey[400]!,
                    width: _hasAttachedDoc ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _hasAttachedDoc
                          ? Icons.task_alt
                          : Icons.upload_file_rounded,
                      size: 44,
                      color: _hasAttachedDoc
                          ? Colors.green[700]
                          : Colors.grey[600],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _hasAttachedDoc
                          ? 'Dokumen Terlampir: scan_ktp_kk_pindah.png (Ketuk ubah)'
                          : 'Ketuk untuk pilih foto Dokumen / KTP / Surat RT (Maks 2MB)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _hasAttachedDoc
                            ? Colors.green[900]
                            : Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _handleSubmitMutation,
                icon: const Icon(Icons.security, size: 22),
                label: const Text(
                  'Kirim Pengajuan Handshake Mutasi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTipeRadioCard(
    String title,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    final bool active = _tipePermohonan == title;
    return GestureDetector(
      onTap: () => _onTipeChanged(title),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? color.withAlpha(20) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? color : Colors.grey[300]!,
            width: active ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: active ? color : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: active ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: active ? color : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            Icon(
              active
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: active ? color : Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
