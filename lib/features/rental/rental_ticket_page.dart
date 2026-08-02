import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class RentalTicketPage extends StatelessWidget {
  final String itemName;
  final String renterName;
  final String eventType;
  final bool needsLogistics;
  final int totalPrice;
  final int durationDays;

  const RentalTicketPage({
    super.key,
    required this.itemName,
    required this.renterName,
    required this.eventType,
    required this.needsLogistics,
    required this.totalPrice,
    required this.durationDays,
  });

  void _simulateWhatsApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Membuka WhatsApp: Halo Pengurus, saya ingin konfirmasi Bukti Transaksi...',
        ),
        backgroundColor: Colors.blue[800],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Generate some mock data for the receipt
    final String currentDate = DateFormat('dd MMMM yyyy').format(DateTime.now());
    final String refNumber = 'RES/${DateTime.now().year}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Unduh Bukti Transaksi', style: TextStyle(color: Colors.black87, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Membagikan PDF Bukti Transaksi...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
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
              padding: const EdgeInsets.only(left: 24, right: 24, top: 120, bottom: 40),
              child: Container(
                color: Colors.white.withAlpha(220), // Slight white overlay for text readability if needed
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Surat
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Text(
                            'Bukti Transaksi Pemesanan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Nomor Ref: $refNumber',
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

                    // Section I
                    const Text(
                      'I. Identitas & Detail Pesanan',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 12),
                    _buildTableRow('Nama Pemesan', renterName),
                    _buildTableRow('Tanggal Transaksi', '$currentDate WIB'),
                    _buildTableRow('Barang / Layanan', itemName),
                    _buildTableRow('Tipe Acara', eventType),
                    _buildTableRow('Lama Sewa', '$durationDays Hari'),
                    _buildTableRow('Total Pembayaran', totalPrice == 0 ? 'GRATIS' : 'Rp ${NumberFormat('#,###', 'id_ID').format(totalPrice)}'),
                    
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 130,
                          child: Text('Status Terkini', style: TextStyle(fontSize: 13, color: Colors.black87)),
                        ),
                        const Text(':', style: TextStyle(fontSize: 13, color: Colors.black87)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Berhasil / Lunas',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Section II
                    const Text(
                      'II. Instruksi & Catatan Tambahan',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.white,
                      ),
                      child: Text(
                        needsLogistics
                            ? 'Pesanan ini membutuhkan logistik tambahan (Kursi/Speaker) dari gudang. Harap hubungi pengurus pada hari H untuk serah terima kunci dan perlengkapan.'
                            : 'Pesanan telah dicatat. Harap hubungi pengurus pada hari H untuk serah terima kunci/barang.',
                        style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Tanda Tangan Elektronik
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('Bengkalis, $currentDate', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                          const SizedBox(height: 4),
                          const Text('Sistem SilaDesBeng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const Text('Admin BUMDes', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          const SizedBox(height: 12),
                          // QR Code
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              QrImageView(
                                data: 'https://siladesbeng.id/validasi/transaksi/$refNumber',
                                version: QrVersions.auto,
                                size: 100.0,
                              ),
                              Container(
                                color: Colors.white,
                                padding: const EdgeInsets.all(2),
                                child: const Icon(Icons.verified, color: Colors.blue, size: 20),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Tanda Tangan Elektronik', style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Disclaimer
                    const Divider(thickness: 1, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Dokumen ini dicetak otomatis oleh Sistem SilaDesBeng dan sah tanpa tanda tangan basah.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Hubungi Pengurus Button (not part of PDF, just app action)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _simulateWhatsApp(context),
                        icon: const Icon(Icons.wechat, size: 24),
                        label: const Text('Hubungi Pengurus BUMDes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildTableRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
          const Text(':', style: TextStyle(fontSize: 13, color: Colors.black87)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
