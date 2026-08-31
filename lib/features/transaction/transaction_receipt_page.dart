import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'delivery_tracking_page.dart';

class TransactionReceiptPage extends StatefulWidget {
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
  final String type; // 'Sewa Alat', 'Sewa Mobil', 'Gas', 'Fasilitas', 'Pasar'

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
  State<TransactionReceiptPage> createState() => _TransactionReceiptPageState();
}

class _TransactionReceiptPageState extends State<TransactionReceiptPage> {
  final GlobalKey _receiptCardKey = GlobalKey();
  bool _isGeneratingImage = false;

  /// Maps the type to a receipt subtitle like the web template
  String get _receiptSubtitle {
    final t = widget.type.toLowerCase();
    if (t.contains('pasar')) {
      return 'Pasar Daerah';
    } else if (t.contains('gas')) {
      return 'Unit Pembelian Gas';
    } else if (t.contains('alat') || t.contains('sewa alat')) {
      return 'Unit Penyewaan Alat';
    } else if (t.contains('mobil') || t.contains('kendaraan')) {
      return 'Unit Penyewaan Mobil';
    } else if (t.contains('fasilitas') || t.contains('gedung')) {
      return 'Unit Fasilitas Umum';
    } else if (t.contains('ambulans')) {
      return 'Layanan Ambulans';
    }
    return widget.type;
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
            SizedBox(width: 12.w),
            Text('Sedang membuat gambar Bukti Transaksi (PNG)...'),
          ],
        ),
        backgroundColor: Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // Small delay to ensure rendering is complete
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
    final bgColor = isDark ? const Color(0xFF090D16) : const Color(0xFFF1F8FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(isDark ? 25 : 35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 16.sp,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Bukti Transaksi',
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3),
        ),
        centerTitle: true,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: 'Bagikan Bukti',
            onPressed: () {
              final text = 'Bukti Transaksi ${widget.type} - SilaDesBeng\n\n'
                  'No. Pesanan: ${widget.orderNumber}\n'
                  'Waktu: ${widget.orderTime}\n'
                  'Total: ${widget.totalPayment}\n\n'
                  'SiladesBeng - Platform E-Government Kab. Bengkalis';
              SharePlus.instance.share(ShareParams(text: text));
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Unduh Gambar PNG',
            onPressed: () => _generateAndDownloadPng(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== RECEIPT CARD CAPTURED AS PNG (REPAINT BOUNDARY) =====
              RepaintBoundary(
                key: _receiptCardKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // Always pure white paper for export
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 40 : 12),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Stack(
                      children: [
                        // Watermark Logo SiladesBeng di tengah halaman
                        Positioned.fill(
                          child: Center(
                            child: Opacity(
                              opacity: 0.07,
                              child: Image.asset(
                                'logodomain.png',
                                width: 260,
                                height: 260,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const SizedBox(),
                              ),
                            ),
                          ),
                        ),

                        // Content
                        Padding(
                          padding: EdgeInsets.all(22.0.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ===== 1. HEADER (SilaDesBeng & Bukti Transaksi) =====
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'logodomain.png',
                                    height: 44,
                                    width: 44,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(Icons.business_rounded, size: 44.sp, color: Color(0xFF2563EB)),
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    'SiladesBeng',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const Spacer(),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Bukti Transaksi',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        _receiptSubtitle,
                                        style: TextStyle(
                                          fontSize: 11.5.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              SizedBox(height: 14.h),
                              const Divider(thickness: 1.2, color: Color(0xFF0F172A)),
                              SizedBox(height: 10.h),

                              // ===== 2. INFORMASI PESANAN =====
                              _buildReceiptRow('No. Pesanan', widget.orderNumber, isBold: true),
                              _buildReceiptRow('Waktu Pemesanan', widget.orderTime),
                              _buildReceiptRow('Nama Akun Pemesan', widget.accountName),
                              _buildReceiptRow('NIK', '-'),

                              SizedBox(height: 8.h),
                              const Divider(thickness: 1, color: Color(0xFFE2E8F0)),
                              SizedBox(height: 8.h),

                              // ===== 3. INFORMASI PENGIRIMAN =====
                              Text(
                                'Informasi Pengiriman',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.sp,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              _buildReceiptRow('Nama Penerima', widget.recipientName.isNotEmpty ? widget.recipientName : widget.accountName),
                              _buildReceiptRow('No. Handphone', '-'),
                              _buildReceiptRow('Alamat', widget.address.isNotEmpty ? widget.address : '-'),
                              _buildReceiptRow('Metode Pengiriman', widget.deliveryMethod.isNotEmpty ? widget.deliveryMethod : '-'),
                              if (widget.rentalPurpose != null && widget.rentalPurpose!.isNotEmpty)
                                _buildReceiptRow('Tujuan / Kegiatan', widget.rentalPurpose!),

                              SizedBox(height: 8.h),
                              const Divider(thickness: 1, color: Color(0xFFE2E8F0)),
                              SizedBox(height: 8.h),

                              // ===== 4. INFORMASI PEMBAYARAN =====
                              Text(
                                'Informasi Pembayaran',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.sp,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              _buildReceiptRow(
                                'Metode Pembayaran',
                                widget.paymentMethod.toUpperCase().replaceAll('_', ' '),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 8.h),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 140,
                                      child: Text(
                                        'Status Pesanan',
                                        style: TextStyle(fontSize: 12.5.sp, color: Color(0xFF0F172A)),
                                      ),
                                    ),
                                    Text(':', style: TextStyle(fontSize: 12.5.sp, color: Color(0xFF0F172A))),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Text(
                                        ': ${widget.status.toUpperCase()}',
                                        style: TextStyle(
                                          fontSize: 12.5.sp,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF10B981), // Green confirmed badge
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 8.h),
                              const Divider(thickness: 1, color: Color(0xFFE2E8F0)),
                              SizedBox(height: 8.h),

                              // ===== 5. DETAIL PESANAN (TABEL) =====
                              Text(
                                'Detail Pesanan',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.sp,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 10.h),

                              // Table Header
                              Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      'Nama Produk',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5.sp, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Jumlah',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5.sp, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Harga Satuan',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5.sp, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      'Total',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5.sp, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              const Divider(thickness: 1, color: Color(0xFF0F172A)),
                              SizedBox(height: 6.h),

                              // Table Row Item
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      widget.itemName,
                                      style: TextStyle(fontSize: 11.5.sp, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${widget.qty}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 11.5.sp, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      widget.pricePerItem,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(fontSize: 11.5.sp, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      widget.totalPayment,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 11.5.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 10.h),
                              const Divider(thickness: 1, color: Color(0xFF0F172A)),
                              SizedBox(height: 8.h),

                              // Subtotal Box
                              Padding(
                                padding: EdgeInsets.only(left: 80.w),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Total Harga Produk', style: TextStyle(fontSize: 12.sp, color: Color(0xFF475569))),
                                        Text(widget.totalPayment, style: TextStyle(fontSize: 12.sp, color: Color(0xFF0F172A))),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Ongkos Kirim', style: TextStyle(fontSize: 12.sp, color: Color(0xFF475569))),
                                        Text('Rp. 0', style: TextStyle(fontSize: 12.sp, color: Color(0xFF0F172A))),
                                      ],
                                    ),
                                    SizedBox(height: 6.h),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total Pembayaran',
                                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.sp, color: Color(0xFF0F172A)),
                                        ),
                                        Text(
                                          widget.totalPayment,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14.sp,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 24.h),

                              // ===== 6. SIGNATURE & QR CODE SECTION =====
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bengkalis, ${widget.orderTime.split(' ').take(3).join(' ')}',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        'Hormat Kami',
                                        style: TextStyle(fontSize: 11.sp, color: Color(0xFF475569)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              SizedBox(height: 10.h),

                              // Centered QR Code
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12.r),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: QrImageView(
                                        data: widget.orderNumber,
                                        version: QrVersions.auto,
                                        size: 110.0.sp,
                                        backgroundColor: Colors.white,
                                        embeddedImage: const AssetImage('logodomain.png'),
                                        embeddedImageStyle: const QrEmbeddedImageStyle(
                                          size: Size(26, 26),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'SiladesBeng',
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      'Platform E-Government Kab. Bengkalis',
                                      style: TextStyle(
                                        fontSize: 10.5.sp,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 16.h),
                              const Divider(thickness: 1.2, color: Color(0xFF0F172A)),
                              SizedBox(height: 6.h),

                              // Footer tagline
                              Center(
                                child: Text(
                                  'SiladesBeng - Sistem Sinergi Layanan dan Aspirasi Desa di Kabupaten Bengkalis',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 9.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 18.h),

              // ===== TOMBOL UNDUH GAMBAR PNG BUKTI TRANSAKSI =====
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingImage ? null : () => _generateAndDownloadPng(),
                  icon: _isGeneratingImage
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(Icons.image_outlined, size: 20.sp),
                  label: Text(
                    _isGeneratingImage ? 'Menyiapkan Gambar...' : 'Unduh Bukti Transaksi (PNG)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5.sp),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 2,
                    shadowColor: const Color(0xFF2563EB).withAlpha(100),
                  ),
                ),
              ),

              // Lacak Pengiriman Button (hanya muncul jika Diantar, Sewa Mobil, atau Ambulans)
              if (widget.deliveryMethod.toLowerCase().contains('diantar') ||
                  widget.type == 'Sewa Mobil' ||
                  widget.type == 'Ambulans')
                Padding(
                  padding: EdgeInsets.only(top: 12.h),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeliveryTrackingPage(
                              orderNumber: widget.orderNumber,
                              type: widget.type,
                              deliveryAddress: widget.address,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.local_shipping_outlined, size: 20.sp),
                      label: Text(
                        widget.type == 'Ambulans' ? 'Lacak Posisi Ambulans' : 'Lacak Pengantaran',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5.sp),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5.sp, color: Color(0xFF0F172A)),
            ),
          ),
          Text(':', style: TextStyle(fontSize: 12.5.sp, color: Color(0xFF0F172A))),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
