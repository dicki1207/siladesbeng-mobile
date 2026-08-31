import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:siladesbeng_mobile/features/transaction/transaction_receipt_page.dart';
import 'package:siladesbeng_mobile/features/report/report_receipt_page.dart';

class TransactionDetailPage extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Selesai':
        return Colors.green;
      case 'Menunggu':
        return Colors.orange;
      case 'Batal':
        return Colors.red;
      case 'Dikonfirmasi':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(
      transaction['status']?.toString() ?? '',
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Aktivitas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
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
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Status Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32.r),
                  bottomRight: Radius.circular(32.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left side (Text content)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction['title']?.toString() ?? 'Tidak ada judul',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          transaction['price']?.toString() ?? '-',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(20),
                            borderRadius: BorderRadius.circular(30.r),
                            border: Border.all(
                              color: statusColor.withAlpha(50),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                transaction['status']?.toString() ?? 'Menunggu',
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 16.w),

                  // Right side (Image)
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withAlpha(20),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border.all(
                        color: statusColor.withAlpha(30),
                        width: 1,
                      ),
                    ),
                    child: Image.network(
                      transaction['image']?.toString() ?? '',
                      height: 72,
                      width: 72,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => Icon(
                        Icons.shopping_bag,
                        size: 72.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Detail Information
            Padding(
              padding: EdgeInsets.all(24.0.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rincian Pesanan',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20.h),
                  _buildDetailRow(
                    context,
                    'Kategori',
                    transaction['category'],
                    Icons.category_outlined,
                  ),
                  _buildDetailRow(
                    context,
                    'Waktu',
                    transaction['date'],
                    Icons.access_time_outlined,
                  ),
                  if (transaction['payment'] != null &&
                      transaction['payment'] != '-')
                    _buildDetailRow(
                      context,
                      'Pembayaran',
                      transaction['payment'],
                      Icons.payment_outlined,
                    ),

                  SizedBox(height: 32.h),
                  Text(
                    'Catatan',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: Colors.white.withAlpha(10)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).primaryColor,
                          size: 24.sp,
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Text(
                            'Terima kasih telah menggunakan layanan kami. Simpan rincian aktivitas ini sebagai bukti pemesanan yang sah. Jika Anda mengalami kendala, hubungi pengelola BUMDes.',
                            style: TextStyle(
                              color: Colors.grey[400],
                              height: 1.6,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (transaction['category'] == 'Laporan Warga') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReportReceiptPage(
                                reportId:
                                    transaction['id']?.toString() ??
                                    'RPT-12345',
                                category:
                                    transaction['category'] ?? 'Laporan Warga',
                                date: transaction['date'] ?? '12 Juli 2026',
                                description:
                                    transaction['title'] ?? 'Judul Laporan',
                                status: transaction['status'] ?? 'Menunggu',
                                statusColor: statusColor,
                                rawData:
                                    transaction['raw_data']
                                        is Map<String, dynamic>
                                    ? transaction['raw_data']
                                    : null,
                              ),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionReceiptPage(
                                orderNumber:
                                    transaction['id']?.toString() ??
                                    'TRX-12345',
                                orderTime:
                                    transaction['date'] ?? '12 Juli 2026',
                                accountName: 'Andi Desa',
                                accountEmail: 'andi@example.com',
                                recipientName: 'Andi Desa',
                                address: 'Jl. Pemuda No. 4, Bengkalis',
                                deliveryMethod: 'Diantar',
                                paymentTime:
                                    transaction['date'] ?? '12 Juli 2026',
                                paymentMethod:
                                    transaction['payment'] ?? 'Transfer Bank',
                                totalPayment: transaction['price'] ?? 'Rp 0',
                                status: transaction['status'] ?? 'Selesai',
                                statusColor: statusColor,
                                itemName: transaction['title'] ?? 'Layanan',
                                qty: 1,
                                pricePerItem: transaction['price'] ?? 'Rp 0',
                                type: transaction['category'] ?? 'Layanan',
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        transaction['category'] == 'Laporan Warga'
                            ? 'Lihat Bukti Laporan'
                            : 'Unduh Struk Digital',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: Colors.white.withAlpha(10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 22.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 2.h),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13.sp),
                ),
                SizedBox(height: 6.h),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
