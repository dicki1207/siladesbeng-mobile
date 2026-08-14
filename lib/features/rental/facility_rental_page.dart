import 'package:flutter/material.dart';
import 'rental_booking_page.dart';
import 'item_detail_page.dart';
import '../../widgets/product_card_widget.dart';
import 'package:siladesbeng_mobile/services/rental_service.dart';

class FacilityRentalPage extends StatefulWidget {
  final int initialTabIndex;
  const FacilityRentalPage({super.key, this.initialTabIndex = 0});

  @override
  State<FacilityRentalPage> createState() => _FacilityRentalPageState();
}

class _FacilityRentalPageState extends State<FacilityRentalPage>
    with SingleTickerProviderStateMixin {
  static bool _hasShownSnackbar = false;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTabInfo(widget.initialTabIndex);
    });
  }

  void _showTabInfo(int index) {
    if (!mounted || _hasShownSnackbar) return;
    _hasShownSnackbar = true;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    String message = index == 0
        ? 'Fasilitas ambulans untuk medis darurat & siaga event, serta bus operasional desa.'
        : 'Peminjaman gedung pertemuan balai desa, aula kecamatan, dan lapangan olahraga.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              index == 0 ? Icons.airport_shuttle : Icons.account_balance,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        backgroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
        final vehicles = data
            .where((i) => (i is Map && i['is_vehicle'] == true))
            .toList();
        final buildings = data
            .where((i) => (i is Map && i['is_vehicle'] != true))
            .toList();

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
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Layanan Fasilitas Umum Desa',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
          dividerColor: Colors.transparent,
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
          // Daftar Item
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.7,
              ),
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


  Widget _buildFacilityCard(dynamic item, int index) {
    final bool isAmbulance =
        item['is_ambulance'] == true ||
        (item['name'] ?? '').toString().toLowerCase().contains('ambulan');
    
    double priceVal = 0;
    if (item['price'] != null) {
      if (item['price'] is String) {
        priceVal = double.tryParse(item['price'].toString()) ?? 0;
      } else if (item['price'] is num) {
        priceVal = (item['price'] as num).toDouble();
      }
    }

    String imageUrl = item['image']?.toString() ?? '';
    bool isAsset = false;
    if (imageUrl.isEmpty || imageUrl.contains('mobil.png') || imageUrl.contains('F1.png') || imageUrl.contains('fasilitas.png') || imageUrl.contains('F2.png') || imageUrl.startsWith('assets/')) {
        isAsset = true;
        if (isAmbulance || imageUrl.contains('mobil')) {
            imageUrl = 'assets/images/mobil.png';
        } else {
            imageUrl = 'assets/images/fasilitas.png';
        }
    }

    String status = isAmbulance ? 'Darurat / Siaga' : 'Tersedia';
    Color statusColor = isAmbulance ? Colors.red : const Color(0xFF10B981);

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index * 100)),
      curve: Curves.easeOutQuart,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: ProductCardWidget(
              title: item['name'] ?? 'Fasilitas Desa',
              category: item['type_badge']?.toString() ?? (isAmbulance ? 'Kendaraan' : 'Fasilitas'),
              imageUrl: imageUrl,
              isAssetImage: isAsset,
              price: priceVal,
              priceUnit: priceVal == 0 ? '' : '/Hari',
              stockLabel: '',
              stockValue: '',
              statusText: status,
              statusColor: statusColor,
              onTap: () {
                if (isAmbulance) {
                  _showAmbulanceEmergencyModal(item as Map<String, dynamic>);
                } else {
                  _showStandardBookingModal(item as Map<String, dynamic>);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
