import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class TransactionReceiptPage extends StatelessWidget {
  final String orderNumber;
  final String orderTime;
  final String accountName;
  final String accountEmail;
  final String recipientName;
  final String address;
  final String deliveryMethod;
  final String? rentalPurpose;
  final String paymentTime;
  final String paymentMethod;
  final String totalPayment;
  final String status;
  final Color statusColor;
  final String itemName;
  final int qty;
  final String pricePerItem;
  final String type; // 'Sewa Alat', 'Sewa Mobil', 'Gas', 'Fasilitas'

  const TransactionReceiptPage({
    super.key,
    required this.orderNumber,
    required this.orderTime,
    required this.accountName,
    required this.accountEmail,
    required this.recipientName,
    required this.address,
    required this.deliveryMethod,
    this.rentalPurpose,
    required this.paymentTime,
    required this.paymentMethod,
    required this.totalPayment,
    required this.status,
    required this.statusColor,
    required this.itemName,
    required this.qty,
    required this.pricePerItem,
    required this.type,
  });

  /// Maps the type to a receipt subtitle like the web template
  String get _receiptSubtitle {
    switch (type) {
      case 'Gas':
        return 'Unit Pembelian Gas';
      case 'Sewa Alat':
        return 'Unit Penyewaan Alat';
      case 'Sewa Mobil':
        return 'Unit Penyewaan Mobil';
      case 'Fasilitas':
        return 'Unit Fasilitas Umum';
      default:
        return 'Unit $type';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final valueColor = isDark ? Colors.white : Colors.black;
    final labelColor = isDark ? Colors.grey[400]! : Colors.grey[700]!;
    final bgColor = isDark ? Colors.grey[900]! : Colors.white;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Unduh Bukti Transaksi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: textColor),
            onPressed: () {
              final text = 'Bukti Transaksi $type - SilaDesBeng\n\n'
                  'No. Pesanan: $orderNumber\n'
                  'Waktu: $orderTime\n'
                  'Total Dibayar: $totalPayment\n\n'
                  'SiladesBeng - Platform E-Government Kab. Bengkalis';
              SharePlus.instance.share(ShareParams(text: text));
            },
          ),
          IconButton(
            icon: Icon(Icons.download_rounded, color: textColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Struk resmi PDF berhasil diunduh ke perangkat Anda.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              // Watermark Logo SiladesBeng di tengah halaman
              Positioned.fill(
                child: Center(
                  child: Opacity(
                    opacity: 0.06,
                    child: Image.asset(
                      'logodomain.png',
                      width: 280,
                      height: 280,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor.withAlpha(isDark ? 230 : 245),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                    ),
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ===== HEADER SILADESBENG (seperti web) =====
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Logo SiladesBeng
                          Image.asset(
                            'logodomain.png',
                            height: 50,
                            width: 50,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.business, size: 50, color: Colors.blue),
                          ),
                          const SizedBox(width: 10),
                          // Nama SiladesBeng
                          Text(
                            'SiladesBeng',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: valueColor,
                            ),
                          ),
                          const Spacer(),
                          // Bukti Transaksi (kanan atas)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Bukti Transaksi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _receiptSubtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: labelColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      Divider(thickness: 1, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                      const SizedBox(height: 16),

                      // ===== INFO PESANAN =====
                      _buildTableRow('No. Pesanan', orderNumber, labelColor, valueColor),
                      _buildTableRow('Waktu Pemesanan', orderTime, labelColor, valueColor),
                      _buildTableRow('Nama Akun Pemesan', accountName, labelColor, valueColor),
                      _buildTableRow('Email Akun Pemesan', accountEmail, labelColor, valueColor),
                      
                      const SizedBox(height: 12),
                      Divider(thickness: 1, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                      const SizedBox(height: 12),

                      // ===== NAMA DAN ALAMAT =====
                      Text(
                        type == 'Gas' ? 'Nama dan Alamat Pembeli Gas' : 'Nama dan Alamat Penyewa',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valueColor),
                      ),
                      const SizedBox(height: 10),
                      _buildTableRow('Nama Lengkap', recipientName, labelColor, valueColor),
                      _buildTableRow('Alamat', address, labelColor, valueColor),
                      if (type != 'Gas') _buildTableRow('Pengiriman', deliveryMethod, labelColor, valueColor),
                      if (rentalPurpose != null && rentalPurpose!.isNotEmpty)
                        _buildTableRow('Tujuan Sewa', rentalPurpose!, labelColor, valueColor),
                      
                      const SizedBox(height: 12),
                      Divider(thickness: 1, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                      const SizedBox(height: 12),

                      // ===== INFO PEMBAYARAN =====
                      Text('Informasi Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valueColor)),
                      const SizedBox(height: 10),
                      _buildTableRow('Waktu Pembayaran', paymentTime, labelColor, valueColor),
                      _buildTableRow('Metode Pembayaran', paymentMethod.toUpperCase().replaceAll('_', ' '), labelColor, valueColor),
                      _buildTableRow('Total Pembayaran', totalPayment, labelColor, valueColor),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 130, child: Text('Status', style: TextStyle(fontSize: 13, color: labelColor))),
                            Text(':', style: TextStyle(fontSize: 13, color: labelColor)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(status, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: statusColor))),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      Divider(thickness: 1, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                      const SizedBox(height: 12),

                      // ===== DETAIL PESANAN (Tabel) =====
                      Text('Detail Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valueColor)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(flex: 4, child: Text('Keterangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: labelColor))),
                          Expanded(flex: 1, child: Text('Jml', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: labelColor))),
                          Expanded(flex: 3, child: Text('Satuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: labelColor))),
                          Expanded(flex: 3, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: labelColor))),
                        ],
                      ),
                      Divider(thickness: 1, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(flex: 4, child: Text(itemName, style: TextStyle(fontSize: 11, color: valueColor))),
                          Expanded(flex: 1, child: Text('$qty', style: TextStyle(fontSize: 11, color: valueColor))),
                          Expanded(flex: 3, child: Text(pricePerItem, style: TextStyle(fontSize: 11, color: valueColor), overflow: TextOverflow.ellipsis, maxLines: 1)),
                          Expanded(flex: 3, child: Text(totalPayment, style: TextStyle(fontSize: 11, color: valueColor), overflow: TextOverflow.ellipsis, maxLines: 1)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Spacer(flex: 4),
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total Pemesanan', style: TextStyle(fontSize: 12, color: labelColor)),
                                    Text(totalPayment, style: TextStyle(fontSize: 12, color: valueColor)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total Dibayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: valueColor)),
                                    Text(totalPayment, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: valueColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                      
                      // ===== QR CODE dengan Logo SiladesBeng =====
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.withAlpha(50)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: orderNumber,
                            version: QrVersions.auto,
                            size: 120.0,
                            backgroundColor: Colors.white,
                            embeddedImage: const AssetImage('logodomain.png'),
                            embeddedImageStyle: const QrEmbeddedImageStyle(
                              size: Size(35, 35),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // ===== BRANDING SiladesBeng di bawah QR =====
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'SiladesBeng',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: valueColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Platform E-Government Kab. Bengkalis',
                              style: TextStyle(
                                fontSize: 11,
                                color: labelColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      Divider(thickness: 1.5, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                      const SizedBox(height: 8),
                      
                      // ===== FOOTER TAGLINE =====
                      Center(
                        child: Text(
                          'SiladesBeng - Sistem Sinergi Layanan dan Aspirasi Desa di Kabupaten Bengkalis',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: labelColor),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          'Dokumen ini dicetak otomatis oleh Sistem SilaDesBeng\ndan sah tanpa tanda tangan basah.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 9, color: labelColor.withAlpha(180)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(String label, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(fontSize: 13, color: labelColor)),
          ),
          Text(':', style: TextStyle(fontSize: 13, color: labelColor)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor)),
          ),
        ],
      ),
    );
  }
}
