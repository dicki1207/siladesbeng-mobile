import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:siladesbeng_mobile/widgets/custom_cached_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:siladesbeng_mobile/widgets/ticket_card.dart';

class GasReceiptPage extends StatefulWidget {
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

  @override
  State<GasReceiptPage> createState() => _GasReceiptPageState();
}

class _GasReceiptPageState extends State<GasReceiptPage> {
  final GlobalKey _receiptCardKey = GlobalKey();
  bool _isGeneratingImage = false;

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}';
  }

  Future<void> _generateAndDownloadPng() async {
    if (_isGeneratingImage) return;

    setState(() => _isGeneratingImage = true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            const Text('Sedang membuat gambar Bukti Transaksi (PNG)...'),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final boundary = _receiptCardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Gagal menemukan tampilan struk');
      }

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Gagal mengonversi gambar ke format PNG');
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final cleanOrderNumber = widget.orderNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final file = File('${dir.path}/Bukti_Transaksi_$cleanOrderNumber.png');
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      setState(() => _isGeneratingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti Transaksi (PNG) berhasil dibuat!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Bukti Transaksi SilaDesBeng: ${widget.orderNumber}',
          subject: 'Bukti Transaksi - SilaDesBeng',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGeneratingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat gambar PNG: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Bukti Transaksi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2563EB),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
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
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            RepaintBoundary(
              key: _receiptCardKey,
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
                            CustomCachedImage(
                              'https://siladesbeng.inovasia.site/assets/img/logo.png', // Fallback
                              height: 40,
                              errorBuilder: (c, e, s) => const Icon(
                                Icons.gas_meter,
                                color: Colors.blue,
                                size: 40,
                              ),
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
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // INFO PESANAN
                    _buildInfoRow('No. Pesanan', widget.orderNumber),
                    _buildInfoRow('Waktu Pemesanan', widget.orderDate),
                    _buildInfoRow('Nama Akun Pemesan', widget.buyerName),
                    _buildInfoRow('Email Akun Pemesan', widget.email),

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
                    _buildInfoRow('Nama Lengkap', widget.buyerName),
                    _buildInfoRow('Alamat', widget.address),

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
                    _buildInfoRow('Metode Pembayaran', widget.paymentMethod),
                    _buildInfoRow('Total Pembayaran', _formatCurrency(widget.total)),
                    _buildInfoRow('Status', widget.status),

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
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Keterangan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Jumlah',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Satuan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(thickness: 1),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(widget.itemName, style: const TextStyle(fontSize: 12)),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${widget.quantity}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _formatCurrency(widget.price),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _formatCurrency(widget.total),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Pemesanan',
                                style: TextStyle(fontSize: 12),
                              ),
                              Text(
                                _formatCurrency(widget.total),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Dibayar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                              Text(
                                _formatCurrency(widget.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // QR CODE & FOOTER
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Bengkalis, ${widget.orderDate}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('Hormat Kami', style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 16),
                          QrImageView(
                            data: widget.orderNumber,
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
            const SizedBox(height: 24),
            // Tombol Unduh & Share
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isGeneratingImage ? null : _generateAndDownloadPng,
                icon: _isGeneratingImage
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.download_rounded),
                label: Text(
                  _isGeneratingImage ? 'Menyiapkan Gambar...' : 'Unduh Bukti Transaksi (PNG)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
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
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
