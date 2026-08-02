import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:siladesbeng_mobile/widgets/ticket_card.dart';

class GasReceiptPage extends StatelessWidget {
  final String orderNumber;
  final String orderDate;
  final String buyerName;
  final String email;
  final String address;
  final String paymentMethod;
  final String status;
  final String itemName;
  final int quantity;
  final int price;
  final int total;

  const GasReceiptPage({
    super.key,
    required this.orderNumber,
    required this.orderDate,
    required this.buyerName,
    required this.email,
    required this.address,
    required this.paymentMethod,
    required this.status,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.total,
  });

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'\\B(?=(\\d{3})+(?!\\d))'), (match) => '.')}';
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
                        errorBuilder: (c, e, s) => const Icon(Icons.gas_meter, color: Colors.blue, size: 40),
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Bukti Transaksi',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Unit Pembelian Gas',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // INFO PESANAN
              _buildInfoRow('No. Pesanan', orderNumber),
              _buildInfoRow('Waktu Pemesanan', orderDate),
              _buildInfoRow('Nama Akun Pemesan', buyerName),
              _buildInfoRow('Email Akun Pemesan', email),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: DashedLineSeparator(),
              ),

              // NAMA DAN ALAMAT
              const Text(
                'Nama dan Alamat Pembeli Gas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Nama Lengkap', buyerName),
              _buildInfoRow('Alamat', address),

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
              _buildInfoRow('Waktu Pembayaran', '-'),
              _buildInfoRow('Metode Pembayaran', paymentMethod),
              _buildInfoRow('Total Pembayaran', _formatCurrency(total)),
              _buildInfoRow('Status', status),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: DashedLineSeparator(),
              ),

              // DETAIL PEMBELIAN
              const Text(
                'Detail Pembayaran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(flex: 2, child: Text('Keterangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 1, child: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 2, child: Text('Satuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 2, child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
              const Divider(thickness: 1),
              Row(
                children: [
                  Expanded(flex: 2, child: Text(itemName, style: const TextStyle(fontSize: 12))),
                  Expanded(flex: 1, child: Text('$quantity', style: const TextStyle(fontSize: 12))),
                  Expanded(flex: 2, child: Text(_formatCurrency(price), style: const TextStyle(fontSize: 12))),
                  Expanded(flex: 2, child: Text(_formatCurrency(total), style: const TextStyle(fontSize: 12))),
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
                            const Text('Total Pemesanan', style: TextStyle(fontSize: 12)),
                            Text(_formatCurrency(total), style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Dibayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text(_formatCurrency(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                      'Bengkalis, $orderDate',
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
