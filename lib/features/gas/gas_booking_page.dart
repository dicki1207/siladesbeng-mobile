import 'dart:convert';
import 'package:flutter/material.dart';
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
  String _deliveryMethod = 'antar';

  // Payment Method logic
  String _paymentCategory = 'tunai'; // 'tunai', 'bank', 'ewallet'
  String? _selectedBank;
  String? _selectedEWallet;

  final _addressController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  final List<String> _bankOptions = [
    'bank_transfer_bca',
    'bank_transfer_bri',
    'bank_transfer_bni',
    'bank_transfer_mandiri',
  ];

  final List<String> _eWalletOptions = ['qris', 'gopay'];

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
              _addressController.text =
                  "RT ${user['rt'] ?? '-'} / RW ${user['rw'] ?? '-'}";
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

    if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
      _showError('Mohon lengkapi Nama dan Alamat Anda');
      return;
    }

    if (_paymentCategory == 'bank' && _selectedBank == null) {
      _showError('Silakan pilih Bank');
      return;
    }

    if (_paymentCategory == 'ewallet' && _selectedEWallet == null) {
      _showError('Silakan pilih E-Wallet');
      return;
    }

    // SIMULASI MASA KRISIS: Cegat pesanan jika belum verifikasi KK
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
        // Continue with booking
      } else {
        return; // Blocked or cancelled
      }
    }

    try {
      final token = prefs.getString('auth_token');

      if (token == null) {
        _showError('Sesi berakhir, silakan login kembali.');
        return;
      }

      // Show loading indicator in a dialog to block UI
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

      final body = {
        'gas_id': widget.item['id'].toString(),
        'delivery_method': _deliveryMethod,
        'buyer_name': _nameController.text,
        'buyer_address': _addressController.text,
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
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              content: const Text(
                'Pesanan Gas Berhasil!\n\nMohon siapkan pembayaran Anda (Tunai).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context); // Pop booking page
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('OK', style: TextStyle(color: Colors.white)),
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
      if (mounted) Navigator.pop(context); // Close loading dialog if error
      _showError('Terjadi kesalahan jaringan.');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
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

  Widget _buildPaymentOption(
    String value,
    String title,
    String subtitle,
    IconData icon, {
    Widget? child,
  }) {
    bool isSelected = _paymentCategory == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentCategory = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withAlpha(20)
              : Theme.of(context).cardColor,
          border: Border.all(
            color: isSelected ? Colors.blue : Theme.of(context).dividerColor,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final fieldColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.withAlpha(20);

    final int price = double.tryParse(
      widget.item['harga_satuan']?.toString() ??
          widget.item['price']?.toString() ??
          '0',
    )?.toInt() ?? 0;
    final int total = price * _quantity;
    final int stock =
        int.tryParse(widget.item['stok']?.toString() ?? '10') ?? 10;

    final String imageUrl =
        widget.item['image_url'] ??
        widget.item['image'] ??
        'https://via.placeholder.com/150';
    final String itemName =
        widget.item['jenis_gas'] ?? widget.item['name'] ?? 'Gas LPG';

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Pembelian Gas',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Lokasi BUMDes
          const Text(
            'Alamat BUMDes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
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
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item['region']?['bumdes_name'] ??
                            'BUMDes Desa Anda',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pusat Distribusi Gas',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.location_on, color: Colors.red),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Pengiriman
          const Text(
            'Metode Pengiriman',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _deliveryMethod = 'antar'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _deliveryMethod == 'antar'
                          ? Colors.blue.withAlpha(20)
                          : cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _deliveryMethod == 'antar'
                            ? Colors.blue
                            : (isDark ? Colors.grey[800]! : Colors.grey.withAlpha(50)),
                        width: _deliveryMethod == 'antar' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          size: 28,
                          color: _deliveryMethod == 'antar'
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Diantar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _deliveryMethod == 'antar'
                                ? Colors.blue
                                : Colors.grey,
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
                  onTap: () => setState(() => _deliveryMethod = 'jemput'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _deliveryMethod == 'jemput'
                          ? Colors.blue.withAlpha(20)
                          : cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _deliveryMethod == 'jemput'
                            ? Colors.blue
                            : (isDark ? Colors.grey[800]! : Colors.grey.withAlpha(50)),
                        width: _deliveryMethod == 'jemput' ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.store,
                          size: 28,
                          color: _deliveryMethod == 'jemput'
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ambil Sendiri',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _deliveryMethod == 'jemput'
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section: Data Pemesan
          const Text(
            'Detail Pemesan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
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
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Nama Lengkap',
                    labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: fieldColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  maxLines: 2,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Alamat Lengkap',
                    labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700]),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: fieldColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section: Detail Produk
          const Text(
            'Detail Produk',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
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
                    child: (imageUrl.startsWith('assets/') || imageUrl.contains('F2.png'))
                        ? Image.asset(
                            'assets/images/F2.png',
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.propane_tank,
                              size: 40,
                              color: Colors.grey,
                            ),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.propane_tank,
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
                        itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp. $price',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Tersedia',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                                    if (_quantity > 1) {
                                      setState(() => _quantity--);
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
                                  '$_quantity',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    if (_quantity < stock) {
                                      setState(() => _quantity++);
                                    }
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

          // Section: Metode Pembayaran
          const Text(
            'Metode Pembayaran',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),

          _buildPaymentOption(
            'tunai',
            'Bayar Tunai',
            'Bayar langsung di tempat',
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
                color: Colors.white,
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
                          child: Text(
                            _formatBankName(val),
                            style: const TextStyle(fontSize: 14),
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
                color: Colors.white,
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
                          child: Text(
                            _formatEWalletName(val),
                            style: const TextStyle(fontSize: 14),
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
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
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
                    'Rp. $total',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Pesan Sekarang',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
