import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:siladesbeng_mobile/widgets/ticket_card.dart';

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
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Bukti Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            TicketCard(
              color: isDark ? Theme.of(context).cardColor : Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          type == 'Gas'
                              ? Icons.local_fire_department
                              : type == 'Sewa Mobil'
                              ? Icons.directions_car
                              : type == 'Sewa Alat'
                              ? Icons.handyman
                              : Icons.home_work,
                          size: 50,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'BUKTI TRANSAKSI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'SILA-DESBENG',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const DashedLineSeparator(),
                  const SizedBox(height: 20),

                  // Info Table
                  _buildInfoRow('No. Pesanan', orderNumber, isDark),
                  _buildInfoRow('Waktu Pemesanan', orderTime, isDark),
                  _buildInfoRow('Nama Akun', accountName, isDark),
                  _buildInfoRow('Email Akun', accountEmail, isDark),

                  const SizedBox(height: 15),
                  const DashedLineSeparator(),
                  const SizedBox(height: 15),

                  const Text(
                    'INFORMASI PENGIRIMAN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow('Nama Penerima', recipientName, isDark),
                  _buildInfoRow('Alamat', address, isDark),
                  _buildInfoRow('Metode', deliveryMethod, isDark),
                  if (rentalPurpose != null)
                    _buildInfoRow('Tujuan Sewa', rentalPurpose!, isDark),

                  const SizedBox(height: 15),
                  const DashedLineSeparator(),
                  const SizedBox(height: 15),

                  const Text(
                    'INFORMASI PEMBAYARAN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow('Waktu Pembayaran', paymentTime, isDark),
                  _buildInfoRow('Metode Pembayaran', paymentMethod, isDark),

                  const SizedBox(height: 15),
                  const DashedLineSeparator(),
                  const SizedBox(height: 15),

                  // Rincian Pesanan
                  const Text(
                    'RINCIAN PESANAN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          itemName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${qty}x',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[300] : Colors.black87),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          pricePerItem,
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const DashedLineSeparator(),
                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL PEMBAYARAN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        totalPayment,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STATUS PESANAN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Download Button
            SizedBox(
              width: double.infinity,
              height: 55,
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
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                label: const Text(
                  'Unduh Struk Resmi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
            ),
          ),
          const Text(':', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
