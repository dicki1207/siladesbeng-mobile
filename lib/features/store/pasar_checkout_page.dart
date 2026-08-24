import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:siladesbeng_mobile/features/store/pasar_payment_page.dart';
import 'package:siladesbeng_mobile/services/pasar_checkout_service.dart';

class PasarCheckoutPage extends StatefulWidget {
  final double totalAmount;

  const PasarCheckoutPage({super.key, required this.totalAmount});

  @override
  State<PasarCheckoutPage> createState() => _PasarCheckoutPageState();
}

class _PasarCheckoutPageState extends State<PasarCheckoutPage> {
  final PasarCheckoutService _pasarCheckoutService = PasarCheckoutService();
  String _deliveryMethod = 'Ambil Sendiri';

  // Unified Payment State matching Gas & Rental services
  String _paymentCategory = 'tunai'; // 'tunai', 'bank', 'ewallet'
  String? _selectedBank;
  String? _selectedEWallet;

  final List<String> _bankOptions = ['bca', 'bri', 'bni', 'mandiri'];
  final List<String> _eWalletOptions = ['qris', 'gopay', 'dana'];

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  final formatCurrency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  double get _ongkir => _deliveryMethod == 'Diantar' ? 5000 : 0;
  double get _grandTotal => widget.totalAmount + _ongkir;

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitOrder() async {
    if (_deliveryMethod == 'Diantar' &&
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Alamat pengiriman wajib diisi untuk layanan Diantar',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (_paymentCategory == 'bank' && _selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Silakan pilih Bank tujuan transfer Virtual Account',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    if (_paymentCategory == 'ewallet' && _selectedEWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Silakan pilih opsi E-Wallet / QRIS'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    String finalPaymentMethod = 'COD';
    if (_paymentCategory == 'bank') {
      finalPaymentMethod = _selectedBank ?? 'virtual_account';
    } else if (_paymentCategory == 'ewallet') {
      finalPaymentMethod = _selectedEWallet ?? 'qris';
    }

    final result = await _pasarCheckoutService.checkout(
      _deliveryMethod,
      deliveryAddress: _deliveryMethod == 'Diantar'
          ? _addressController.text.trim()
          : null,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      paymentMethod: finalPaymentMethod,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      final order = result['order'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PasarPaymentPage(
            orderId: order['id'],
            orderNumber: order['order_number'] ?? '',
            grandTotal: order['grand_total'] != null
                ? double.parse(order['grand_total'].toString())
                : widget.totalAmount,
            paymentMethod: finalPaymentMethod,
            paymentVaNumber: order['payment_va_number'],
            paymentQrUrl: order['payment_qr_url'],
            paymentExpiryTime: order['payment_expiry_time'],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Terjadi kesalahan saat checkout'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  String _formatBankName(String val) {
    switch (val.toLowerCase()) {
      case 'bca':
        return 'BCA Virtual Account';
      case 'bri':
        return 'BRI Virtual Account';
      case 'bni':
        return 'BNI Virtual Account';
      case 'mandiri':
        return 'Mandiri Virtual Account';
      default:
        return val.toUpperCase();
    }
  }

  String _formatEWalletName(String val) {
    switch (val.toLowerCase()) {
      case 'qris':
        return 'QRIS (Instant Payment)';
      case 'gopay':
        return 'GoPay';
      case 'dana':
        return 'DANA';
      default:
        return val.toUpperCase();
    }
  }

  String _getSelectedPaymentLabel() {
    if (_paymentCategory == 'tunai') {
      return 'Bayar Tunai (COD)';
    } else if (_paymentCategory == 'bank' && _selectedBank != null) {
      return _formatBankName(_selectedBank!);
    } else if (_paymentCategory == 'ewallet' && _selectedEWallet != null) {
      return _formatEWalletName(_selectedEWallet!);
    }
    return 'Pilih Metode Pembayaran';
  }

  Widget _buildPaymentLogo(
    String key, {
    double width = 46,
    double height = 26,
  }) {
    String? assetPath;
    switch (key.toLowerCase()) {
      case 'bca':
        assetPath = 'assets/images/banks/bca.png';
        break;
      case 'bri':
        assetPath = 'assets/images/banks/bri.png';
        break;
      case 'bni':
        assetPath = 'assets/images/banks/bni.png';
        break;
      case 'mandiri':
        assetPath = 'assets/images/banks/mandiri.png';
        break;
      case 'gopay':
        assetPath = 'assets/images/banks/gopay.png';
        break;
      case 'dana':
        assetPath = 'assets/images/banks/dana.png';
        break;
      case 'qris':
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

    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300, width: 0.8),
      ),
      child: const Icon(Icons.payment, size: 16, color: Colors.blue),
    );
  }

  Widget _getSelectedPaymentLeadingWidget(bool isDark) {
    final primaryColor = const Color(0xFF2563EB);

    if (_paymentCategory == 'tunai') {
      return Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: primaryColor.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.payments_outlined, color: primaryColor, size: 18),
      );
    } else if (_paymentCategory == 'bank' && _selectedBank != null) {
      return _buildPaymentLogo(_selectedBank!, width: 44, height: 26);
    } else if (_paymentCategory == 'ewallet' && _selectedEWallet != null) {
      return _buildPaymentLogo(_selectedEWallet!, width: 44, height: 26);
    }
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: primaryColor.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.payment_rounded, color: primaryColor, size: 18),
    );
  }

  void _showPaymentPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2563EB);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
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
                            color: isDark ? Colors.white24 : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pilih Metode Pembayaran',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Option 1: Bayar Tunai (COD)
                      _buildModalPaymentItem(
                        iconWidget: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: primaryColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.payments_outlined,
                            color: primaryColor,
                            size: 20,
                          ),
                        ),
                        title: 'Bayar Tunai (COD)',
                        subtitle:
                            'Bayar uang pas saat kurir mengantar / ambil di toko',
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
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _paymentCategory == 'bank'
                                ? primaryColor
                                : (isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0)),
                            width: _paymentCategory == 'bank' ? 1.5 : 1,
                          ),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: _paymentCategory == 'bank',
                          shape: const Border(),
                          collapsedShape: const Border(),
                          leading:
                              _paymentCategory == 'bank' &&
                                  _selectedBank != null
                              ? _buildPaymentLogo(_selectedBank!)
                              : Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withAlpha(20),
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
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: _paymentCategory == 'bank'
                                  ? primaryColor
                                  : (isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A)),
                            ),
                          ),
                          subtitle: Text(
                            'BCA, BRI, BNI, Mandiri',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B),
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
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _paymentCategory == 'ewallet'
                                ? primaryColor
                                : (isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0)),
                            width: _paymentCategory == 'ewallet' ? 1.5 : 1,
                          ),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: _paymentCategory == 'ewallet',
                          shape: const Border(),
                          collapsedShape: const Border(),
                          leading:
                              _paymentCategory == 'ewallet' &&
                                  _selectedEWallet != null
                              ? _buildPaymentLogo(_selectedEWallet!)
                              : Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.qr_code_2_rounded,
                                    color: primaryColor,
                                    size: 20,
                                  ),
                                ),
                          title: Text(
                            _paymentCategory == 'ewallet' &&
                                    _selectedEWallet != null
                                ? _formatEWalletName(_selectedEWallet!)
                                : 'E-Wallet / QRIS Instant',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: _paymentCategory == 'ewallet'
                                  ? primaryColor
                                  : (isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A)),
                            ),
                          ),
                          subtitle: Text(
                            'QRIS Instant, GoPay, DANA',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF64748B),
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
    final primaryColor = const Color(0xFF2563EB);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                iconWidget,
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? primaryColor
                              : (isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: primaryColor,
                    size: 20,
                  )
                else
                  Icon(
                    Icons.radio_button_unchecked_rounded,
                    color: isDark ? Colors.white30 : const Color(0xFFCBD5E1),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(
    int step,
    String title,
    bool isActive,
    bool isFinished,
    bool isDark,
  ) {
    final activeColor = const Color(0xFF2563EB);
    final inactiveColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isActive || isFinished ? activeColor : inactiveColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isFinished
              ? const Icon(Icons.check, color: Colors.white, size: 15)
              : Text(
                  step.toString(),
                  style: TextStyle(
                    color: isActive
                        ? Colors.white
                        : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: isActive || isFinished
                ? activeColor
                : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepper(bool isDark) {
    final activeLineColor = const Color(0xFF2563EB);
    final inactiveLineColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStep(1, 'Keranjang', false, true, isDark),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: activeLineColor,
            ),
          ),
          _buildStep(2, 'Checkout', true, false, isDark),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: inactiveLineColor,
            ),
          ),
          _buildStep(3, 'Pembayaran', false, false, isDark),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption({
    required String title,
    required String value,
    required IconData icon,
    required String badgeText,
    required Color badgeColor,
    required bool isDark,
  }) {
    final isSelected = _deliveryMethod == value;
    final primaryColor = const Color(0xFF2563EB);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 15 : 4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _deliveryMethod = value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withAlpha(20)
                        : (isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? primaryColor
                        : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withAlpha(20),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? primaryColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : (isDark ? Colors.white30 : const Color(0xFFCBD5E1)),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStepper(isDark),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Metode Pengiriman
                  Text(
                    'Metode Pengiriman',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDeliveryOption(
                    title: 'Ambil Sendiri di Toko',
                    value: 'Ambil Sendiri',
                    icon: Icons.store_mall_directory_outlined,
                    badgeText: 'Gratis Ongkir',
                    badgeColor: const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                  _buildDeliveryOption(
                    title: 'Diantar Kurir Lokal',
                    value: 'Diantar',
                    icon: Icons.delivery_dining_outlined,
                    badgeText: 'Same-day • Rp 5.000',
                    badgeColor: primaryColor,
                    isDark: isDark,
                  ),

                  // Alamat Pengiriman
                  if (_deliveryMethod == 'Diantar') ...[
                    const SizedBox(height: 10),
                    Text(
                      'Alamat Pengiriman',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Contoh: Dusun Mawar RT 02 / RW 01, Rumah Pagar Hitam...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: primaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // 2. METODE PEMBAYARAN TILE (STANDAR PERSIS SEPERTI LAYANAN LAIN)
                  Text(
                    'Metode Pembayaran',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 15 : 4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _showPaymentPicker,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              _getSelectedPaymentLeadingWidget(isDark),
                              const SizedBox(width: 12),
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
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Ketuk untuk memilih metode lain',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.white54
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey[400],
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 3. Catatan Pesanan
                  Text(
                    'Catatan Pesanan (Opsional)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Contoh: Titip di pos ronda / hubungi sebelum antar...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 6),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal Barang',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    formatCurrency.format(widget.totalAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ongkos Kirim',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    _ongkir == 0 ? 'Gratis' : formatCurrency.format(_ongkir),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: _ongkir == 0
                          ? const Color(0xFF10B981)
                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(
                  height: 1,
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Grand Total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    formatCurrency.format(_grandTotal),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17.5,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Buat Pesanan',
                          style: TextStyle(
                            fontSize: 14.5,
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
}
