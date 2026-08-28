import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/features/rental/rental_ticket_page.dart';
import 'package:siladesbeng_mobile/services/rental_service.dart';

class RentalBookingPage extends StatefulWidget {
  final dynamic item;
  final String? category;
  final int? initialDuration;
  const RentalBookingPage({
    super.key,
    required this.item,
    this.category,
    this.initialDuration,
  });

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
  final bool _needsAdditionalFacilities = false;
  bool _isSubmitting = false;
  final RentalService _rentalService = RentalService();

  final List<String> _bankOptions = [
    'bank_transfer_bca',
    'bank_transfer_bri',
    'bank_transfer_bni',
    'bank_transfer_mandiri',
  ];

  final List<String> _eWalletOptions = ['qris', 'gopay'];

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

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
        final phone = prefs.getString('profile_phone') ?? '';
        if (phone.isNotEmpty) {
          _waController.text = phone;
        }
      });
    }
  }

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

  Widget _buildPaymentLogo(
    String key, {
    double width = 46,
    double height = 26,
  }) {
    String? assetPath;
    switch (key.toLowerCase()) {
      case 'bank_transfer_bca':
      case 'bca':
        assetPath = 'assets/images/banks/bca.png';
        break;
      case 'bank_transfer_bri':
      case 'bri':
        assetPath = 'assets/images/banks/bri.png';
        break;
      case 'bank_transfer_bni':
      case 'bni':
        assetPath = 'assets/images/banks/bni.png';
        break;
      case 'bank_transfer_mandiri':
      case 'mandiri':
        assetPath = 'assets/images/banks/mandiri.png';
        break;
      case 'gopay':
        assetPath = 'assets/images/banks/gopay.png';
        break;
    }

    if (assetPath != null) {
      return Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 0.8),
        ),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) =>
              const Icon(Icons.account_balance, size: 16, color: Colors.blue),
        ),
      );
    }

    if (key.toLowerCase().contains('qris')) {
      return Container(
        width: width,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300, width: 0.8),
        ),
        child: SvgPicture.asset(
          'assets/images/banks/qris.svg',
          fit: BoxFit.contain,
        ),
      );
    }

    // Default icon badge for generic fallback
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300, width: 0.8),
      ),
      child: const Center(
        child: Icon(Icons.account_balance, size: 16, color: Colors.blue),
      ),
    );
  }

  void _showPaymentPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sheet Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pilih Metode Pembayaran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Option 1: Bayar Tunai (COD / Di Kantor)
                    _buildModalPaymentItem(
                      iconWidget: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.payments_outlined,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      title: 'Bayar Tunai',
                      subtitle:
                          'Bayar saat serah terima alat / di kantor BUMDes',
                      isSelected: _paymentCategory == 'tunai',
                      onTap: () {
                        setState(() {
                          _paymentCategory = 'tunai';
                          _selectedBank = null;
                          _selectedEWallet = null;
                        });
                        Navigator.pop(context);
                      },
                    ),

                    const SizedBox(height: 10),

                    // Option 2: Bank Transfer (Virtual Account)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _paymentCategory == 'bank'
                              ? primaryColor
                              : (isDark
                                    ? Colors.white10
                                    : Colors.grey.withValues(alpha: 0.15)),
                          width: _paymentCategory == 'bank' ? 1.5 : 1,
                        ),
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: _paymentCategory == 'bank',
                        leading:
                            _paymentCategory == 'bank' && _selectedBank != null
                            ? _buildPaymentLogo(_selectedBank!)
                            : Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.account_balance_outlined,
                                  color: primaryColor,
                                  size: 20,
                                ),
                              ),
                        title: Text(
                          _paymentCategory == 'bank' && _selectedBank != null
                              ? _formatBankName(_selectedBank!)
                              : 'Transfer Bank (Virtual Account)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _paymentCategory == 'bank'
                                ? primaryColor
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          'BCA, BRI, BNI, Mandiri',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white38 : Colors.grey[500],
                          ),
                        ),
                        children: _bankOptions.map((bank) {
                          final isBankActive =
                              _paymentCategory == 'bank' &&
                              _selectedBank == bank;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            leading: _buildPaymentLogo(bank),
                            title: Text(
                              _formatBankName(bank),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isBankActive
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isBankActive
                                    ? primaryColor
                                    : (isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B)),
                              ),
                            ),
                            trailing: isBankActive
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: primaryColor,
                                    size: 18,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _paymentCategory = 'bank';
                                _selectedBank = bank;
                                _selectedEWallet = null;
                              });
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Option 3: E-Wallet / QRIS
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _paymentCategory == 'ewallet'
                              ? primaryColor
                              : (isDark
                                    ? Colors.white10
                                    : Colors.grey.withValues(alpha: 0.15)),
                          width: _paymentCategory == 'ewallet' ? 1.5 : 1,
                        ),
                      ),
                      child: ExpansionTile(
                        initiallyExpanded: _paymentCategory == 'ewallet',
                        leading:
                            _paymentCategory == 'ewallet' &&
                                _selectedEWallet != null
                            ? _buildPaymentLogo(_selectedEWallet!)
                            : Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: primaryColor,
                                  size: 20,
                                ),
                              ),
                        title: Text(
                          _paymentCategory == 'ewallet' &&
                                  _selectedEWallet != null
                              ? _formatEWalletName(_selectedEWallet!)
                              : 'E-Wallet / QRIS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _paymentCategory == 'ewallet'
                                ? primaryColor
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          'QRIS Instant, GoPay',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white38 : Colors.grey[500],
                          ),
                        ),
                        children: _eWalletOptions.map((wallet) {
                          final isWalletActive =
                              _paymentCategory == 'ewallet' &&
                              _selectedEWallet == wallet;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            leading: _buildPaymentLogo(wallet),
                            title: Text(
                              _formatEWalletName(wallet),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isWalletActive
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isWalletActive
                                    ? primaryColor
                                    : (isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B)),
                              ),
                            ),
                            trailing: isWalletActive
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: primaryColor,
                                    size: 18,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                _paymentCategory = 'ewallet';
                                _selectedEWallet = wallet;
                                _selectedBank = null;
                              });
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalPaymentItem({
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? primaryColor
              : (isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.15)),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: iconWidget,
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? primaryColor : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? Colors.white38 : Colors.grey[500],
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle_rounded, color: primaryColor, size: 18)
            : null,
      ),
    );
  }

  String _getSelectedPaymentLabel() {
    if (_paymentCategory == 'tunai') {
      return 'Bayar Tunai';
    } else if (_paymentCategory == 'bank') {
      return _selectedBank != null
          ? _formatBankName(_selectedBank!)
          : 'Pilih Bank Virtual Account';
    } else if (_paymentCategory == 'ewallet') {
      return _selectedEWallet != null
          ? _formatEWalletName(_selectedEWallet!)
          : 'Pilih QRIS / E-Wallet';
    }
    return 'Pilih Metode Pembayaran';
  }

  Widget _getSelectedPaymentLeadingWidget() {
    final primaryColor = Theme.of(context).primaryColor;

    if (_paymentCategory == 'tunai') {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.payments_outlined, color: primaryColor, size: 20),
      );
    } else if (_paymentCategory == 'bank' && _selectedBank != null) {
      return _buildPaymentLogo(_selectedBank!, width: 44, height: 26);
    } else if (_paymentCategory == 'ewallet' && _selectedEWallet != null) {
      return _buildPaymentLogo(_selectedEWallet!, width: 44, height: 26);
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.payment_rounded, color: primaryColor, size: 20),
    );
  }

  Future<void> _submitBooking() async {
    final String itemType =
        widget.item['type']?.toString().toLowerCase() ?? 'alat';
    final String cat = widget.category?.toLowerCase() ?? '';
    final bool isFasilitas =
        itemType == 'fasilitas' || cat.contains('fasilitas');

    if (_nameController.text.trim().isEmpty ||
        _waController.text.trim().isEmpty ||
        (!isFasilitas && _addressController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFasilitas
                ? 'Mohon lengkapi Data Penyewa (Nama dan Nomor WhatsApp)'
                : 'Mohon lengkapi Data Penyewa (Nama, WA, dan Alamat)',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_paymentCategory == 'bank' && _selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih Bank tujuan transfer'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_paymentCategory == 'ewallet' && _selectedEWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih opsi E-Wallet / QRIS'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final int pricePerDay =
        int.tryParse(widget.item['price']?.toString() ?? '0') ?? 0;
    final int itemId = widget.item['id'] ?? 1;

    int total = pricePerDay * _durationDays;
    if ((itemType == 'fasilitas' || cat.contains('fasilitas')) &&
        _eventCategory == 'sosial') {
      total = 0;
    }

    String paymentMethod = 'tunai';
    if (_paymentCategory == 'bank') {
      paymentMethod = _selectedBank ?? 'bank_transfer_bca';
    }
    if (_paymentCategory == 'ewallet') {
      paymentMethod = _selectedEWallet ?? 'qris';
    }

    final String startDate = DateTime.now().toIso8601String().substring(0, 10);
    final String endDate = DateTime.now()
        .add(Duration(days: _durationDays))
        .toIso8601String()
        .substring(0, 10);

    Map<String, dynamic> result;

    if (itemType == 'paket' || cat.contains('paket')) {
      result = await _rentalService.bookPackage(
        packageName: widget.item['name'] ?? 'Paket Sewa',
        itemsDescription: widget.item['description'] ?? '',
        totalAmount: total.toDouble(),
        durationDays: _durationDays,
        startDate: startDate,
        endDate: endDate,
        recipientName: _nameController.text,
        paymentMethod: paymentMethod,
      );
    } else if (itemType == 'mobil' || cat.contains('mobil')) {
      result = await _rentalService.bookMobil(
        mobilId: itemId,
        startDate: startDate,
        endDate: endDate,
        recipientName: _nameController.text,
        deliveryAddress: _addressController.text,
        paymentMethod: paymentMethod,
        rentalPurpose: _notesController.text,
        denganSupir: _driverOption != 'sendiri',
      );
    } else if (itemType == 'fasilitas' || cat.contains('fasilitas')) {
      result = await _rentalService.bookFasilitas(
        fasilitasId: itemId,
        startDate: startDate,
        endDate: endDate,
        rentalPurpose: _notesController.text,
        jenisAcara: _eventCategory,
        butuhGudang: _needsAdditionalFacilities,
      );
    } else {
      result = await _rentalService.bookRentalItem(
        barangId: itemId,
        quantity: 1,
        startDate: startDate,
        endDate: endDate,
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
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) =>
              RentalTicketPage(
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
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
            );
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
    final primaryColor = Theme.of(context).primaryColor;

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

    String pageTitle = 'Penyewaan Alat';
    if (itemType == 'mobil' || cat.contains('mobil')) {
      pageTitle = 'Penyewaan Kendaraan';
    }
    if (itemType == 'fasilitas' || cat.contains('fasilitas')) {
      pageTitle = 'Penyewaan Fasilitas';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          pageTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 17,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF2563EB),
        iconTheme: const IconThemeData(color: Colors.white),
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
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          // 1. Detail Produk Card
          _buildSectionHeader('Detail Produk'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
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
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child:
                        (widget.item['image'] != null &&
                            widget.item['image'].toString().isNotEmpty)
                        ? Image.network(
                            widget.item['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey[400],
                            ),
                          )
                        : Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.grey[400],
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item['name'] ?? 'Item',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_currencyFormat.format(pricePerDay)} / Hari',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tarif Resmi BUMDes',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                // Duration Stepper
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(16),
                        ),
                        onTap: () {
                          if (_durationDays > 1) {
                            setState(() => _durationDays--);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Icon(
                            Icons.remove_rounded,
                            size: 18,
                            color: _durationDays > 1
                                ? primaryColor
                                : Colors.grey,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '$_durationDays Hari',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(16),
                        ),
                        onTap: () {
                          setState(() => _durationDays++);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. Data Penyewa Section
          _buildSectionHeader('Data Penyewa'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
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
                _buildCleanTextField(
                  controller: _nameController,
                  label: 'Nama Lengkap Penyewa',
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 12),
                _buildCleanTextField(
                  controller: _waController,
                  label: 'Nomor WhatsApp / HP',
                  hint: '08123456789',
                  prefixIcon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                if (itemType == 'fasilitas' || cat.contains('fasilitas')) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(
                        alpha: isDark ? 0.15 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_city_rounded,
                          color: primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lokasi Fasilitas',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.item['location'] ??
                                    'Gedung / Area Fasilitas Desa SiladesBeng',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  _buildCleanTextField(
                    controller: _addressController,
                    label: itemType == 'mobil' || cat.contains('mobil')
                        ? 'Alamat Penjemputan / Pengantaran Mobil'
                        : 'Alamat Pengantaran / Lokasi Pemasangan',
                    hint: 'Alamat lengkap RT/RW atau nama jalan',
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                ],
                if (itemType == 'mobil' || cat.contains('mobil')) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Pilihan Pengemudi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(
                            child: Text(
                              'Setir Sendiri',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          selected: _driverOption == 'sendiri',
                          onSelected: (val) =>
                              setState(() => _driverOption = 'sendiri'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(
                            child: Text(
                              'Dengan Supir',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          selected: _driverOption != 'sendiri',
                          onSelected: (val) =>
                              setState(() => _driverOption = 'supir'),
                        ),
                      ),
                    ],
                  ),
                ],
                if (itemType == 'fasilitas' || cat.contains('fasilitas')) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Kategori Acara',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(
                            child: Text(
                              'Sosial (Gratis)',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          selected: _eventCategory == 'sosial',
                          onSelected: (val) =>
                              setState(() => _eventCategory = 'sosial'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(
                            child: Text(
                              'Pribadi / Komersil',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          selected: _eventCategory != 'sosial',
                          onSelected: (val) =>
                              setState(() => _eventCategory = 'pribadi'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                _buildCleanTextField(
                  controller: _notesController,
                  label: (itemType == 'fasilitas' || cat.contains('fasilitas'))
                      ? 'Tujuan Penggunaan Acara (Opsional)'
                      : 'Catatan Tambahan (Opsional)',
                  hint: (itemType == 'fasilitas' || cat.contains('fasilitas'))
                      ? 'Contoh: Rapat warga, pernikahan, atau turnamen olahraga'
                      : 'Contoh: Pasang tenda H-1 sebelum acara',
                  prefixIcon: Icons.edit_note_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 3. Metode Pembayaran Card (Compact Tile)
          _buildSectionHeader('Metode Pembayaran'),
          const SizedBox(height: 8),
          Container(
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
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _showPaymentPicker,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      _getSelectedPaymentLeadingWidget(),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getSelectedPaymentLabel(),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ketuk untuk memilih metode pembayaran lain',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ubah',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: primaryColor,
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

          const SizedBox(height: 18),

          // 4. Rincian Pembayaran (Order Summary)
          _buildSectionHeader('Rincian Pembayaran'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
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
              children: [
                _buildSummaryRow(
                  label: 'Biaya Sewa ($_durationDays Hari)',
                  value: _currencyFormat.format(total),
                ),
                const SizedBox(height: 10),
                _buildSummaryRow(
                  label: 'Biaya Layanan & Pemeliharaan',
                  value: 'Gratis',
                  isFree: true,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Pembayaran',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      _currencyFormat.format(total),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Sticky Action Bar
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white10
                  : Colors.grey.withValues(alpha: 0.15),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 45,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Tagihan',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _currencyFormat.format(total),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Sewa Sekarang',
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
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white70 : const Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildCleanTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white60 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade300,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white24 : Colors.grey[400],
              ),
              prefixIcon: Icon(prefixIcon, size: 18, color: primaryColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    bool isFree = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? Colors.white54 : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isFree
                ? Colors.green
                : (isDark ? Colors.white : const Color(0xFF1E293B)),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _waController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
