import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'rental_booking_page.dart';
import 'item_detail_page.dart';
import 'package:siladesbeng_mobile/services/rental_service.dart';

class FacilityRentalPage extends StatefulWidget {
  final int initialTabIndex;
  const FacilityRentalPage({super.key, this.initialTabIndex = 0});

  @override
  State<FacilityRentalPage> createState() => _FacilityRentalPageState();
}

class _FacilityRentalPageState extends State<FacilityRentalPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _vehicles = [];
  List<dynamic> _buildings = [];
  bool _isLoading = true;
  final RentalService _rentalService = RentalService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _fetchFacilities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFacilities() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await _rentalService.getFasilitasItems();
      if (!mounted) return;

      if (data.isNotEmpty) {
        // Safe access in case API doesn't return map or misses fields
        final vehicles = data.where((i) => (i is Map && i['is_vehicle'] == true)).toList();
        final buildings = data.where((i) => (i is Map && i['is_vehicle'] != true)).toList();

        setState(() {
          _vehicles = vehicles;
          _buildings = buildings;
          _isLoading = false;
        });
      } else {
        setState(() {
          _vehicles = [];
          _buildings = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _vehicles = [];
        _buildings = [];
        _isLoading = false;
      });
    }
  }

  void _showAmbulanceEmergencyModal(Map<String, dynamic> item) {
    String selectedPurpose = 'darurat_medis'; // or 'siaga_event'
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final phoneController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Modal
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medical_services_outlined,
                            color: Colors.red,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pengajuan Ambulans Desa',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Layanan Cepat Siaga 24 Jam & Pengamankan Event',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[800],
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ambulans disediakan gratis oleh desa untuk keadaan darurat ke Rumah Sakit atau disiagakan di event/kegiatan desa agar kejadian tidak diinginkan dapat segera ditangani.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.blue[950],
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Pilihan Tujuan Penggunaan
                    const Text(
                      'Pilih Jenis Keperluan Ambulans:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(
                              () => selectedPurpose = 'darurat_medis',
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selectedPurpose == 'darurat_medis'
                                    ? Colors.red[50]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedPurpose == 'darurat_medis'
                                      ? Colors.red
                                      : Colors.grey[300]!,
                                  width: selectedPurpose == 'darurat_medis'
                                      ? 2
                                      : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.local_hospital_rounded,
                                    color: selectedPurpose == 'darurat_medis'
                                        ? Colors.red
                                        : Colors.grey[600],
                                    size: 26,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Darurat Medis / RS',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                      color: selectedPurpose == 'darurat_medis'
                                          ? Colors.red[900]
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(
                              () => selectedPurpose = 'siaga_event',
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selectedPurpose == 'siaga_event'
                                    ? Colors.blue[50]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedPurpose == 'siaga_event'
                                      ? Colors.blue
                                      : Colors.grey[300]!,
                                  width: selectedPurpose == 'siaga_event'
                                      ? 2
                                      : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.health_and_safety_rounded,
                                    color: selectedPurpose == 'siaga_event'
                                        ? Colors.blue[800]
                                        : Colors.grey[600],
                                    size: 26,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Siaga Event Desa',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                      color: selectedPurpose == 'siaga_event'
                                          ? Colors.blue[900]
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Inputs
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Pemohon / Warga',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Nomor Telepon Darurat / WhatsApp',
                        prefixIcon: const Icon(Icons.phone_in_talk_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(
                        labelText: selectedPurpose == 'darurat_medis'
                            ? 'Lokasi Jemput & Tujuan Rujukan RS'
                            : 'Lokasi & Jadwal Pelaksanaan Event',
                        prefixIcon: const Icon(Icons.add_location_alt_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: selectedPurpose == 'darurat_medis'
                            ? 'Keterangan Kondisi Pasien (Opsional)'
                            : 'Jenis Kegiatan & Jumlah Perkiraan Massa',
                        prefixIcon: const Icon(Icons.notes_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (nameController.text.isEmpty ||
                              phoneController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  '⚠️ Nama dan Nomor Telepon wajib diisi!',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                    selectedPurpose == 'darurat_medis'
                                        ? Icons.add_alert_rounded
                                        : Icons.check_circle,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      selectedPurpose == 'darurat_medis'
                                          ? '🚨 Permintaan Ambulans Darurat disiarkan ke Supir & Desa! Mohon tunggu telepon balasan.'
                                          : '📅 Pengajuan Ambulans untuk Siaga Event Desa berhasil diajukan dan dijadwalkan!',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor:
                                  selectedPurpose == 'darurat_medis'
                                  ? Colors.red[800]
                                  : Colors.blue[800],
                              duration: const Duration(seconds: 4),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          selectedPurpose == 'darurat_medis'
                              ? Icons.campaign
                              : Icons.send_rounded,
                          color: Colors.white,
                        ),
                        label: Text(
                          selectedPurpose == 'darurat_medis'
                              ? 'PANGGIL AMBULANS DARURAT (GRATIS)'
                              : 'KIRIM PENGAJUAN SIAGA EVENT',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedPurpose == 'darurat_medis'
                              ? Colors.red[700]
                              : Colors.blue[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showStandardBookingModal(Map<String, dynamic> item) {
    // Navigasi ke halaman detail atau buka modal booking cepat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailPage(
          item: item,
          category: 'Fasilitas Umum',
          bookingPage: RentalBookingPage(
            item: item,
            category: 'Fasilitas Umum',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text(
          'Layanan Fasilitas Umum Desa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1E3A8A) : const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3.5,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.emergency_share_outlined),
              text: 'Kendaraan (Ambulans & Bus)',
            ),
            Tab(icon: Icon(Icons.domain), text: 'Bangunan & Lapangan'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF2563EB)),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat daftar fasilitas umum desa...',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFacilityList(_vehicles, isVehicleTab: true),
                _buildFacilityList(_buildings, isVehicleTab: false),
              ],
            ),
    );
  }

  Widget _buildFacilityList(List<dynamic> items, {required bool isVehicleTab}) {
    return RefreshIndicator(
      onRefresh: _fetchFacilities,
      color: const Color(0xFF2563EB),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Banner Penjelasan Khas Desa (Sesuai Konsep User POV)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isVehicleTab
                      ? [const Color(0xFF1E88E5), const Color(0xFF1565C0)]
                      : [const Color(0xFF0284C7), const Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isVehicleTab
                          ? Icons.airport_shuttle_rounded
                          : Icons.account_balance_rounded,
                      color: isVehicleTab
                          ? Colors.blue[900]
                          : Colors.blue[900],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isVehicleTab
                              ? 'Armada & Kendaraan Operasional'
                              : 'Gedung, Aula & Ruang Publik',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isVehicleTab
                              ? 'Fasilitas ambulans untuk medis darurat & siaga event, serta bus/kendaraan operasional desa untuk warga.'
                              : 'Peminjaman gedung pertemuan balai desa, aula kecamatan, dan lapangan olahraga untuk kegiatan masyarakat.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Daftar Item
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildFacilityCard(items[index], index),
                childCount: items.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _renderImage(String? path, {required bool isAmbulance}) {
    String clean = path ?? '';
    if (clean.contains('mobil.png')) {
      clean = 'assets/images/mobil.png';
    } else if (clean.contains('F1.png') || clean.contains('alat.png')) {
      clean = 'assets/images/F1.png';
    } else if (clean.contains('fasilitas.png')) {
      clean = 'assets/images/fasilitas.png';
    } else if (clean.contains('F2.png')) {
      clean = 'assets/images/F2.png';
    }
    if (clean.startsWith('assets/')) {
      return Image.asset(
        clean,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(
          isAmbulance ? Icons.local_hospital : Icons.domain,
          size: 65,
          color: isAmbulance ? Colors.red[300] : Colors.blue[300],
        ),
      );
    }
    return Image.network(
      clean,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(
        isAmbulance ? Icons.local_hospital : Icons.domain,
        size: 65,
        color: isAmbulance ? Colors.red[300] : Colors.blue[300],
      ),
    );
  }

  Widget _buildFacilityCard(dynamic item, int index) {
    final bool isAmbulance =
        item['is_ambulance'] == true ||
        (item['name'] ?? '').toString().toLowerCase().contains('ambulan');
    final String priceDisplay = item['price_display'] != null
        ? item['price_display'].toString()
        : item['price'] != null && item['price'] == 0
        ? 'Gratis (Fasilitas Desa)'
        : 'Rp ${NumberFormat('#,###', 'id_ID').format(item['price'] ?? 0)}';

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index * 100)),
      curve: Curves.easeOutQuart,
      builder: (context, double value, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: isAmbulance
                    ? Border.all(color: Colors.red[300]!, width: 1.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isAmbulance
                        ? Colors.red.withAlpha(20)
                        : Colors.black.withAlpha(12),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    if (isAmbulance) {
                      _showAmbulanceEmergencyModal(
                        item as Map<String, dynamic>,
                      );
                    } else {
                      _showStandardBookingModal(item as Map<String, dynamic>);
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Header & Gambar
                      Stack(
                        children: [
                          Container(
                            height: 150,
                            width: double.infinity,
                            color: isDark ? Colors.grey[850] : Colors.grey[100],
                            padding: const EdgeInsets.all(12),
                            child: _renderImage(
                              item['image']?.toString() ?? '',
                              isAmbulance: isAmbulance,
                            ),
                          ),
                          if (item['type_badge'] != null)
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (item['badge_color'] as Color?) ??
                                      Colors.blue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item['type_badge'].toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          if (isAmbulance)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.red[700],
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withAlpha(80),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Deskripsi & Tombol Aksi
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? 'Fasilitas Desa',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  isAmbulance
                                      ? Icons.verified_user
                                      : Icons.price_check_rounded,
                                  size: 18,
                                  color: isAmbulance
                                      ? Colors.red[700]
                                      : Colors.blue[700],
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    priceDisplay,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isAmbulance
                                          ? (isDark ? Colors.red[300] : Colors.red[800])
                                          : (isDark ? Colors.blue[300] : Colors.blue[800]),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item['description'] ?? '',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.grey[400] : Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Divider(color: isDark ? Colors.grey[800] : Colors.grey[200], height: 1),
                            const SizedBox(height: 14),

                            // Tombol Interaktif Khusus
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (isAmbulance) {
                                    _showAmbulanceEmergencyModal(
                                      item as Map<String, dynamic>,
                                    );
                                  } else {
                                    _showStandardBookingModal(
                                      item as Map<String, dynamic>,
                                    );
                                  }
                                },
                                icon: Icon(
                                  isAmbulance
                                      ? Icons.touch_app_rounded
                                      : Icons.calendar_month_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  isAmbulance
                                      ? 'PANGGIL AMBULANS / SIAGA EVENT'
                                      : 'AJUKAN JADWAL PEMAKAIAN',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isAmbulance
                                      ? Colors.red[700]
                                      : const Color(0xFF1D4ED8),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
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
              ),
            ),
          ),
        );
      },
    );
  }
}
