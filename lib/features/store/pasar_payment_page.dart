import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
      SnackBar(
        content: Text('$label berhasil disalin ke clipboard!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildPaymentInstructions(bool isDark) {
    final primaryColor = const Color(0xFF2563EB);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    if (widget.paymentMethod == 'cod' || widget.paymentMethod == 'tunai') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 20 : 6),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.payments_outlined, size: 40, color: primaryColor),
            ),
            const SizedBox(height: 14),
            Text(
              "Bayar Tunai / COD",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Siapkan uang pas saat pesanan diantar kurir atau saat Anda mengambil barang di toko.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    } else if (widget.paymentMethod == 'transfer_manual') {
      const String rekName = "BRI";
      const String rekNumber = "1234-5678-9012";
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 20 : 6),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.account_balance_outlined, size: 36, color: primaryColor),
            ),
            const SizedBox(height: 14),
            Text(
              "Transfer ke Rekening Resmi:",
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "$rekName - $rekNumber",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _copyToClipboard(rekNumber, "Nomor Rekening"),
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text("Salin Rekening", style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      );
    } else if (widget.paymentMethod == 'qris') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 20 : 6),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.qr_code_2_rounded, size: 36, color: primaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              "Scan QRIS untuk Membayar",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),
            if (widget.paymentQrUrl != null && widget.paymentQrUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.paymentQrUrl!,
                  height: 180,
                  width: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    width: 180,
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    child: const Center(child: Icon(Icons.qr_code, size: 80, color: Colors.grey)),
                  ),
                ),
              )
            else
              Container(
                height: 160,
                width: 160,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.qr_code_2, size: 80, color: primaryColor),
                ),
              ),
          ],
        ),
      );
    } else if (widget.paymentMethod == 'virtual_account') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 20 : 6),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.credit_card_rounded, size: 36, color: primaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              "Nomor Virtual Account:",
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.paymentVaNumber ?? "8808 1234 5678 9012",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _copyToClipboard(
                widget.paymentVaNumber ?? "8808123456789012",
                "Nomor Virtual Account",
              ),
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text("Salin Nomor VA", style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2563EB);
    final isWarningTime = _remainingTime.inMinutes < 30 && _remainingTime.inSeconds > 0;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'Pembayaran',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          backgroundColor: const Color(0xFF2563EB),
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
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
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dynamic Header Card
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withAlpha(60),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      "Pesanan Berhasil Dibuat!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Nomor Pesanan: ${widget.orderNumber}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(height: 1, color: Colors.white24),
                    const SizedBox(height: 14),
                    const Text(
                      "Total Pembayaran",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(widget.grandTotal),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),

              // Countdown Timer
              if (_expiryTime != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        "Batas Waktu Pembayaran:",
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDuration(_remainingTime),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: isWarningTime ? const Color(0xFFEF4444) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Payment Instructions
              _buildPaymentInstructions(isDark),

              const SizedBox(height: 40),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Kembali ke Beranda', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
