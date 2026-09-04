import 'dart:async';
import 'package:siladesbeng_mobile/widgets/custom_cached_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';

class PaymentInstructionPage extends StatefulWidget {
  final Map<String, dynamic> paymentData;
  final VoidCallback onFinish;

  const PaymentInstructionPage({
    super.key,
    required this.paymentData,
    required this.onFinish,
  });

  @override
  State<PaymentInstructionPage> createState() => _PaymentInstructionPageState();
}

class _PaymentInstructionPageState extends State<PaymentInstructionPage> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    final expiryTimeStr = widget.paymentData['expiry_time'];
    if (expiryTimeStr == null || expiryTimeStr.isEmpty) return;

    final expiryTime = DateTime.tryParse(expiryTimeStr);
    if (expiryTime == null) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final difference = expiryTime.difference(now);

      if (difference.isNegative) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _remainingTime = Duration.zero;
            _isExpired = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _remainingTime = difference;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final String channel =
        widget.paymentData['channel']?.toString() ?? 'Metode Pembayaran';
    final String vaNumber = widget.paymentData['va_number']?.toString() ?? '';
    final String qrUrl = widget.paymentData['qr_url']?.toString() ?? '';
    final String amount = widget.paymentData['total_amount']?.toString() ?? '0';

    // Format nominal ke Rupiah
    final amountFormatted =
        'Rp ${amount.replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        widget.onFinish();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Instruksi Pembayaran',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17.sp,
              letterSpacing: 0.3,
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF2563EB),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: widget.onFinish,
          ),
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
          padding: EdgeInsets.all(24.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timer
              if (widget.paymentData['expiry_time'] != null && !_isExpired)
                Container(
                  margin: EdgeInsets.only(bottom: 24.h),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            color: Colors.red[700],
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'SELESAIKAN PEMBAYARAN DALAM',
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        _formatDuration(_remainingTime),
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isExpired)
                Container(
                  margin: EdgeInsets.only(bottom: 24.h),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Text(
                      'WAKTU PEMBAYARAN HABIS',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Kartu Informasi Pembayaran
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    Text(
                      'Total Pembayaran',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      amountFormatted,
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const Divider(height: 32),

                    // Metode
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Metode',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          channel.toUpperCase().replaceAll('_', ' '),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // Jika metode QRIS
                    if (qrUrl.isNotEmpty && qrUrl != 'DUMMY_QR_CODE') ...[
                      const Text(
                        'Scan QR Code ini',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10.h),
                      CustomCachedImage(
                        qrUrl,
                        height: 200,
                        width: 200,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.qr_code, size: 200.sp),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Buka aplikasi e-Wallet atau M-Banking Anda, lalu scan QR di atas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                    ]
                    // Jika metode Virtual Account (Bank Transfer)
                    else if (vaNumber.isNotEmpty) ...[
                      Text(
                        'Nomor Virtual Account',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              vaNumber,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: vaNumber),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nomor VA disalin!'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: const Icon(
                                Icons.copy,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Instruksi pembayaran akan dikonfirmasi oleh Admin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              ElevatedButton(
                onPressed: widget.onFinish,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Selesai & Kembali ke Beranda',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
