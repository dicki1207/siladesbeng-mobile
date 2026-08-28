import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:siladesbeng_mobile/features/profile/verification/verification_page.dart';
import 'package:siladesbeng_mobile/features/gas/gas_kk_scanner_page.dart';
import 'package:siladesbeng_mobile/features/transaction/payment_instruction_page.dart';

class GasBookingPage extends StatefulWidget {
  final dynamic item;
  const GasBookingPage({super.key, required this.item});

  @override
  State<GasBookingPage> createState() => _GasBookingPageState();
}

class _GasBookingPageState extends State<GasBookingPage> {
  int _quantity = 1;
  String _deliveryMethod = 'antar'; // 'antar' or 'jemput'

  // Payment Method State
  String _paymentCategory = 'tunai'; // 'tunai', 'bank', 'ewallet'
  String? _selectedBank;
  String? _selectedEWallet;

  final _addressController = TextEditingController();
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isLoading = false;

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
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://10.250.3.148:8000/api/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final user = data['data']['user'];
          if (mounted) {
            setState(() {
              _nameController.text = user['name'] ?? '';
              final address = user['address'] ?? '';
              final rt = user['rt'] ?? '';
              final rw = user['rw'] ?? '';
              if (address.isNotEmpty) {
                _addressController.text = address;
              } else if (rt.isNotEmpty || rw.isNotEmpty) {
                _addressController.text = "RT $rt / RW $rw";
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Gagal load profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitBooking() async {
    final prefs = await SharedPreferences.getInstance();
    final isVerified = prefs.getBool('is_verified') ?? false;

    if (!isVerified) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Verifikasi Diperlukan',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Untuk menggunakan layanan pemesanan Gas, Anda harus memverifikasi identitas (KYC) terlebih dahulu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nanti', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VerificationPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Verifikasi Sekarang',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (_nameController.text.isEmpty ||
        (_deliveryMethod == 'antar' && _addressController.text.isEmpty)) {
      _showError('Mohon lengkapi Nama dan Alamat Pengantaran');
      return;
    }

    if (_paymentCategory == 'bank' && _selectedBank == null) {
      _showError('Silakan pilih Bank tujuan transfer');
      return;
    }

    if (_paymentCategory == 'ewallet' && _selectedEWallet == null) {
      _showError('Silakan pilih opsi E-Wallet / QRIS');
      return;
    }

    // SIMULASI MASA KRISIS: Verifikasi KK
    bool isCrisisMode = true;
    final hasUploadedKK = prefs.getBool('has_uploaded_kk_gas') ?? false;

    if (isCrisisMode && !hasUploadedKK) {
      if (!mounted) return;
      final bool? isKkValid = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GasKKScannerPage()),
      );

      if (isKkValid == true) {
        await prefs.setBool('has_uploaded_kk_gas', true);
      } else {
        return;
      }
    }

    try {
      final token = prefs.getString('auth_token');

      if (token == null) {
        _showError('Sesi berakhir, silakan login kembali.');
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      String paymentMethodStr = _paymentCategory;
      if (_paymentCategory == 'bank') {
        paymentMethodStr = _selectedBank ?? '';
      } else if (_paymentCategory == 'ewallet') {
        paymentMethodStr = _selectedEWallet ?? '';
      }

      String finalAddress = _addressController.text;
      if (_deliveryMethod == 'jemput') {
        finalAddress = 'Ambil Mandiri di Kantor BUMDes';
      } else if (_noteController.text.isNotEmpty) {
        finalAddress = "$finalAddress (Catatan: ${_noteController.text})";
      }

      final body = {
        'gas_id': widget.item['id'].toString(),
        'delivery_method': _deliveryMethod,
        'buyer_name': _nameController.text,
        'buyer_address': finalAddress,
        'quantity': _quantity.toString(),
        'payment_method': paymentMethodStr,
      };

      final response = await http.post(
        Uri.parse('http://10.250.3.148:8000/api/gas/booking'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: body,
      );

      final data = json.decode(response.body);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200 && data['success'] == true) {
        if (data['payment_data'] != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentInstructionPage(
                paymentData: data['payment_data'],
                onFinish: () {
                  Navigator.pop(context); // Pop booking page
                },
              ),
            ),
          );
        } else {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 70,
              ),
              content: const Text(
                'Pesanan Gas Berhasil Dibuat!\n\nMohon siapkan pembayaran tunai saat pesanan diterima/diambil.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.5, height: 1.4),
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Selesai',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        _showError(data['message'] ?? 'Gagal membuat pesanan');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showError('Terjadi kesalahan jaringan.');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

                    // Option 1: Bayar Tunai (COD)
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
                      title: 'Bayar Tunai (COD)',
                      subtitle: 'Bayar uang pas saat tabung gas diterima',
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

                    // Option 2: Bank Transfer
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
      return 'Bayar Tunai (COD)';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final int price =
        double.tryParse(
          widget.item['harga_satuan']?.toString() ??
              widget.item['price']?.toString() ??
              '0',
        )?.toInt() ??
        0;
    final int total = price * _quantity;
    final int stock =
        int.tryParse(widget.item['stok']?.toString() ?? '10') ?? 10;

    final String imageUrl =
        widget.item['image_url'] ??
        widget.item['image'] ??
        widget.item['foto'] ??
        'assets/images/F2.png';
    final String itemName =
        widget.item['jenis_gas'] ?? widget.item['name'] ?? 'Gas LPG';

    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Pembelian Gas',
          style: TextStyle(
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
          // 1. Delivery Method Section (Side-by-Side Modern Feature Cards with Badges)
          _buildSectionHeader('Metode Pengambilan'),
          const SizedBox(height: 10),
          Row(
            children: [
              // Option A: Diantar ke Rumah
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _deliveryMethod = 'antar'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: _deliveryMethod == 'antar'
                          ? (isDark
                                ? primaryColor.withValues(alpha: 0.18)
                                : const Color(0xFFEFF6FF))
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _deliveryMethod == 'antar'
                            ? primaryColor
                            : (isDark
                                  ? Colors.white12
                                  : const Color(0xFFE2E8F0)),
                        width: _deliveryMethod == 'antar' ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _deliveryMethod == 'antar'
                              ? primaryColor.withValues(
                                  alpha: isDark ? 0.25 : 0.15,
                                )
                              : Colors.black.withValues(
                                  alpha: isDark ? 0.15 : 0.03,
                                ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Header Row: Icon + Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _deliveryMethod == 'antar'
                                    ? primaryColor.withValues(alpha: 0.2)
                                    : (isDark
                                          ? Colors.white10
                                          : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.delivery_dining_rounded,
                                size: 22,
                                color: _deliveryMethod == 'antar'
                                    ? primaryColor
                                    : (isDark
                                          ? Colors.white70
                                          : const Color(0xFF64748B)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Kurir Desa',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Diantar ke Rumah',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Icon(
                              _deliveryMethod == 'antar'
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 18,
                              color: _deliveryMethod == 'antar'
                                  ? primaryColor
                                  : (isDark
                                        ? Colors.white24
                                        : Colors.grey[400]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kurir antar langsung ke alamat',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Option B: Ambil Mandiri
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _deliveryMethod = 'jemput'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: _deliveryMethod == 'jemput'
                          ? (isDark
                                ? const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.15)
                                : const Color(0xFFECFDF5))
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _deliveryMethod == 'jemput'
                            ? const Color(0xFF10B981)
                            : (isDark
                                  ? Colors.white12
                                  : const Color(0xFFE2E8F0)),
                        width: _deliveryMethod == 'jemput' ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _deliveryMethod == 'jemput'
                              ? const Color(
                                  0xFF10B981,
                                ).withValues(alpha: isDark ? 0.25 : 0.15)
                              : Colors.black.withValues(
                                  alpha: isDark ? 0.15 : 0.03,
                                ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Header Row: Icon + Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _deliveryMethod == 'jemput'
                                    ? const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.2)
                                    : (isDark
                                          ? Colors.white10
                                          : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.storefront_rounded,
                                size: 22,
                                color: _deliveryMethod == 'jemput'
                                    ? const Color(0xFF10B981)
                                    : (isDark
                                          ? Colors.white70
                                          : const Color(0xFF64748B)),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Gratis (Rp 0)',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Ambil Mandiri',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            Icon(
                              _deliveryMethod == 'jemput'
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 18,
                              color: _deliveryMethod == 'jemput'
                                  ? const Color(0xFF10B981)
                                  : (isDark
                                        ? Colors.white24
                                        : Colors.grey[400]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ambil di Pangkalan BUMDes',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 2. Dynamic Content: Alamat Pengantaran (jika Diantar) atau Lokasi Pengambilan (jika Ambil Mandiri)
          if (_deliveryMethod == 'antar') ...[
            _buildSectionHeader('Alamat Pengantaran'),
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
                    label: 'Nama Lengkap Pemesan',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildCleanTextField(
                    controller: _addressController,
                    label: 'Alamat Pengantaran (RT / RW / Jalan)',
                    prefixIcon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  _buildCleanTextField(
                    controller: _noteController,
                    label: 'Catatan Pengantaran (Opsional)',
                    hint: 'Contoh: Rumah pagar hitam samping musala',
                    prefixIcon: Icons.edit_note_rounded,
                  ),
                ],
              ),
            ),
          ] else ...[
            _buildSectionHeader('Lokasi Pengambilan (Pick-up)'),
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
                    label: 'Nama Lengkap Pemesan',
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                size: 20,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pangkalan Gas BUMDes Desa',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Kantor BUMDes / Pangkalan Resmi Desa',
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
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_filled_rounded,
                              size: 14,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Jam Layanan: 08.00 - 16.00 WIB',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Silakan bawa tabung kosong (jika tukar) & tunjukkan bukti transaksi digital di aplikasi kepada petugas pangkalan.',
                            style: TextStyle(
                              fontSize: 11,
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
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // 4. Detail Produk Card
          _buildSectionHeader('Produk Dipesan'),
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
                        (imageUrl.startsWith('assets/') ||
                            imageUrl.contains('F2.png'))
                        ? Image.asset(
                            'assets/images/F2.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey[400],
                            ),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.grey[400],
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        itemName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _currencyFormat.format(price),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Stok Tersedia: $stock',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                // Stepper Counter
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(20),
                        ),
                        onTap: () {
                          if (_quantity > 1) {
                            setState(() => _quantity--);
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: Icon(Icons.remove_rounded, size: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(20),
                        ),
                        onTap: () {
                          if (_quantity < stock) {
                            setState(() => _quantity++);
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: Icon(Icons.add_rounded, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 5. Metode Pembayaran Dropdown / Selector Card
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
                              'Ketuk untuk memilih metode lain',
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

          // 6. Rincian Pembayaran (Order Summary)
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
                  label: 'Harga Gas ($_quantity Tabung)',
                  value: _currencyFormat.format(total),
                ),
                const SizedBox(height: 10),
                _buildSummaryRow(
                  label: 'Biaya Pengantaran',
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
                child: ElevatedButton.icon(
                  onPressed: _submitBooking,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text(
                    'Konfirmasi Pesanan',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
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
    _addressController.dispose();
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
