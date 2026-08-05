import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/features/rental/rental_ticket_page.dart';
import 'package:siladesbeng_mobile/services/rental_service.dart';

class RentalBookingPage extends StatefulWidget {
  final dynamic item;
  final String? category;
  final int? initialDuration;
  const RentalBookingPage({super.key, required this.item, this.category, this.initialDuration});

  @override
  State<RentalBookingPage> createState() => _RentalBookingPageState();
}

class _RentalBookingPageState extends State<RentalBookingPage> {
  int _durationDays = 1;
  String _paymentCategory = 'tunai';
  String? _selectedBank;
  String? _selectedEWallet;
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _waController = TextEditingController();
  final _notesController = TextEditingController();
  String _driverOption = 'sendiri';
  String _eventCategory = 'sosial';
  bool _needsAdditionalFacilities = false;
  bool _isSubmitting = false;
  final RentalService _rentalService = RentalService();

  @override
  void initState() {
    super.initState();
    _durationDays = widget.initialDuration ?? 1;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _nameController.text = prefs.getString('profile_name') ?? '';
      });
    }
  }

  final List<String> _bankOptions = [
    'bank_transfer_bca',
    'bank_transfer_bri',
    'bank_transfer_bni',
    'bank_transfer_mandiri',
  ];

  final List<String> _eWalletOptions = ['qris', 'gopay'];

  String _formatBankName(String val) {
    switch (val) {
      case 'bank_transfer_bca':
        return 'BCA Virtual Account';
      case 'bank_transfer_bri':
        return 'BRI Virtual Account';
      case 'bank_transfer_bni':
        return 'BNI Virtual Account';
      case 'bank_transfer_mandiri':
        return 'Mandiri Virtual Account';
      default:
        return val;
    }
  }

  String _formatEWalletName(String val) {
    switch (val) {
      case 'qris':
        return 'QRIS (All E-Wallet)';
      case 'gopay':
        return 'GoPay';
      default:
        return val;
    }
  }

  Widget _getLogo(String val) {
    String url = '';

    if (val.contains('bca')) {
      url = 'http://10.250.3.148:8000/assets/img/payment_logos/bca.jpg';
    } else if (val.contains('bri')) {
      url = 'http://10.250.3.148:8000/assets/img/payment_logos/bri.png';
    } else if (val.contains('bni')) {
      url = 'http://10.250.3.148:8000/assets/img/payment_logos/bni.png';
    } else if (val.contains('mandiri')) {
      url = 'http://10.250.3.148:8000/assets/img/payment_logos/mandiri.png';
    } else if (val.contains('qris')) {
      url = 'https://qris.id/homepage/images/logo.png';
    } else if (val.contains('gopay')) {
      url = 'http://10.250.3.148:8000/assets/img/payment_logos/gopay.png';
    }

    if (url.isEmpty) return const SizedBox(width: 50);

    return Container(
      width: 50,
      height: 30,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.account_balance, size: 20, color: Colors.grey),
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    String subtitle,
    IconData icon, {
    Widget? child,
  }) {
    bool isSelected = _paymentCategory == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => setState(() => _paymentCategory = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withAlpha(20)
              : (isDark ? Theme.of(context).cardColor : Colors.white),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.withAlpha(50),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isSelected ? Colors.blue : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Colors.blue),
              ],
            ),
            if (isSelected && child != null)
              Padding(padding: const EdgeInsets.only(top: 16), child: child),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBooking() async {
    if (_nameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _waController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi Data Penyewa (Nama, WA, dan Alamat)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_paymentCategory == 'bank' && _selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih Bank'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_paymentCategory == 'ewallet' && _selectedEWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih E-Wallet'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final int pricePerDay =
        int.tryParse(widget.item['price']?.toString() ?? '0') ?? 0;
    final String itemType =
        widget.item['type']?.toString().toLowerCase() ?? 'alat';
    final String cat = widget.category?.toLowerCase() ?? '';
    final int itemId = widget.item['id'] ?? 1;

    int total = pricePerDay * _durationDays;
    if ((itemType == 'fasilitas' || cat.contains('fasilitas')) &&
        _eventCategory == 'sosial') {
      total = 0;
    }

    String paymentMethod = 'tunai';
    if (_paymentCategory == 'bank') paymentMethod = _selectedBank ?? 'bank_transfer_bca';
    if (_paymentCategory == 'ewallet') paymentMethod = _selectedEWallet ?? 'qris';

    final now = DateTime.now();
    final startDateStr = now.toIso8601String().substring(0, 10);
    final endDateStr = now.add(Duration(days: _durationDays)).toIso8601String().substring(0, 10);

    Map<String, dynamic> result;

    if (itemType == 'mobil' || cat.contains('mobil')) {
      result = await _rentalService.bookMobil(
        mobilId: itemId,
        startDate: startDateStr,
        endDate: endDateStr,
        recipientName: _nameController.text,
        deliveryAddress: _addressController.text,
        paymentMethod: paymentMethod,
        denganSupir: _driverOption == 'supir',
        rentalPurpose: _notesController.text,
      );
    } else if (itemType == 'fasilitas' || cat.contains('fasilitas')) {
      result = await _rentalService.bookFasilitas(
        fasilitasId: itemId,
        startDate: startDateStr,
        endDate: endDateStr,
        jenisAcara: _eventCategory,
        butuhGudang: _needsAdditionalFacilities,
        rentalPurpose: _notesController.text,
      );
    } else if (itemType == 'paket' || cat.contains('paket')) {
      result = await _rentalService.bookPackage(
        packageName: widget.item['name'] ?? 'Paket',
        itemsDescription: widget.item['description'] ?? 'Penyewaan Paket Alat',
        totalAmount: total.toDouble(),
        durationDays: _durationDays,
        startDate: startDateStr,
        endDate: endDateStr,
        recipientName: _nameController.text,
        paymentMethod: paymentMethod,
      );
    } else {
      result = await _rentalService.bookRentalItem(
        barangId: itemId,
        quantity: 1, // Default 1 for now
        startDate: startDateStr,
        endDate: endDateStr,
        recipientName: _nameController.text,
        deliveryAddress: _addressController.text,
        paymentMethod: paymentMethod,
        rentalPurpose: _notesController.text,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['status'] == 'success') {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) => RentalTicketPage(
            itemName: widget.item['name'] ?? 'Penyewaan',
            renterName: _nameController.text,
            eventType: _eventCategory == 'sosial'
                ? 'Sosial (Gratis)'
                : 'Pribadi (Berbayar)',
            needsLogistics: _needsAdditionalFacilities,
            totalPrice: total,
            durationDays: _durationDays,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutQuart);
            return FadeTransition(
              opacity: curve,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.05),
                  end: Offset.zero,
                ).animate(curve),
                child: child,
              ),
            );
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal membuat pesanan'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int pricePerDay =
        int.tryParse(widget.item['price']?.toString() ?? '0') ?? 0;
    final String itemType =
        widget.item['type']?.toString().toLowerCase() ?? 'alat';
    final String cat = widget.category?.toLowerCase() ?? '';

    int total = pricePerDay * _durationDays;
    if ((itemType == 'fasilitas' || cat.contains('fasilitas')) &&
        _eventCategory == 'sosial') {
      total = 0;
    }

    String pageTitle = 'Pemesanan Alat';
    String tunaiSubtitle = 'Bayar saat ambil alat';

    if (itemType == 'mobil' || cat.contains('mobil')) {
      pageTitle = 'Penyewaan Kendaraan';
      tunaiSubtitle = 'Bayar saat serah terima kendaraan';
    }
    if (itemType == 'fasilitas' || cat.contains('fasilitas')) {
      pageTitle = 'Penyewaan Fasilitas';
      tunaiSubtitle = 'Bayar di kantor pengelola desa';
    }

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFFF5F7FA), // Light greyish blue for premium feel
      appBar: AppBar(
        title: Text(
          pageTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Detail Produk
          const Text(
            'Detail Produk',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.item['image'] ?? 'https://via.placeholder.com/150',
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.inventory_2,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item['name'] ?? 'Item',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp $pricePerDay/hari',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lama Sewa',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.withAlpha(80),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () {
                                    if (_durationDays > 1) {
                                      setState(() => _durationDays--);
                                    }
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    child: Icon(Icons.remove, size: 16),
                                  ),
                                ),
                                Text(
                                  '$_durationDays',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    setState(() => _durationDays++);
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    child: Icon(Icons.add, size: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (pageTitle == 'Penyewaan Fasilitas') ...[
            const Text(
              'Kategori Acara',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _eventCategory = 'sosial'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _eventCategory == 'sosial'
                            ? Colors.blue.withAlpha(20)
                            : (isDark ? Theme.of(context).cardColor : Colors.white),
                        border: Border.all(
                          color: _eventCategory == 'sosial'
                              ? Colors.blue
                              : Colors.grey.withAlpha(50),
                          width: _eventCategory == 'sosial' ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.people,
                            color: _eventCategory == 'sosial'
                                ? Colors.blue
                                : Colors.grey,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Acara Sosial',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _eventCategory == 'sosial'
                                  ? Colors.blue
                                  : (isDark ? Colors.white : Colors.black87),
                              fontSize: 13,
                            ),
                          ),
                          const Text(
                            '(Gratis)',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _eventCategory = 'pribadi'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _eventCategory == 'pribadi'
                            ? Colors.blue.withAlpha(20)
                            : (isDark ? Theme.of(context).cardColor : Colors.white),
                        border: Border.all(
                          color: _eventCategory == 'pribadi'
                              ? Colors.blue
                              : Colors.grey.withAlpha(50),
                          width: _eventCategory == 'pribadi' ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person,
                            color: _eventCategory == 'pribadi'
                                ? Colors.blue
                                : Colors.grey,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Acara Pribadi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _eventCategory == 'pribadi'
                                  ? Colors.blue
                                  : (isDark ? Colors.white : Colors.black87),
                              fontSize: 13,
                            ),
                          ),
                          const Text(
                            '(Berbayar)',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.blue.withAlpha(40) : Colors.blue[50],
                border: Border.all(color: isDark ? Colors.blue[700]! : Colors.blue[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: isDark ? Colors.blue[400] : Colors.blue[800],
                title: Text(
                  'Ya, saya butuh fasilitas tambahan di dalam gudang aula (kursi/speaker)',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.blue[200] : Colors.blue[900]),
                ),
                value: _needsAdditionalFacilities,
                onChanged: (val) {
                  setState(() {
                    _needsAdditionalFacilities = val ?? false;
                  });
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (pageTitle == 'Penyewaan Kendaraan') ...[
            const Text(
              'Opsi Pengemudi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _driverOption = 'sendiri'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _driverOption == 'sendiri'
                            ? Colors.blue.withAlpha(20)
                            : (isDark ? Theme.of(context).cardColor : Colors.white),
                        border: Border.all(
                          color: _driverOption == 'sendiri'
                              ? Colors.blue
                              : Colors.grey.withAlpha(50),
                          width: _driverOption == 'sendiri' ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.person,
                            color: _driverOption == 'sendiri'
                                ? Colors.blue
                                : Colors.grey,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Supir Sendiri',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _driverOption == 'sendiri'
                                  ? Colors.blue
                                  : (isDark ? Colors.white : Colors.black87),
                              fontSize: 13,
                            ),
                          ),
                          const Text(
                            '(Lepas Kunci)',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _driverOption = 'disediakan'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _driverOption == 'disediakan'
                            ? Colors.blue.withAlpha(20)
                            : (isDark ? Theme.of(context).cardColor : Colors.white),
                        border: Border.all(
                          color: _driverOption == 'disediakan'
                              ? Colors.blue
                              : Colors.grey.withAlpha(50),
                          width: _driverOption == 'disediakan' ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.badge,
                            color: _driverOption == 'disediakan'
                                ? Colors.blue
                                : Colors.grey,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Disediakan Supir',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _driverOption == 'disediakan'
                                  ? Colors.blue
                                  : (isDark ? Colors.white : Colors.black87),
                              fontSize: 13,
                            ),
                          ),
                          const Text(
                            '(Dari Desa)',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Section: Data Penyewa
          const Text(
            'Data Penyewa',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap (Otomatis)',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.withAlpha(20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _waController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Nomor WhatsApp / HP',
                    prefixIcon: const Icon(Icons.phone_android),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.withAlpha(20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Alamat Pengiriman / Penggunaan',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.withAlpha(20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Catatan Tambahan (Opsional)',
                    prefixIcon: const Icon(Icons.notes),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.withAlpha(20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Metode Pembayaran
          const Text(
            'Metode Pembayaran',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          _buildPaymentOption(
            'tunai',
            'Bayar Tunai',
            tunaiSubtitle,
            Icons.money,
          ),
          _buildPaymentOption(
            'bank',
            'Bank Transfer',
            'Pembayaran via Virtual Account',
            Icons.account_balance,
              child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.withAlpha(100)),
                borderRadius: BorderRadius.circular(12),
                color: isDark ? Theme.of(context).cardColor : Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text(
                    'Pilih Bank',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: _selectedBank,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.blue,
                  ),
                  items: _bankOptions
                      .map(
                        (String val) => DropdownMenuItem(
                          value: val,
                          child: Row(
                            children: [
                              _getLogo(val),
                              const SizedBox(width: 12),
                              Text(
                                _formatBankName(val),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedBank = val),
                ),
              ),
            ),
          ),

          _buildPaymentOption(
            'ewallet',
            'E-Wallet / QRIS',
            'GoPay, OVO, Dana, LinkAja',
            Icons.qr_code_scanner,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.withAlpha(100)),
                borderRadius: BorderRadius.circular(12),
                color: isDark ? Theme.of(context).cardColor : Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text(
                    'Pilih E-Wallet',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: _selectedEWallet,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.blue,
                  ),
                  items: _eWalletOptions
                      .map(
                        (String val) => DropdownMenuItem(
                          value: val,
                          child: Row(
                            children: [
                              _getLogo(val),
                              const SizedBox(width: 12),
                              Text(
                                _formatEWalletName(val),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedEWallet = val),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),

      // STICKY BOTTOM BAR
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp $total',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSubmitting ? Colors.grey : const Color(0xFF1E88E5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: _isSubmitting ? 0 : 8,
                  shadowColor: const Color(0xFF1E88E5).withAlpha(100),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Pesan Sekarang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
