import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentInstructionPage extends StatelessWidget {
  final Map<String, dynamic> paymentData;
  final VoidCallback onFinish;

  const PaymentInstructionPage({
    super.key,
    required this.paymentData,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final String channel = paymentData['channel']?.toString() ?? 'Metode Pembayaran';
    final String vaNumber = paymentData['va_number']?.toString() ?? '';
    final String qrUrl = paymentData['qr_url']?.toString() ?? '';
    final String amount = paymentData['total_amount']?.toString() ?? '0';
    
    // Format nominal ke Rupiah
    final amountFormatted = 'Rp ${amount.replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onFinish();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Instruksi Pembayaran'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: onFinish,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sukses Icon
              const Center(
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 80,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pesanan Berhasil Dibuat!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selesaikan pembayaran Anda agar pesanan dapat segera diproses.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              // Kartu Informasi Pembayaran
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Total Pembayaran',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      amountFormatted,
                      style: const TextStyle(
                        fontSize: 28,
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
                    const SizedBox(height: 20),

                    // Jika metode QRIS
                    if (qrUrl.isNotEmpty && qrUrl != 'DUMMY_QR_CODE') ...[
                      const Text(
                        'Scan QR Code ini',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Image.network(
                        qrUrl,
                        height: 200,
                        width: 200,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.qr_code, size: 200),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Buka aplikasi e-Wallet atau M-Banking Anda, lalu scan QR di atas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ]
                    // Jika metode Virtual Account (Bank Transfer)
                    else if (vaNumber.isNotEmpty) ...[
                      Text(
                        'Nomor Virtual Account',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              vaNumber,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: vaNumber));
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
                      // Fallback jika tidak ada VA/QR (contoh: tunai)
                      Text(
                        'Instruksi pembayaran akan dikonfirmasi oleh Admin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: onFinish,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Selesai & Kembali ke Beranda',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
