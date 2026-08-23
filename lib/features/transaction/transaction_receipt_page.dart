import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'delivery_tracking_page.dart';

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
    final valueColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F8FF);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Unduh Bukti Transaksi',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: 'Bagikan Bukti',
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
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Unduh PDF',
            onPressed: () => _generateAndDownloadPdf(context),
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
                    opacity: 0.04,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
                                height: 46,
                                width: 46,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.business, size: 46, color: Color(0xFF2563EB)),
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2563EB),
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
                          
                          const SizedBox(height: 18),
                          Divider(thickness: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 14),

                          // ===== INFO PESANAN =====
                          _buildTableRow('No. Pesanan', orderNumber, labelColor, valueColor),
                          _buildTableRow('Waktu Pemesanan', orderTime, labelColor, valueColor),
                          _buildTableRow('Nama Akun Pemesan', accountName, labelColor, valueColor),
                          _buildTableRow('Email Akun Pemesan', accountEmail, labelColor, valueColor),
                          
                          const SizedBox(height: 10),
                          Divider(thickness: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 10),

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
                          
                          const SizedBox(height: 10),
                          Divider(thickness: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 10),

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

                          const SizedBox(height: 10),
                          Divider(thickness: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 10),

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
                          Divider(thickness: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(flex: 4, child: Text(itemName, style: TextStyle(fontSize: 11, color: valueColor))),
                              Expanded(flex: 1, child: Text('$qty', style: TextStyle(fontSize: 11, color: valueColor))),
                              Expanded(flex: 3, child: Text(pricePerItem, style: TextStyle(fontSize: 11, color: valueColor), overflow: TextOverflow.ellipsis, maxLines: 1)),
                              Expanded(flex: 3, child: Text(totalPayment, style: TextStyle(fontSize: 11, color: valueColor), overflow: TextOverflow.ellipsis, maxLines: 1)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(thickness: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total Pemesanan', style: TextStyle(fontSize: 12, color: labelColor)),
                                    Text(totalPayment, style: TextStyle(fontSize: 12, color: valueColor)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total Dibayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: valueColor)),
                                    Text(totalPayment, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: valueColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),
                          
                          // ===== QR CODE dengan Logo SiladesBeng =====
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
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
                                  size: Size(30, 30),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // ===== BRANDING SiladesBeng di bawah QR =====
                          Center(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'logodomain.png',
                                      width: 16,
                                      height: 16,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => const Icon(Icons.shield, size: 16, color: Color(0xFF2563EB)),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'SiladesBeng',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: valueColor,
                                      ),
                                    ),
                                  ],
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
                          
                          const SizedBox(height: 16),
                          Divider(thickness: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
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

                    const SizedBox(height: 16),

                    // Tombol Unduh PDF Bukti Transaksi
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => _generateAndDownloadPdf(context),
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                        label: const Text(
                          'Unduh PDF Bukti Transaksi',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),

                    // Lacak Pengiriman Button (hanya muncul jika Diantar, Sewa Mobil, atau Ambulans)
                    if (deliveryMethod.toLowerCase().contains('diantar') || type == 'Sewa Mobil' || type == 'Ambulans')
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DeliveryTrackingPage(
                                    orderNumber: orderNumber,
                                    type: type,
                                    deliveryAddress: address,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.local_shipping_outlined, size: 20),
                            label: Text(
                              type == 'Ambulans' ? 'Lacak Posisi Ambulans' : 'Lacak Pengantaran',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[800],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),
                  ],
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

  Future<void> _generateAndDownloadPdf(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sedang membuat dokumen PDF...'),
        backgroundColor: Color(0xFF0EA5E9),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final pdf = pw.Document();

      // Load logo for header
      final logoData = await rootBundle.load('logodomain.png');
      final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header SilaDesBeng
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Image(logoImage, width: 50, height: 50),
                    pw.SizedBox(width: 10),
                    pw.Text('SilaDesBeng',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Spacer(),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Bukti Transaksi',
                            style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue800)),
                        pw.Text(_receiptSubtitle,
                            style: pw.TextStyle(
                                fontSize: 11, color: PdfColors.grey700)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 16),

                // Transaction Info
                _buildPdfRow('No. Pesanan', orderNumber),
                _buildPdfRow('Waktu Pemesanan', orderTime),
                _buildPdfRow('Nama Akun', accountName),
                _buildPdfRow('Email Akun', accountEmail),
                if (type == 'Sewa' || type == 'Ambulans')
                  _buildPdfRow('Nama Pemohon', recipientName),
                if (type == 'Sewa')
                  _buildPdfRow('Tujuan / Kegiatan', rentalPurpose ?? '-'),
                if (type == 'Ambulans' || type == 'Pasar')
                  _buildPdfRow(
                      type == 'Ambulans'
                          ? 'Alamat Penjemputan'
                          : 'Alamat Pengiriman',
                      address),
                if (type == 'Pasar')
                  _buildPdfRow('Metode Pengiriman', deliveryMethod),

                pw.SizedBox(height: 16),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 16),

                // Payment Info
                pw.Text('INFORMASI PEMBAYARAN',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: PdfColors.grey600)),
                pw.SizedBox(height: 10),
                _buildPdfRow('Waktu Pembayaran', paymentTime),
                _buildPdfRow('Metode Pembayaran', paymentMethod),
                _buildPdfRow('Total Pembayaran', totalPayment, isBold: true),
                _buildPdfRow('Status', status),

                pw.SizedBox(height: 16),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 16),

                // Item Details
                pw.Text('RINCIAN PESANAN',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: PdfColors.grey600)),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(itemName,
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.SizedBox(height: 8),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Tagihan',
                              style: pw.TextStyle(color: PdfColors.grey700)),
                          pw.Text(totalPayment,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Center(
                  child: pw.Text(
                    'Dokumen ini merupakan bukti transaksi yang sah dan diterbitkan oleh sistem SilaDesBeng.\nDicetak secara otomatis dari Aplikasi Mobile SilaDesBeng.',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Bukti_Transaksi_$orderNumber.pdf');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Bukti Transaksi SilaDesBeng: $orderNumber',
            subject: 'Bukti Transaksi - SilaDesBeng',
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  pw.Widget _buildPdfRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(label,
                style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          ),
          pw.Text(':',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
}
