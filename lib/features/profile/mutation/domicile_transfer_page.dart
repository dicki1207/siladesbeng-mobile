import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';
import 'package:siladesbeng_mobile/services/mutasi_service.dart';

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
  final MutasiService _mutasiService = MutasiService();

  // Form State
  final _formKey = GlobalKey<FormState>();
  String _tipePermohonan = 'Pindah Keluar (Akun Saya)';
  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _kkController = TextEditingController();
  final _reasonController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedDesaAsal = 'Desa Sila-DesBeng (Desa Kita)';
  String _selectedDesaTujuan = 'Desa Batin Solapan (Kec. Mandau)';
  String _selectedPemohonStatus = 'Mandiri (Diri Sendiri)';

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

  String _selectedReasonCategory = 'Pindah Rumah / Tempat Tinggal';
  final List<String> _reasonSuggestions = [
    'Pindah Rumah / Tempat Tinggal',
    'Mengikuti Keluarga / Pasangan',
    'Pekerjaan / Dinas Luar Daerah',
    'Pendidikan / Sekolah',
    'Perawatan Keluarga / Lansia',
    'Lainnya (Tulis Manual)',
  ];

  List<Map<String, dynamic>> _mutationList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _loadMutations();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('profile_name') ?? 'Warga Sila-DesBeng';
    final nik = prefs.getString('profile_nik') ?? '1403010101900001';
    final address = prefs.getString('profile_address') ??
        'Lingkungan RT 01 / RW 02, Desa Bengkalis';

    if (mounted) {
      setState(() {
        if (_tipePermohonan == 'Pindah Keluar (Akun Saya)') {
          _nameController.text = name;
          _nikController.text = nik;
          _kkController.text = '1403010101900055';
          _addressController.text = address;
        }
      });
    }
  }

  Future<void> _loadMutations() async {
    final data = await _mutasiService.getMyMutations();
    if (!mounted) return;
    setState(() {
      _mutationList = data.map<Map<String, dynamic>>((item) {
        final String tipe = item['tipe'] ?? 'keluar';
        final String status = item['status'] ?? 'pending';
        String tabType;
        String statusTitle;
        Color badgeCol;
        Color bgCol;
        bool isLocked;
        String lockStatus;

        if (status == 'completed') {
          tabType = 'Riwayat';
          statusTitle = 'Mutasi Selesai (Handshake Sukses)';
          badgeCol = const Color(0xFF10B981);
          bgCol = const Color(0xFF10B981).withAlpha(25);
          isLocked = false;
          lockStatus = 'Gembok Terbuka • NIK Resmi Aktif di Desa Tujuan';
        } else if (tipe == 'keluar') {
          tabType = 'Keluar';
          statusTitle = 'Menunggu Pelepasan (Keluar)';
          badgeCol = const Color(0xFF2FA2F1);
          bgCol = const Color(0xFF2FA2F1).withAlpha(25);
          isLocked = true;
          lockStatus = 'Gembok NIK Terkunci • Menunggu persetujuan Admin Desa Asal';
        } else {
          tabType = 'Masuk';
          statusTitle = 'Menunggu Persetujuan Desa Lama';
          badgeCol = const Color(0xFF6366F1);
          bgCol = const Color(0xFF6366F1).withAlpha(25);
          isLocked = true;
          lockStatus = 'Menunggu Admin Desa Asal membuka kunci pelepasan NIK';
        }

        return {
          'id': item['id'],
          'name': item['nama'] ?? '',
          'nik': item['nik'] ?? '',
          'tabType': tabType,
          'statusTitle': statusTitle,
          'desaAsal': item['desa_asal'] ?? '',
          'desaTujuan': item['desa_tujuan'] ?? '',
          'pemohon': item['status_pemohon'] ?? '',
          'alasan': item['alasan'] ?? '',
          'lockStatus': lockStatus,
          'isLocked': isLocked,
          'date': item['created_at']?.toString().substring(0, 10) ?? '',
          'color': badgeCol,
          'bgColor': bgCol,
        };
      }).toList();
    });
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
        _loadUserData();
        _selectedDesaAsal = 'Desa Sila-DesBeng (Desa Kita)';
        _selectedDesaTujuan = 'Desa Batin Solapan (Kec. Mandau)';
        _selectedPemohonStatus = 'Mandiri (Diri Sendiri)';
      } else {
        _nameController.text = '';
        _nikController.text = '';
        _kkController.text = '';
        _addressController.text = '';
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
          content: Text('Alasan pemindahan domisili wajib diisi'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final bool isKeluar = _tipePermohonan.contains('Keluar');

    final response = await _mutasiService.store(
      nama: _nameController.text.trim(),
      nik: _nikController.text.trim(),
      noKk: _kkController.text.trim(),
      desaAsal: _selectedDesaAsal,
      desaTujuan: _selectedDesaTujuan,
      alamat: _addressController.text.trim(),
      statusPemohon: _selectedPemohonStatus,
      alasan: _reasonController.text.trim(),
      tipe: isKeluar ? 'keluar' : 'masuk',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      _reasonController.clear();
      _tabController.index = 1; // Pindah ke tab status
      await _loadMutations();

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AnimatedSuccessDialog(
          message: isKeluar
              ? 'Pengajuan Pindah Keluar berhasil dikirim'
              : 'Permohonan Tarik Warga (Handshake) berhasil dikirim',
          isLogout: false,
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'Gagal mengirim pengajuan'),
          backgroundColor: Colors.redAccent,
        ),
      );
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
          title: const Text('Batalkan Pengajuan?'),
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
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final itemId = item['id'];
                if (itemId != null) {
                  final res = await _mutasiService.cancel(itemId);
                  if (res['status'] == 'success') {
                    await _loadMutations();
                  }
                }
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Permohonan pindah berhasil dibatalkan'),
                    backgroundColor: Colors.redAccent,
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
          content: Text(
            'Pengingat Handshake telah dikirim ke Admin ${item['desaAsal']}',
          ),
          backgroundColor: Theme.of(context).primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mengunduh Surat Bukti Mutasi Domisili & Berkas...',
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Mutasi Domisili (Handshake)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: primaryColor,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.edit_note_rounded, size: 20),
                  text: 'Ajukan Mutasi',
                ),
                Tab(
                  icon: Icon(Icons.sync_alt_rounded, size: 20),
                  text: 'Status & Riwayat',
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Memproses data mutasi kependudukan...',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCreationFormTab(),
                _buildStatusListTab(),
              ],
            ),
    );
  }

  Widget _buildCreationFormTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final bool isAkunSaya = _tipePermohonan == 'Pindah Keluar (Akun Saya)';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Jenis Permohonan Selector
            _buildSectionTitle('1. Pilih Jenis Permohonan'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildSegmentedTypeCard(
                    title: 'Pindah Keluar',
                    subtitle: 'Akun Saya',
                    icon: Icons.logout_rounded,
                    isSelected: isAkunSaya,
                    onTap: () => _onTipeChanged('Pindah Keluar (Akun Saya)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSegmentedTypeCard(
                    title: 'Tarik Warga',
                    subtitle: 'Lansia / Keluarga',
                    icon: Icons.group_add_rounded,
                    isSelected: !isAkunSaya,
                    onTap: () => _onTipeChanged('Tarik Warga / Lansia'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 2. Data Pemohon Section
            _buildSectionTitle('2. Identitas Warga yang Dimutasi'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white12
                      : Colors.grey.withAlpha(35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 6),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAkunSaya) ...[
                    // Tampilan Data Terkunci Resmi untuk Akun Sendiri
                    Row(
                      children: [
                        Icon(Icons.verified_user_rounded,
                            color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Data Terverifikasi dari Akun Anda',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildReadOnlyField(
                      label: 'Nama Lengkap',
                      value: _nameController.text,
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildReadOnlyField(
                      label: 'Nomor Induk Kependudukan (NIK)',
                      value: _nikController.text,
                      icon: Icons.badge_outlined,
                      isMonospace: true,
                    ),
                    const SizedBox(height: 10),
                    _buildReadOnlyField(
                      label: 'Alamat Saat Ini',
                      value: _addressController.text,
                      icon: Icons.home_outlined,
                    ),
                  ] else ...[
                    // Form Isian untuk Tarik Warga / Lansia
                    _buildFormTextField(
                      controller: _nameController,
                      label: 'Nama Lengkap Warga yang Ditarik',
                      hint: 'Contoh: Ahmad Fadilah',
                      icon: Icons.person_outline_rounded,
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _buildFormTextField(
                      controller: _nikController,
                      label: 'NIK Warga (16 Digit)',
                      hint: '1403xxxxxxxxxxxx',
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      validator: (val) => (val == null || val.trim().length < 16)
                          ? 'NIK harus 16 digit angka'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _buildDropdownField(
                      label: 'Status / Hubungan dengan Pemohon',
                      value: _selectedPemohonStatus,
                      items: _statusPemohonList,
                      icon: Icons.family_restroom_rounded,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPemohonStatus = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildFormTextField(
                      controller: _addressController,
                      label: 'Alamat Domisili Asal',
                      hint: 'RT/RW, Dusun, atau Jalan',
                      icon: Icons.home_outlined,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Arah Perpindahan Section
            _buildSectionTitle('3. Arah Perpindahan Domisili'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white12
                      : Colors.grey.withAlpha(35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 6),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDropdownField(
                    label: 'Desa Asal (Lama)',
                    value: _selectedDesaAsal,
                    items: _desaList,
                    icon: Icons.outbox_rounded,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDesaAsal = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_downward_rounded,
                          color: primaryColor,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDropdownField(
                    label: 'Desa Tujuan (Baru)',
                    value: _selectedDesaTujuan,
                    items: _desaList,
                    icon: Icons.inbox_rounded,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDesaTujuan = val);
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. Alasan Mutasi Section
            _buildSectionTitle('4. Alasan Pemindahan Domisili'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white12
                      : Colors.grey.withAlpha(35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 6),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDropdownField(
                    label: 'Pilih Kategori Alasan',
                    value: _selectedReasonCategory,
                    items: _reasonSuggestions,
                    icon: Icons.category_outlined,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedReasonCategory = val;
                          if (val != 'Lainnya (Tulis Manual)') {
                            _reasonController.text = val;
                          } else {
                            _reasonController.clear();
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildFormTextField(
                    controller: _reasonController,
                    label: 'Keterangan Alasan Lengkap',
                    hint: 'Tuliskan rincian atau keterangan alasan pemindahan...',
                    icon: Icons.edit_note_rounded,
                    maxLines: 2,
                    validator: (val) => (val == null || val.trim().isEmpty)
                        ? 'Alasan mutasi wajib diisi'
                        : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _handleSubmitMutation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                icon: const Icon(Icons.send_rounded, size: 20),
                label: const Text(
                  'Kirim Pengajuan Mutasi',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.2,
          ),
    );
  }

  Widget _buildSegmentedTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withAlpha(isDark ? 40 : 20)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : (isDark ? Colors.white12 : Colors.grey.withAlpha(40)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: primaryColor.withAlpha(25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor
                      : (isDark ? Colors.white10 : Colors.grey[200]),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.grey[700]),
                  size: 24,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: isSelected
                      ? primaryColor
                      : (isDark ? Colors.white : Colors.black87),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    bool isMonospace = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(8) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isNotEmpty ? value : '-',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: isMonospace ? 'monospace' : null,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildFormTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor:
            isDark ? Colors.white.withAlpha(8) : const Color(0xFFF8FAFC),
        labelStyle: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white60 : Colors.grey[600],
        ),
        hintStyle: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white30 : Colors.grey[400],
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : items.first,
      items: items.map((e) {
        return DropdownMenuItem<String>(
          value: e,
          child: Text(
            e,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      isExpanded: true,
      icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.grey[600]),
      dropdownColor: Theme.of(context).cardColor,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor:
            isDark ? Colors.white.withAlpha(8) : const Color(0xFFF8FAFC),
        labelStyle: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white60 : Colors.grey[600],
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey[300]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusListTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    List<Map<String, dynamic>> filteredList = _mutationList;
    if (_selectedFilter != 'Semua') {
      filteredList = _mutationList
          .where((item) => item['tabType'] == _selectedFilter)
          .toList();
    }

    final int cKeluar =
        _mutationList.where((e) => e['tabType'] == 'Keluar').length;
    final int cMasuk =
        _mutationList.where((e) => e['tabType'] == 'Masuk').length;
    final int cRiwayat =
        _mutationList.where((e) => e['tabType'] == 'Riwayat').length;

    return Column(
      children: [
        // Filter Chips Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : Colors.grey.withAlpha(30),
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip('Semua (${_mutationList.length})', 'Semua'),
                _buildFilterChip('Pelepasan ($cKeluar)', 'Keluar'),
                _buildFilterChip('Persetujuan ($cMasuk)', 'Masuk'),
                _buildFilterChip('Selesai ($cRiwayat)', 'Riwayat'),
              ],
            ),
          ),
        ),

        // List Content
        Expanded(
          child: filteredList.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: primaryColor.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.history_toggle_off_rounded,
                            size: 48,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada Pengajuan Mutasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Riwayat pemindahan domisili dan tarik warga Anda akan tercatat secara resmi di sini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: () {
                            _tabController.animateTo(0);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryColor,
                            side: BorderSide(color: primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Buat Pengajuan Baru'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final item = filteredList[index];
                    final int realIdx = _mutationList.indexOf(item);
                    final Color badgeCol = item['color'];
                    final bool isLocked = item['isLocked'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : Colors.grey.withAlpha(35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 30 : 6),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Header Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: item['bgColor'],
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      item['tabType'] == 'Keluar'
                                          ? Icons.logout_rounded
                                          : item['tabType'] == 'Masuk'
                                              ? Icons.login_rounded
                                              : Icons.check_circle_rounded,
                                      size: 16,
                                      color: badgeCol,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      item['statusTitle'],
                                      style: TextStyle(
                                        color: badgeCol,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  item['date'],
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.grey[600],
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
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['name'],
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'NIK: ${item['nik']}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'monospace',
                                              color: isDark
                                                  ? Colors.white70
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      isLocked
                                          ? Icons.lock_outline_rounded
                                          : Icons.lock_open_rounded,
                                      color: isLocked
                                          ? primaryColor
                                          : const Color(0xFF10B981),
                                      size: 24,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // Route Info
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withAlpha(8)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Desa Asal',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item['desaAsal'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: primaryColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Desa Tujuan',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item['desaTujuan'],
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Status Gembok Banner
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isLocked
                                        ? primaryColor.withAlpha(15)
                                        : const Color(0xFF10B981).withAlpha(15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isLocked
                                            ? Icons.vpn_key_rounded
                                            : Icons.verified_rounded,
                                        size: 16,
                                        color: isLocked
                                            ? primaryColor
                                            : const Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item['lockStatus'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isLocked
                                                ? (isDark
                                                    ? primaryColor
                                                    : const Color(0xFF1E40AF))
                                                : const Color(0xFF10B981),
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
                                          ? Icons.close_rounded
                                          : item['tabType'] == 'Masuk'
                                              ? Icons.notifications_none_rounded
                                              : Icons.download_rounded,
                                      size: 16,
                                    ),
                                    label: Text(
                                      item['tabType'] == 'Keluar'
                                          ? 'Batalkan Pengajuan'
                                          : item['tabType'] == 'Masuk'
                                              ? 'Kirim Pengingat'
                                              : 'Unduh Bukti Mutasi',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          item['tabType'] == 'Keluar'
                                              ? Colors.redAccent
                                              : item['tabType'] == 'Masuk'
                                                  ? primaryColor
                                                  : const Color(0xFF10B981),
                                      backgroundColor:
                                          item['tabType'] == 'Keluar'
                                              ? Colors.redAccent.withAlpha(20)
                                              : item['tabType'] == 'Masuk'
                                                  ? primaryColor.withAlpha(20)
                                                  : const Color(0xFF10B981)
                                                      .withAlpha(20),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
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
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: active
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.grey[700]),
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
        selected: active,
        selectedColor: primaryColor,
        backgroundColor:
            isDark ? Colors.white.withAlpha(12) : const Color(0xFFF1F5F9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: active
                ? primaryColor
                : (isDark ? Colors.white10 : Colors.grey[300]!),
          ),
        ),
        onSelected: (_) {
          setState(() => _selectedFilter = filterValue);
        },
      ),
    );
  }
}
