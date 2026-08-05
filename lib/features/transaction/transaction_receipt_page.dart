import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:siladesbeng_mobile/widgets/ticket_card.dart';
import 'package:url_launcher/url_launcher.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Unduh Bukti Transaksi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Membagikan PDF Bukti Transaksi...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menyimpan PDF ke perangkat...')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Kopsurat (Watermark)
          Positioned.fill(
            child: Image.network(
              'http://10.250.3.148:8000/User/img/buktilapor/Halaman1buktipelaporan(kopsurat).png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Text('Watermark tidak dapat dimuat'));
              },
            ),
          ),
          
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 40),
              child: Container(
                color: Colors.white.withAlpha(220),
                padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // HEADER INFO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Bukti Transaksi\n$type',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Nomor Ref: $orderNumber',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

              // INFO PESANAN
              _buildInfoRow('No. Pesanan', orderNumber),
              _buildInfoRow('Waktu Pesan', orderTime),
              _buildInfoRow('Akun Pemesan', accountName),
              _buildInfoRow('Email Akun', accountEmail),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: DashedLineSeparator(),
              ),

              // NAMA DAN ALAMAT
              Text(
                type == 'Gas' ? 'Nama dan Alamat Pembeli Gas' : 'Nama dan Alamat Penyewa',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Nama Lengkap', recipientName),
              _buildInfoRow('Alamat', address),
              if (rentalPurpose != null && rentalPurpose!.isNotEmpty)
                _buildInfoRow('Tujuan', rentalPurpose!),
              if (type != 'Gas')
                _buildInfoRow('Pengiriman', deliveryMethod),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: DashedLineSeparator(),
              ),

              // INFO PEMBAYARAN
              Text(
                'Informasi Pembayaran',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Waktu Bayar', paymentTime),
              _buildInfoRow('Metode', paymentMethod.toUpperCase().replaceAll('_', ' ')),
              _buildInfoRow('Total Bayar', totalPayment),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Status',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const Text(' : ', style: TextStyle(fontSize: 12)),
                    Expanded(
                      flex: 3,
                      child: Text(
                        status,
                        style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: DashedLineSeparator(),
              ),

              // DETAIL PEMBELIAN
              Text(
                'Detail Pesanan',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(flex: 2, child: Text('Keterangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700]))),
                  Expanded(flex: 1, child: Text('Jml', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700]))),
                  Expanded(flex: 2, child: Text('Satuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700]))),
                  Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700]))),
                ],
              ),
              const Divider(thickness: 1),
              Row(
                children: [
                  Expanded(flex: 2, child: Text(itemName, style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87))),
                  Expanded(flex: 1, child: Text('$qty', style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87))),
                  Expanded(flex: 2, child: Text(pricePerItem, style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87))),
                  Expanded(flex: 2, child: Text(totalPayment, style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87))),
                ],
              ),
              const Divider(thickness: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(flex: 3, child: SizedBox()),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Pesanan', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700])),
                            Text(totalPayment, style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Dibayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
                            Text(totalPayment, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : Colors.black87)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // QR CODE & FOOTER
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.white,
                      child: QrImageView(
                        data: orderNumber,
                        version: QrVersions.auto,
                        size: 100.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bengkalis, ${orderTime.split(' ').first}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hormat Kami',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'SiladesBeng',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Text(
                      'Platform E-Government Kab. Bengkalis',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Download Button
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    String routeType = 'rental';
                    if (type == 'Gas') routeType = 'gas';
                    if (type == 'Sewa Mobil') routeType = 'mobil';
                    if (type == 'Fasilitas') routeType = 'fasilitas';

                    final id = orderNumber.replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    ); // extract number for dummy ID

                    final url = Uri.parse(
                      'http://10.250.3.148:8000/receipt/$routeType/$id/download',
                    );

                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Tidak dapat membuka tautan unduhan struk $type',
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'Unduh Struk Resmi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ],
),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ),
              Text(' : ', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[700])),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}
