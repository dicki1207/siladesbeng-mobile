import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final valueColor = isDark ? Colors.white : Colors.black;
    final labelColor = isDark ? Colors.grey[400]! : Colors.grey[700]!;
    final bgColor = isDark ? Colors.grey[900]! : Colors.white;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    // Generate some mock data for the receipt
    final String currentDate = DateFormat('dd MMMM yyyy').format(DateTime.now());
    final String refNumber = 'RES/${DateTime.now().year}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Unduh Bukti Transaksi', style: TextStyle(color: textColor, fontSize: 16)),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final text = 'Bukti Transaksi Sewa $itemName - SilaDesBeng\n\n'
                  'No. Ref: $refNumber\n'
                  'Lama Sewa: $durationDays Hari\n'
                  'Total Harga: Rp $totalPrice\n\n'
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
                                'Unit Penyewaan Alat',
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
                      _buildTableRow('No. Pesanan', refNumber, labelColor, valueColor),
                      _buildTableRow('Waktu Pesan', currentDate, labelColor, valueColor),
                      _buildTableRow('Akun Pemesan', renterName, labelColor, valueColor),
                      _buildTableRow('Email Akun', '${renterName.toLowerCase().replaceAll(' ', '')}@example.com', labelColor, valueColor),
                      
                      const SizedBox(height: 12),
                      Divider(thickness: 1, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                      const SizedBox(height: 12),

                      // ===== NAMA DAN ALAMAT =====
                      Text('Nama dan Alamat Penyewa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valueColor)),
                      const SizedBox(height: 10),
                      _buildTableRow('Nama Lengkap', renterName, labelColor, valueColor),
                      _buildTableRow('Alamat', 'Jl. Pemuda No. 4, Bengkalis', labelColor, valueColor),
                      _buildTableRow('Pengiriman', needsLogistics ? 'Diantar' : 'Ambil Sendiri', labelColor, valueColor),

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
                          Expanded(flex: 4, child: Text('Sewa $itemName ($durationDays hari)', style: TextStyle(fontSize: 11, color: textColor))),
                          Expanded(flex: 1, child: Text('1', style: TextStyle(fontSize: 11, color: textColor))),
                          Expanded(flex: 3, child: Text('Rp $totalPrice', style: TextStyle(fontSize: 11, color: textColor), overflow: TextOverflow.ellipsis, maxLines: 1)),
                          Expanded(flex: 3, child: Text('Rp $totalPrice', style: TextStyle(fontSize: 11, color: textColor), overflow: TextOverflow.ellipsis, maxLines: 1)),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      Divider(thickness: 1, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                      const SizedBox(height: 12),

                      // ===== INFO PEMBAYARAN =====
                      Text('Informasi Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valueColor)),
                      const SizedBox(height: 10),
                      _buildTableRow('Waktu Bayar', currentDate, labelColor, valueColor),
                      _buildTableRow('Metode', 'TUNAI', labelColor, valueColor),
                      _buildTableRow('Total Bayar', 'Rp $totalPrice', labelColor, valueColor),
                      
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 130,
                              child: Text('Status', style: TextStyle(fontSize: 13, color: labelColor)),
                            ),
                            Text(':', style: TextStyle(fontSize: 13, color: labelColor)),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('Menunggu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange)),
                            ),
                          ],
                        ),
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
                            data: refNumber,
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
                      
                      const SizedBox(height: 24),
                      
                      // ===== HUBUNGI PENGURUS BUTTON =====
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
