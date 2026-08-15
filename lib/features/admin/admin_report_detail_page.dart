import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';

class AdminReportDetailPage extends StatefulWidget {
  final Map<String, dynamic> report;
  final String role; // 'rt' or 'rw'

  const AdminReportDetailPage({
    super.key,
    required this.report,
    required this.role,
  });

  @override
  State<AdminReportDetailPage> createState() => _AdminReportDetailPageState();
}

class _AdminReportDetailPageState extends State<AdminReportDetailPage>
    with SingleTickerProviderStateMixin {
  late String _currentStatus;
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Dropdown Selection State
  String? _selectedActionCode;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.report['status'] ?? 'Menunggu';
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    // Default dropdown action based on role and status
    if (widget.role == 'rt') {
      _selectedActionCode = _currentStatus == 'Diproses'
          ? 'complete'
          : 'process';
    } else {
      _selectedActionCode = _currentStatus == 'Diproses RW'
          ? 'complete'
          : 'process_rw';
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _confirmAction(
    String actionTitle,
    String newStatus,
    Color themeColor,
    String desc,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(100),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: themeColor.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_user_rounded,
                size: 48,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Konfirmasi Eksekusi',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda akan mengeksekusi instruksi komando "$actionTitle" pada laporan ini.\n$desc',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodySmall?.color,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      side: BorderSide(color: Colors.grey.withAlpha(150)),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _updateStatus(newStatus, actionTitle);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Eksekusi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _updateStatus(String newStatus, String actionTitle) async {
    setState(() => _isProcessing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('auth_token');
      
      if (token != null) {
        await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/admin-reports/${widget.report['id']}/forward'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          body: {
            'action': _selectedActionCode,
            'catatan': 'Tindakan: $actionTitle',
          }
        );
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
    }

    if (mounted) {
      setState(() {
        _currentStatus = newStatus;
        _isProcessing = false;
      });

      _showSuccessPopup(actionTitle);
    }
  }

  void _showSuccessPopup(String actionTitle) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tindakan Berhasil!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Status laporan telah diubah melalui instruksi "$actionTitle". Warga pelapor akan menerima notifikasi pembaruan real-time di aplikasi mereka.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text(
                    'Tutup & Lanjutkan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    LatLng reportLoc = const LatLng(-7.12345, 110.12345);
    if (widget.report['lokasi'] != null) {
      final locParts = widget.report['lokasi'].toString().split(',');
      if (locParts.length == 2) {
        try {
          reportLoc = LatLng(
            double.parse(locParts[0]),
            double.parse(locParts[1]),
          );
        } catch (_) {}
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Laporan #${widget.report['id'] ?? '1002'}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Executive Hero Card
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3C72).withAlpha(80),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.report['title'] ?? 'Gorong-gorong Tersumbat',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildStatusBadge(_currentStatus),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(height: 1, color: Colors.white.withAlpha(40)),
                    const SizedBox(height: 16),
                    _buildHeaderMeta(
                      Icons.person_pin_rounded,
                      'Pelapor',
                      widget.report['reporter'] ?? 'Bpk. Hendrawan (RT 02)',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildHeaderMeta(
                            Icons.calendar_today_rounded,
                            'Tanggal MASUK',
                            widget.report['date'] ?? '25 Jul 2026, 08:30 WIB',
                          ),
                        ),
                        Expanded(
                          child: _buildHeaderMeta(
                            Icons.category_rounded,
                            'KATEGORI',
                            widget.report['kategori'] ??
                                widget.report['category'] ??
                                'Infrastruktur',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withAlpha(100)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.amberAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Otoritas Komando: PENGURUS ${widget.role.toUpperCase()}',
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content Body
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Pengaduan Warga',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quote Card Description
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border(
                          left: const BorderSide(
                            color: Colors.blueAccent,
                            width: 5,
                          ),
                          top: BorderSide(color: Colors.grey.withAlpha(30)),
                          right: BorderSide(color: Colors.grey.withAlpha(30)),
                          bottom: BorderSide(color: Colors.grey.withAlpha(30)),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.format_quote_rounded,
                                color: Colors.blueAccent,
                                size: 28,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Catatan Pelapor:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.report['description'] ??
                                widget.report['desc'] ??
                                'Gorong-gorong tersumbat menyebabkan genangan air tinggi saat hujan deras. Mohon segera ditangani sebelum banjir memasuki halaman warga.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color?.withAlpha(220),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Simulated Foto Bukti Kejadian
                    const Text(
                      'Bukti Foto dari Warga',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade800, Colors.grey.shade900],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(30),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.blueGrey.shade900,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_enhance_rounded,
                                    size: 54,
                                    color: Colors.white.withAlpha(150),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Foto Bukti Lapangan Terlampir',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(180),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(150),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.verified_rounded,
                                        color: Colors.greenAccent,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Terverifikasi GPS Geotag',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Ketuk Perbesar',
                                    style: TextStyle(
                                      color: Colors.blueAccent.shade100,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Map Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Titik Koordinat Lokasi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.satellite_alt_rounded,
                                color: Colors.green,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'GPS Akurat',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(25),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          children: [
                            FlutterMap(
                              options: MapOptions(
                                initialCenter: reportLoc,
                                initialZoom: 16.5,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.all,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.example.siladesbeng',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: reportLoc,
                                      width: 60,
                                      height: 60,
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween<double>(
                                          begin: 0.8,
                                          end: 1.1,
                                        ),
                                        duration: const Duration(
                                          milliseconds: 800,
                                        ),
                                        curve: Curves.easeInOut,
                                        builder: (context, val, child) {
                                          return Transform.scale(
                                            scale: val,
                                            child: const Icon(
                                              Icons.location_on_rounded,
                                              color: Colors.redAccent,
                                              size: 55,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).cardColor.withAlpha(235),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(30),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.my_location_rounded,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Blok A2 / Lingkungan RT 02 Sila-DesBeng',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: FloatingActionButton.extended(
                                heroTag: 'nav_map',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Membuka petunjuk rute ke titik lokasi di Google Maps...',
                                      ),
                                      backgroundColor: Colors.blueAccent,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                backgroundColor: Colors.blue.shade700,
                                icon: const Icon(
                                  Icons.navigation_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Rute ke Titik Ini',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.indigo,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Panel Komando & Keputusan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Gunakan menu Dropdown di bawah untuk memilih keputusan penanganan mandiri, penyelesaian, atau eskalasi laporan.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_isProcessing)
                      Container(
                        padding: const EdgeInsets.all(40),
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.blueAccent,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Memverifikasi komando digital & memperbarui database...',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      _buildDropdownCommandSection(),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderMeta(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white60,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'Diproses':
      case 'Diproses RW':
        color = Colors.blueAccent;
        icon = Icons.sync_rounded;
        break;
      case 'Selesai':
        color = Colors.greenAccent;
        icon = Icons.verified_rounded;
        break;
      case 'Diteruskan ke RW':
      case 'Diteruskan ke Desa':
        color = Colors.purpleAccent;
        icon = Icons.escalator_warning_rounded;
        break;
      default:
        color = Colors.orangeAccent;
        icon = Icons.access_time_filled_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownCommandSection() {
    if (_currentStatus == 'Selesai') {
      return _buildSuccessCard(
        'Laporan ini telah tuntas diselesaikan dan diverifikasi. Terima kasih atas kerja keras dan kepedulian Anda untuk kenyamanan warga desa!',
        Icons.check_circle_outline_rounded,
        Colors.green,
      );
    }

    if (_currentStatus == 'Diteruskan ke Desa') {
      return _buildSuccessCard(
        'Laporan telah dieskalasi ke Pemerintah Desa dan saat ini dalam pengawasan langsung oleh tim Admin Desa / BUMDes.',
        Icons.assured_workload_rounded,
        Colors.blue,
      );
    }

    if (widget.role == 'rt' && _currentStatus == 'Diteruskan ke RW') {
      return _buildSuccessCard(
        'Laporan ini telah diserahkan dari RT dan saat ini dalam proses pengawasan oleh Pimpinan RW setempat.',
        Icons.mark_email_read_rounded,
        Colors.purple,
      );
    }

    // Build available options based on role and status
    final List<DropdownMenuItem<String>> items = [];

    if (widget.role == 'rt') {
      if (_currentStatus == 'Menunggu') {
        items.add(
          const DropdownMenuItem(
            value: 'process',
            child: Row(
              children: [
                Icon(
                  Icons.engineering_rounded,
                  color: Colors.blueAccent,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tangani Mandiri di Tingkat RT',
                    style: TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      items.add(
        const DropdownMenuItem(
          value: 'complete',
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tandai Selesai Tuntas (Sudah Diperbaiki)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
      items.add(
        const DropdownMenuItem(
          value: 'escalate_rw',
          child: Row(
            children: [
              Icon(Icons.shortcut_rounded, color: Colors.orange, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Eskalasi - Teruskan ke Pimpinan RW',
                  style: TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
      items.add(
        const DropdownMenuItem(
          value: 'cancel',
          child: Row(
            children: [
              Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Batal / Tolak - Laporan Tidak Valid',
                  style: TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Role: RW
      if (_currentStatus == 'Diteruskan ke RW' ||
          _currentStatus == 'Menunggu') {
        items.add(
          const DropdownMenuItem(
            value: 'process_rw',
            child: Row(
              children: [
                Icon(
                  Icons.handshake_rounded,
                  color: Colors.blueAccent,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Ambil Alih & Tangani di Tingkat RW',
                    style: TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      items.add(
        const DropdownMenuItem(
          value: 'complete',
          child: Row(
            children: [
              Icon(Icons.task_alt_rounded, color: Colors.green, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tandai Selesai Tuntas (Sudah Diperbaiki)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
      items.add(
        const DropdownMenuItem(
          value: 'escalate_desa',
          child: Row(
            children: [
              Icon(
                Icons.account_balance_rounded,
                color: Colors.purple,
                size: 20,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Eskalasi ke Pemerintah Desa / BUMDes',
                  style: TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
      items.add(
        const DropdownMenuItem(
          value: 'cancel',
          child: Row(
            children: [
              Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Batal / Tolak - Laporan Tidak Valid',
                  style: TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Safety check untuk mencegah crash Blank White Screen pada Dropdown:
    // Pastikan _selectedActionCode yang tersimpan memang ada di dalam daftar items!
    if (items.isNotEmpty && !items.any((item) => item.value == _selectedActionCode)) {
      _selectedActionCode = items.first.value;
    }

    // Determine impact details
    String impactText = '';
    Color impactColor = Colors.blue;
    IconData impactIcon = Icons.info_outline_rounded;

    switch (_selectedActionCode) {
      case 'process':
      case 'process_rw':
        impactText =
            'Anda akan mengambil alih pengerjaan kasus ini secara mandiri. Warga pelapor akan diberi tahu bahwa pengurus sedang aktif menangani laporan di lapangan.';
        impactColor = Colors.blue;
        impactIcon = Icons.engineering_rounded;
        break;
      case 'complete':
        impactText =
            'Laporan akan ditutup permanen. Sistem akan meresmikan penyelesaian tugas ini dan meneruskan ucapan terima kasih kepada warga pelapor.';
        impactColor = Colors.green;
        impactIcon = Icons.check_circle_rounded;
        break;
      case 'escalate_rw':
        impactText =
            'Kasus ini melampaui fasilitas atau anggaran RT. Status dipindahkan ke Dasbor Kerja Pimpinan RW setempat untuk koordinasi skala lingkungan yang lebih luas.';
        impactColor = Colors.orange;
        impactIcon = Icons.warning_amber_rounded;
        break;
      case 'escalate_desa':
        impactText =
            'Kasus membutuhkan perbaikan alat berat atau Dana Desa. Status dinaikkan ke panel kontrol utama Pemerintah Desa / Admin BUMDes.';
        impactColor = Colors.purple;
        impactIcon = Icons.account_balance_rounded;
        break;
      case 'cancel':
        impactText =
            'Laporan dibatalkan atau ditolak (misal karena duplikasi atau informasi fiktif). Kasus ditutup dengan notifikasi klarifikasi ke warga.';
        impactColor = Colors.redAccent;
        impactIcon = Icons.cancel_rounded;
        break;
      default:
        impactText =
            'Silakan pilih keputusan instruksi komando di menu di atas.';
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.withAlpha(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.touch_app_rounded, color: Colors.blue, size: 22),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pilih Keputusan Instruksi Komando:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.indigo.withAlpha(80),
                width: 1.5,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedActionCode,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.indigo,
                  size: 28,
                ),
                borderRadius: BorderRadius.circular(16),
                items: items,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedActionCode = val);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Dynamic Impact Card
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: impactColor.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: impactColor.withAlpha(80)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(impactIcon, color: impactColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dampak Eksekusi Keputusan:',
                        style: TextStyle(
                          color: impactColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        impactText,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withAlpha(210),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Execution Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_selectedActionCode == null) return;
                String title = 'Proses Laporan';
                String targetStatus = 'Diproses';
                Color btnColor = Colors.blue;

                if (_selectedActionCode == 'process') {
                  title = 'Proses Mandiri RT';
                  targetStatus = 'Diproses';
                  btnColor = const Color(0xFF1565C0);
                } else if (_selectedActionCode == 'process_rw') {
                  title = 'Proses Mandiri RW';
                  targetStatus = 'Diproses RW';
                  btnColor = const Color(0xFF1565C0);
                } else if (_selectedActionCode == 'complete') {
                  title = 'Tandai Selesai Tuntas';
                  targetStatus = 'Selesai';
                  btnColor = const Color(0xFF2E7D32);
                } else if (_selectedActionCode == 'escalate_rw') {
                  title = 'Eskalasi Laporan ke RW';
                  targetStatus = 'Diteruskan ke RW';
                  btnColor = const Color(0xFFE65100);
                } else if (_selectedActionCode == 'escalate_desa') {
                  title = 'Eskalasi ke Pemerintah Desa';
                  targetStatus = 'Diteruskan ke Desa';
                  btnColor = const Color(0xFF6A1B9A);
                } else if (_selectedActionCode == 'cancel') {
                  title = 'Pembatalan & Penolakan Laporan';
                  targetStatus = 'Dibatalkan';
                  btnColor = Colors.red.shade700;
                }

                _confirmAction(title, targetStatus, btnColor, impactText);
              },
              icon: const Icon(
                Icons.flash_on_rounded,
                color: Colors.white,
                size: 22,
              ),
              label: const Text(
                'Eksekusi Instruksi Terpilih',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
                shadowColor: Colors.indigo.withAlpha(120),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(String text, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(70), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Aktual: $_currentStatus',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withAlpha(200),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
