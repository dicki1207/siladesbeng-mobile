import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
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
  late final ShowcaseView _showcaseView;
  final GlobalKey _keyFacilityTabs = GlobalKey();
  final GlobalKey _keyFacilityItem = GlobalKey();

  late TabController _tabController;
  List<dynamic> _vehicles = [];
  List<dynamic> _buildings = [];
  bool _isLoading = true;
  final RentalService _rentalService = RentalService();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _showcaseView = ShowcaseView.register();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _fetchFacilities();
  }

  @override
  void dispose() {
    _showcaseView.unregister();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkAndStartShowcase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenTour = prefs.getBool('has_seen_facility_tour') ?? false;
      if (!hasSeenTour && mounted) {
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          _showcaseView.startShowCase([_keyFacilityTabs, _keyFacilityItem]);
          await prefs.setBool('has_seen_facility_tour', true);
        }
      }
    } catch (e) {
      debugPrint('Facility showcase error: $e');
    }
  }

  void _replayFacilityTour() {
    _showcaseView.startShowCase([_keyFacilityTabs, _keyFacilityItem]);
  }

  Future<void> _fetchFacilities() async {
    setState(() => _isLoading = true);

    try {
      final fasilitasData = await _rentalService.getFasilitasItems();
      final mobilData = await _rentalService.getMobilItems();

      if (!mounted) return;

      // Extract public facility vehicles from Mobil data
      final publicVehiclesFromMobil = mobilData.where((item) {
        if (item is! Map) return false;
        final name = (item['name'] ?? '').toString().toLowerCase();
        final category = (item['category'] ?? '').toString().toLowerCase();
        
        return name.contains('ambulan') || 
               name.contains('bus') ||
               name.contains('jenazah') ||
               category.contains('ambulan') || 
               category.contains('fasilitas');
      }).toList();

      final List<dynamic> combinedData = [...fasilitasData, ...publicVehiclesFromMobil];

      if (combinedData.isNotEmpty) {
        final vehicles = combinedData
            .where(
              (i) =>
                  (i is Map &&
                  (i['is_vehicle'] == true ||
                      i['type'] == 'mobil' ||
                      (i['name'] ?? '').toString().toLowerCase().contains(
                        'ambulan',
                      ) ||
                      (i['name'] ?? '').toString().toLowerCase().contains(
                        'mobil',
                      ) ||
                      (i['name'] ?? '').toString().toLowerCase().contains(
                        'bus',
                      ))),
            )
            .toList();

        final buildings = combinedData
            .where(
              (i) =>
                  !vehicles.contains(i) &&
                  (i['type'] == 'fasilitas' || i['type'] == null),
            )
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
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndStartShowcase();
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
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
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
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            color: Colors.red,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pengajuan Ambulans Desa',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Layanan Siaga 24 Jam & Pendampingan Kegiatan',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Theme.of(context).primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Ambulans disediakan gratis oleh desa untuk keadaan darurat medis menuju Rumah Sakit atau disiagakan dalam kegiatan resmi desa.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pilihan Tujuan Penggunaan
                    Text(
                      'Pilih Jenis Keperluan Ambulans',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF1E293B),
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selectedPurpose == 'darurat_medis'
                                    ? Colors.red.withValues(alpha: 0.08)
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedPurpose == 'darurat_medis'
                                      ? Colors.red
                                      : (isDark
                                            ? Colors.white12
                                            : Colors.grey.shade300),
                                  width: selectedPurpose == 'darurat_medis'
                                      ? 1.5
                                      : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.local_hospital_rounded,
                                    color: selectedPurpose == 'darurat_medis'
                                        ? Colors.red
                                        : Colors.grey[500],
                                    size: 24,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Darurat Medis / RS',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: selectedPurpose == 'darurat_medis'
                                          ? Colors.red
                                          : (isDark
                                                ? Colors.white70
                                                : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setModalState(
                              () => selectedPurpose = 'siaga_event',
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: selectedPurpose == 'siaga_event'
                                    ? Theme.of(
                                        context,
                                      ).primaryColor.withValues(alpha: 0.08)
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedPurpose == 'siaga_event'
                                      ? Theme.of(context).primaryColor
                                      : (isDark
                                            ? Colors.white12
                                            : Colors.grey.shade300),
                                  width: selectedPurpose == 'siaga_event'
                                      ? 1.5
                                      : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.health_and_safety_rounded,
                                    color: selectedPurpose == 'siaga_event'
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[500],
                                    size: 24,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Siaga Event Desa',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: selectedPurpose == 'siaga_event'
                                          ? Theme.of(context).primaryColor
                                          : (isDark
                                                ? Colors.white70
                                                : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Inputs
                    _buildModalTextField(
                      controller: nameController,
                      label: 'Nama Pemohon / Warga',
                      prefixIcon: Icons.person_outline_rounded,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildModalTextField(
                      controller: phoneController,
                      label: 'Nomor Telepon Darurat / WhatsApp',
                      prefixIcon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildModalTextField(
                      controller: locationController,
                      label: selectedPurpose == 'darurat_medis'
                          ? 'Lokasi Penjemputan & Tujuan Rujukan RS'
                          : 'Lokasi & Jadwal Acara Desa',
                      prefixIcon: Icons.location_on_outlined,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildModalTextField(
                      controller: noteController,
                      label: selectedPurpose == 'darurat_medis'
                          ? 'Keterangan Kondisi Pasien (Opsional)'
                          : 'Keterangan Acara & Estimasi Peserta',
                      prefixIcon: Icons.edit_note_rounded,
                      maxLines: 2,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (nameController.text.isEmpty ||
                              phoneController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Nama dan Nomor Telepon wajib diisi!',
                                ),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
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
                                        ? Icons.emergency_rounded
                                        : Icons.check_circle_rounded,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      selectedPurpose == 'darurat_medis'
                                          ? 'Permintaan Ambulans Darurat telah diteruskan ke petugas desa. Mohon tunggu panggilan balasan.'
                                          : 'Pengajuan Ambulans Siaga Event berhasil dikirimkan.',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor:
                                  selectedPurpose == 'darurat_medis'
                                  ? Colors.red[800]
                                  : Theme.of(context).primaryColor,
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
                              ? Icons.emergency_share_rounded
                              : Icons.send_rounded,
                          size: 18,
                        ),
                        label: Text(
                          selectedPurpose == 'darurat_medis'
                              ? 'Panggil Ambulans Darurat (Bebas Biaya)'
                              : 'Kirim Pengajuan Siaga Event',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedPurpose == 'darurat_medis'
                              ? Colors.red[700]
                              : Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
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

  Widget _buildModalTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white38 : Colors.grey[600],
          ),
          prefixIcon: Icon(
            prefixIcon,
            size: 18,
            color: Theme.of(context).primaryColor,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  void _showStandardBookingModal(Map<String, dynamic> item) {
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
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Fasilitas Umum Desa',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFF2FA2F1), const Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipRRect(
            child: Stack(
              children: [
                Positioned(
                  top: -30,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(22),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -15,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withAlpha(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'Panduan Fasilitas',
            onPressed: _replayFacilityTour,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Showcase(
            key: _keyFacilityTabs,
            title: 'Kategori Fasilitas Desa',
            description: 'Pilih tab "Kendaraan & Ambulans" untuk transportasi warga atau siaga medis darurat, atau "Gedung & Lapangan" untuk tempat acara warga.',
            targetBorderRadius: BorderRadius.circular(25),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                indicator: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: isDark ? Colors.white : primaryColor,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.85),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
                tabs: const [
                  Tab(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.airport_shuttle_rounded, size: 15),
                          SizedBox(width: 5),
                          Text('Kendaraan & Ambulans'),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.domain_rounded, size: 15),
                          SizedBox(width: 5),
                          Text('Gedung & Lapangan'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildFacilityList(_vehicles, isVehicleTab: true),
                _buildFacilityList(_buildings, isVehicleTab: false),
              ],
            ),
    );
  }

  Widget _buildFacilityList(List<dynamic> items, {required bool isVehicleTab}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchFacilities,
        color: primaryColor,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                children: [
                  Icon(
                    isVehicleTab
                        ? Icons.airport_shuttle_outlined
                        : Icons.domain_disabled_rounded,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isVehicleTab
                        ? 'Belum ada kendaraan operasional terdaftar.'
                        : 'Belum ada fasilitas gedung atau lapangan terdaftar.',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFacilities,
      color: primaryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // 1. Info Banner
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isVehicleTab
                          ? Icons.health_and_safety_rounded
                          : Icons.info_outline_rounded,
                      color: primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isVehicleTab
                            ? 'Layanan ambulans darurat medis 24 jam dan kendaraan operasional desa.'
                            : 'Peminjaman balai pertemuan warga, aula serbaguna, dan sarana olahraga desa.',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF334155),
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Daftar Grid Item
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 0.65,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final String itemName = item['name']?.toString() ?? 'Fasilitas Desa';
    final bool isAmbulance =
        item['is_ambulance'] == true ||
        itemName.toLowerCase().contains('ambulan');

    double priceVal = 0;
    if (item['price'] != null) {
      if (item['price'] is String) {
        priceVal = double.tryParse(item['price'].toString()) ?? 0;
      } else if (item['price'] is num) {
        priceVal = (item['price'] as num).toDouble();
      }
    }

    final String rawImageUrl = item['image']?.toString() ?? '';
    final bool hasValidNetworkImage =
        rawImageUrl.isNotEmpty &&
        rawImageUrl.startsWith('http') &&
        !rawImageUrl.contains('placeholder') &&
        !rawImageUrl.contains('fasilitas.png');

    final String status = isAmbulance ? 'Siaga 24 Jam' : 'Tersedia';
    final Color statusColor = isAmbulance
        ? Colors.red
        : const Color(0xFF10B981);

    final cardWidget = GestureDetector(
      onTap: () {
        if (isAmbulance) {
          _showAmbulanceEmergencyModal(item as Map<String, dynamic>);
        } else {
          _showStandardBookingModal(item as Map<String, dynamic>);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.grey.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Thumbnail Box
            Expanded(
              flex: 50,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : (isAmbulance
                                ? Colors.red.withValues(alpha: 0.05)
                                : const Color(0xFFF1F5F9)),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                      child: hasValidNetworkImage
                          ? Image.network(
                              rawImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  _buildFallbackIcon(isAmbulance, primaryColor),
                            )
                          : _buildFallbackIcon(isAmbulance, primaryColor),
                    ),
                  ),
                  // Status Badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAmbulance
                                ? Icons.emergency_rounded
                                : Icons.check_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            status.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Content Box
            Expanded(
              flex: 50,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (isAmbulance ? Colors.red : primaryColor)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isAmbulance
                                ? 'Kesehatan'
                                : (item['type_badge']?.toString() ??
                                      'Fasilitas'),
                            style: TextStyle(
                              color: isAmbulance ? Colors.red : primaryColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          itemName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          priceVal == 0
                              ? 'Gratis (Layanan Warga)'
                              : '${_currencyFormat.format(priceVal.toInt())} / Hari',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: priceVal == 0
                                ? const Color(0xFF10B981)
                                : primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // Action Pill Button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: (isAmbulance ? Colors.red : primaryColor)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isAmbulance ? 'Panggil Ambulans' : 'Ajukan Pinjam',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAmbulance ? Colors.red : primaryColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isAmbulance
                                ? Icons.phone_in_talk_rounded
                                : Icons.arrow_forward_rounded,
                            size: 13,
                            color: isAmbulance ? Colors.red : primaryColor,
                          ),
                        ],
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

    if (index == 0) {
      return Showcase(
        key: _keyFacilityItem,
        title: 'Pilih Fasilitas / Ambulans',
        description: 'Ketuk untuk melihat informasi fasilitas desa atau langsung ajukan pinjam / panggil Ambulans Siaga 24 Jam.',
        targetBorderRadius: BorderRadius.circular(16),
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  Widget _buildFallbackIcon(bool isAmbulance, Color primaryColor) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isAmbulance ? Colors.red : primaryColor).withValues(
            alpha: 0.1,
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isAmbulance ? Icons.airport_shuttle_rounded : Icons.domain_rounded,
          size: 32,
          color: isAmbulance ? Colors.red : primaryColor,
        ),
      ),
    );
  }
}
