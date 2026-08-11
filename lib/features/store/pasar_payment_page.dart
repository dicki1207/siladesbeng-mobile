import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class PasarPaymentPage extends StatefulWidget {
  final int orderId;
  final String orderNumber;
  final double grandTotal;
  final String paymentMethod;
  final String? paymentVaNumber;
  final String? paymentQrUrl;
  final String? paymentExpiryTime; // ISO 8601 datetime string
  
  const PasarPaymentPage({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.grandTotal,
    required this.paymentMethod,
    this.paymentVaNumber,
    this.paymentQrUrl,
    this.paymentExpiryTime,
  });

  @override
  State<PasarPaymentPage> createState() => _PasarPaymentPageState();
}

class _PasarPaymentPageState extends State<PasarPaymentPage> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  DateTime? _expiryTime;

  @override
  void initState() {
    super.initState();
    if (widget.paymentExpiryTime != null) {
      _expiryTime = DateTime.tryParse(widget.paymentExpiryTime!);
      if (_expiryTime != null) {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    final now = DateTime.now();
    if (_expiryTime!.isAfter(now)) {
      _remainingTime = _expiryTime!.difference(now);
    }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (_expiryTime!.isAfter(now)) {
        setState(() {
          _remainingTime = _expiryTime!.difference(now);
        });
      } else {
        setState(() {
          _remainingTime = Duration.zero;
        });
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label berhasil disalin!')),
    );
  }

  Widget _buildPaymentInstructions() {
    if (widget.paymentMethod == 'cod' || widget.paymentMethod == 'tunai') {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.money, size: 64, color: Color(0xFF0EA5E9)),
              SizedBox(height: 16),
              Text(
                "Bayar tunai saat barang diterima atau saat pengambilan.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    } else if (widget.paymentMethod == 'transfer_manual') {
      const String rekName = "BRI";
      const String rekNumber = "1234-5678-9012";
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.account_balance, size: 64, color: Color(0xFF0EA5E9)),
              const SizedBox(height: 16),
              const Text(
                "Transfer ke Rekening:",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                "$rekName: $rekNumber",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _copyToClipboard(rekNumber, "Nomor Rekening"),
                icon: const Icon(Icons.copy, size: 18),
                label: const Text("Salin"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (widget.paymentMethod == 'qris') {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.qr_code_2, size: 64, color: Color(0xFF0EA5E9)),
              const SizedBox(height: 16),
              const Text(
                "Scan QRIS untuk membayar",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              if (widget.paymentQrUrl != null && widget.paymentQrUrl!.isNotEmpty)
                Image.network(
                  widget.paymentQrUrl!,
                  height: 200,
                  width: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 100,
                    color: Colors.grey,
                  ),
                )
              else
                Container(
                  height: 200,
                  width: 200,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Text(
                      "QR Code tidak tersedia",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } else if (widget.paymentMethod == 'virtual_account') {
      return Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(Icons.payments, size: 64, color: Color(0xFF0EA5E9)),
              const SizedBox(height: 16),
              const Text(
                "Nomor Virtual Account:",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              if (widget.paymentVaNumber != null && widget.paymentVaNumber!.isNotEmpty)
                Column(
                  children: [
                    Text(
                      widget.paymentVaNumber!,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _copyToClipboard(widget.paymentVaNumber!, "Nomor Virtual Account"),
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text("Salin"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                )
              else
                const Text(
                  "Menunggu info VA...",
                  style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.grey),
                ),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWarningTime = _remainingTime.inMinutes < 30 && _remainingTime.inSeconds > 0;
    
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pembayaran', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF0EA5E9),
          automaticallyImplyLeading: false, // Hide back button
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dynamic Header Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 80, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      "Pesanan Berhasil Dibuat!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.orderNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Total Pembayaran",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrency(widget.grandTotal),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Countdown Timer
              if (_expiryTime != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const Text(
                        "Selesaikan pembayaran sebelum:",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDuration(_remainingTime),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isWarningTime ? Colors.red : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                
              const SizedBox(height: 24),
              
              // Payment Instructions
              _buildPaymentInstructions(),
              
              const SizedBox(height: 48),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Kembali ke Beranda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    // The user can open the market again from the home page
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0EA5E9),
                    side: const BorderSide(color: Color(0xFF0EA5E9)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Belanja Lagi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
