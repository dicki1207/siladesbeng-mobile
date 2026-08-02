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

  String _getUnitName() {
    if (type == 'Gas') return 'Unit Pembelian Gas';
    if (type == 'Sewa Mobil') return 'Unit Penyewaan Kendaraan';
    if (type == 'Sewa Alat') return 'Unit Penyewaan Alat';
    if (type == 'Fasilitas') return 'Unit Penyewaan Fasilitas';
    return 'Unit Pelayanan Terpadu';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Bukti Transaksi'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: TicketCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo
                  Row(
                    children: [
                      Image.network(
                        'http://10.193.206.148:8000/assets/img/logo.png', // Fallback
                        height: 40,
                        errorBuilder: (c, e, s) => const Icon(Icons.description, color: Colors.blue, size: 40),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SiladesBeng',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Bukti Transaksi',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        Text(
                          _getUnitName(),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
              const Text(
                'Informasi Pembayaran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
              const Text(
                'Detail Pesanan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Expanded(flex: 2, child: Text('Keterangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 1, child: Text('Jml', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 2, child: Text('Satuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              const Divider(thickness: 1),
              Row(
                children: [
                  Expanded(flex: 2, child: Text(itemName, style: const TextStyle(fontSize: 12))),
                  Expanded(flex: 1, child: Text('$qty', style: const TextStyle(fontSize: 12))),
                  Expanded(flex: 2, child: Text(pricePerItem, style: const TextStyle(fontSize: 12))),
                  Expanded(flex: 2, child: Text(totalPayment, style: const TextStyle(fontSize: 12))),
                ],
              ),
              const Divider(thickness: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(flex: 5, child: SizedBox()),
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pesanan', style: TextStyle(fontSize: 12)),
                            Text(totalPayment, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Dibayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(totalPayment, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                    Text(
                      'Bengkalis, ${orderTime.split(' ').first}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Hormat Kami',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    QrImageView(
                      data: orderNumber,
                      version: QrVersions.auto,
                      size: 100.0,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'SiladesBeng',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Platform E-Government Kab. Bengkalis',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
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
                      'http://10.193.206.148:8000/receipt/$routeType/$id/download',
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const Text(' : ', style: TextStyle(fontSize: 12)),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
