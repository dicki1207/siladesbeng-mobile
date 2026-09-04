import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:siladesbeng_mobile/features/transaction/transaction_receipt_page.dart';
import 'package:siladesbeng_mobile/features/report/report_receipt_page.dart';
import 'package:siladesbeng_mobile/features/store/give_review_dialog.dart';
import 'package:siladesbeng_mobile/features/store/return_refund_dialog.dart';
import 'package:siladesbeng_mobile/services/pasar_product_service.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';

class TransactionDetailPage extends StatefulWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  late Map<String, dynamic> _tx;
  bool _hasReviewed = false;

  @override
  void initState() {
    super.initState();
    _tx = Map<String, dynamic>.from(widget.transaction);
  }

  bool get _isPasarDaerah => _tx['category'] == 'Pasar Daerah';

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('selesai') || s.contains('completed')) {
      return const Color(0xFF10B981); // Emerald Green
    } else if (s.contains('batal') ||
        s.contains('cancel') ||
        s.contains('reject')) {
      return const Color(0xFFEF4444); // Red
    } else if (s.contains('dikonfirmasi') ||
        s.contains('diproses') ||
        s.contains('dikirim') ||
        s.contains('ready') ||
        s.contains('processing')) {
      return const Color(0xFF0EA5E9); // Sky Blue
    } else {
      return const Color(0xFFF59E0B); // Amber / Orange
    }
  }

  int _getPasarStepIndex(String? rawStatus) {
    final s = (rawStatus ?? _tx['status'] ?? '').toString().toLowerCase();
    if (s.contains('pending') || s.contains('menunggu')) return 1;
    if (s.contains('processing') || s.contains('diproses')) return 2;
    if (s.contains('ready') || s.contains('dikirim') || s.contains('dikonfirmasi')) return 3;
    if (s.contains('selesai') || s.contains('completed')) return 4;
    if (s.contains('batal') || s.contains('cancelled') || s.contains('rejected')) return -1;
    return 1;
  }

  Future<void> _executeConfirmReceived(
    BuildContext sheetCtx,
    String? localPhotoPath,
    void Function(void Function()) setSheetState,
  ) async {
    final orderId = _tx['id'];
    if (orderId == null) return;

    setSheetState(() {});

    final result = await PasarProductService().confirmReceived(
      orderId: orderId is int ? orderId : int.tryParse(orderId.toString()) ?? 0,
      proofImagePath: localPhotoPath,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      if (sheetCtx.mounted) {
        Navigator.pop(sheetCtx);
      }

      setState(() {
        _tx['status'] = 'Selesai';
        if (_tx['raw_data'] is Map) {
          _tx['raw_data']['status'] = 'completed';
          _tx['raw_data']['mapped_status'] = 'Selesai';
          if (result['data'] != null && result['data']['delivery_proof_image'] != null) {
            _tx['raw_data']['delivery_proof_image'] = result['data']['delivery_proof_image'];
          }
        }
      });

      showDialog(
        context: context,
        builder: (dCtx) => const AnimatedSuccessDialog(
          message: 'Pesanan Diterima!',
          subMessage: 'Terima kasih telah berbelanja di Pasar Daerah BUMDes. Yuk beri ulasan!',
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal mengonfirmasi pesanan.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showConfirmReceivedSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? localPhotoPath;
    bool isAgreed = false;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickPhoto(ImageSource source) async {
              try {
                final picker = ImagePicker();
                final picked = await picker.pickImage(
                  source: source,
                  imageQuality: 80,
                  maxWidth: 1280,
                );
                if (picked != null) {
                  setSheetState(() {
                    localPhotoPath = picked.path;
                  });
                }
              } catch (e) {
                debugPrint('Error picking image: $e');
              }
            }

            void showPickerOptions() {
              showModalBottomSheet(
                context: context,
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                ),
                builder: (modalCtx) => SafeArea(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pilih Sumber Foto Bukti',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(modalCtx);
                                  pickPhoto(ImageSource.camera);
                                },
                                borderRadius: BorderRadius.circular(16.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.camera_alt_rounded,
                                        size: 32.sp,
                                        color: const Color(0xFF0EA5E9),
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        'Kamera Langsung',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF0EA5E9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(modalCtx);
                                  pickPhoto(ImageSource.gallery);
                                },
                                borderRadius: BorderRadius.circular(16.r),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.photo_library_rounded,
                                        size: 32.sp,
                                        color: const Color(0xFF10B981),
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        'Galeri Foto',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            Future<void> submitConfirm() async {
              if (!isAgreed) return;
              setSheetState(() => isSubmitting = true);
              await _executeConfirmReceived(ctx, localPhotoPath, setSheetState);
              if (ctx.mounted) {
                setSheetState(() => isSubmitting = false);
              }
            }

            return Container(
              padding: EdgeInsets.only(
                top: 20.h,
                left: 20.w,
                right: 20.w,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.h,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 90 : 30),
                    blurRadius: 25,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44.w,
                        height: 4.5.h,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.local_shipping_rounded,
                            color: const Color(0xFF10B981),
                            size: 22.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Konfirmasi Barang Sampai',
                                style: TextStyle(
                                  fontSize: 16.5.sp,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Pastikan produk diterima lengkap & dalam kondisi baik',
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Foto Bukti Penerimaan (Opsional)',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (localPhotoPath == null)
                      InkWell(
                        onTap: showPickerOptions,
                        borderRadius: BorderRadius.circular(16.r),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white12
                                  : const Color(0xFFCBD5E1),
                              style: BorderStyle.solid,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add_a_photo_rounded,
                                  size: 28.sp,
                                  color: const Color(0xFF0EA5E9),
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Text(
                                'Ambil Foto Barang Diterima',
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0EA5E9),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Bisa foto barang bersama kurir atau paket belanjaan',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: isDark ? Colors.white38 : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: Image.file(
                              File(localPhotoPath!),
                              width: double.infinity,
                              height: 160.h,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InkWell(
                              onTap: () {
                                setSheetState(() {
                                  localPhotoPath = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(160),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: InkWell(
                              onTap: showPickerOptions,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(160),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit, color: Colors.white, size: 14.sp),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Ganti Foto',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 18.h),
                    InkWell(
                      onTap: () {
                        setSheetState(() => isAgreed = !isAgreed);
                      },
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: isAgreed
                              ? const Color(0xFF10B981).withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isAgreed
                                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                : (isDark ? Colors.white10 : Colors.grey[300]!),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24.w,
                              height: 24.h,
                              child: Checkbox(
                                value: isAgreed,
                                activeColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.r),
                                ),
                                onChanged: (val) {
                                  setSheetState(() => isAgreed = val ?? false);
                                },
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                'Saya menyatakan telah menerima barang belanjaan ini dalam keadaan baik dan sesuai pesanan.',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  height: 1.4,
                                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                                  fontWeight: isAgreed ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 22.h),
                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        onPressed: isAgreed && !isSubmitting ? submitConfirm : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          disabledBackgroundColor: isDark
                              ? Colors.white12
                              : Colors.grey[300],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: isSubmitting
                            ? SizedBox(
                                width: 22.sp,
                                height: 22.sp,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 20.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Selesaikan Pesanan',
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openComplaintDialog() async {
    final raw = _tx['raw_data'] is Map ? _tx['raw_data'] : {};
    final items = (raw['items'] as List?) ?? [];
    final firstItem = items.isNotEmpty ? items.first : null;
    final orderNumber = raw['order_number']?.toString() ?? _tx['id']?.toString() ?? '-';
    final regionName = raw['region']?['name'] ?? 'BUMDes Desa';
    final productName = firstItem?['name'] ?? _tx['title'] ?? 'Produk Pasar Daerah';
    final productImage = firstItem?['image'] ?? _tx['image'];

    final result = await ReturnRefundDialog.show(
      context,
      orderId: _tx['id'] is int ? _tx['id'] : int.tryParse(_tx['id'].toString()),
      productName: productName,
      tokoName: 'Toko BUMDes $regionName',
      orderNumber: orderNumber,
      productPrice: raw['grand_total'] != null
          ? double.tryParse(raw['grand_total'].toString())
          : null,
      productImage: productImage,
    );

    if (result == true) {
      if (!mounted) return;
      setState(() {
        if (_tx['raw_data'] is Map) {
          _tx['raw_data']['complaint'] = {
            'reason': 'Komplain diajukan',
            'status': 'pending',
            'solution_requested': 'refund',
            'description': 'Menunggu tinjauan admin desa',
          };
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Komplain berhasil diajukan dan sedang diproses admin.'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openGiveReviewDialog() async {
    final raw = _tx['raw_data'] is Map ? _tx['raw_data'] : {};
    final items = (raw['items'] as List?) ?? [];
    final firstItem = items.isNotEmpty ? items.first : null;
    final regionName = raw['region']?['name'] ?? 'BUMDes Desa';
    final productName = firstItem?['name'] ?? _tx['title'] ?? 'Produk Pasar Daerah';
    final productId = firstItem?['product_id'] ?? firstItem?['pasar_produk_id'];
    final productImage = firstItem?['image'] ?? _tx['image'];

    final result = await GiveReviewDialog.show(
      context,
      productId: productId is int ? productId : int.tryParse(productId.toString()),
      productName: productName,
      tokoName: 'Toko BUMDes $regionName',
      productImage: productImage,
      desaName: regionName,
    );

    if (result == true) {
      if (!mounted) return;
      setState(() {
        _hasReviewed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ulasan & rating Anda berhasil dikirim. Terima kasih!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(_tx['status']?.toString() ?? '');
    final raw = _tx['raw_data'] is Map<String, dynamic> ? _tx['raw_data'] : {};

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
          _isPasarDaerah ? 'Detail Belanja Pasar' : 'Detail Aktivitas',
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildStatusHeader(isDark, statusColor, raw),
                  if (_isPasarDaerah) _buildPasarProgressStepper(isDark, raw),
                  if (raw['complaint'] != null) _buildComplaintCard(isDark, raw['complaint']),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isPasarDaerah) ...[
                          _buildPasarStoreAndDeliveryCard(isDark, raw),
                          SizedBox(height: 16.h),
                          _buildPasarItemsCard(isDark, raw),
                          SizedBox(height: 16.h),
                          if (raw['delivery_proof_image'] != null) ...[
                            _buildDeliveryProofCard(isDark, raw['delivery_proof_image']),
                            SizedBox(height: 16.h),
                          ],
                        ] else ...[
                          _buildGeneralDetails(isDark, raw),
                        ],
                        _buildCatatanCard(isDark),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildStickyBottomBar(isDark, statusColor, raw),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(bool isDark, Color statusColor, Map raw) {
    final orderNumber = raw['order_number']?.toString() ??
        (_tx['id'] != null ? '#TRX-${_tx['id']}' : '');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28.r),
          bottomRight: Radius.circular(28.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 10),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (orderNumber.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(bottom: 6.h),
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      orderNumber,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                Text(
                  _tx['title']?.toString() ?? 'Pesanan',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                Text(
                  _tx['price']?.toString() ?? '-',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0EA5E9),
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7.w,
                        height: 7.h,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 7.w),
                      Text(
                        _tx['status']?.toString() ?? 'Menunggu',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 14.w),
          Container(
            width: 72.w,
            height: 72.h,
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: statusColor.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: _tx['image'] != null && _tx['image'].toString().startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: _tx['image'],
                      fit: BoxFit.cover,
                      memCacheWidth: 500,
                      placeholder: (ctx, url) => Container(color: Colors.grey[200]),
                      errorWidget: (ctx, url, err) => const Icon(Icons.broken_image, color: Colors.grey),
                    )
                  : Image.asset(
                      _tx['image'] ?? 'assets/images/pasar.png',
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Icon(
                        Icons.shopping_bag_outlined,
                        size: 36.sp,
                        color: const Color(0xFF0EA5E9),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasarProgressStepper(bool isDark, Map raw) {
    final stepIndex = _getPasarStepIndex(raw['status']?.toString());
    final isBatal = stepIndex == -1;
    final deliveryMethod = raw['delivery_method']?.toString() ?? 'Diantar';
    final isDiantar = deliveryMethod.toLowerCase().contains('antar');

    final steps = [
      {'title': 'Dipesan', 'desc': 'Pesanan dibuat'},
      {'title': 'Dikemas', 'desc': 'Diproses BUMDes'},
      {'title': isDiantar ? 'Diantar' : 'Siap Diambil', 'desc': isDiantar ? 'Kurir jalan' : 'Ambil di Toko'},
      {'title': 'Selesai', 'desc': 'Barang diterima'},
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Pengiriman',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              if (isBatal)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'Dibatalkan',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 18.h),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final lineStep = (index ~/ 2) + 1;
                final isPassed = !isBatal && stepIndex > lineStep;
                return Expanded(
                  child: Container(
                    height: 2.5.h,
                    color: isPassed
                        ? const Color(0xFF10B981)
                        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  ),
                );
              } else {
                final nodeStep = (index ~/ 2) + 1;
                final isCurrent = !isBatal && stepIndex == nodeStep;
                final isCompleted = !isBatal && stepIndex > nodeStep;

                Color nodeColor;
                Widget nodeIcon;

                if (isBatal) {
                  nodeColor = Colors.grey[400]!;
                  nodeIcon = Text(
                    '$nodeStep',
                    style: TextStyle(color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.bold),
                  );
                } else if (isCompleted) {
                  nodeColor = const Color(0xFF10B981);
                  nodeIcon = Icon(Icons.check_rounded, color: Colors.white, size: 14.sp);
                } else if (isCurrent) {
                  nodeColor = const Color(0xFF0EA5E9);
                  nodeIcon = Text(
                    '$nodeStep',
                    style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
                  );
                } else {
                  nodeColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
                  nodeIcon = Text(
                    '$nodeStep',
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey[500],
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }

                return Column(
                  children: [
                    Container(
                      width: 26.w,
                      height: 26.h,
                      decoration: BoxDecoration(
                        color: nodeColor,
                        shape: BoxShape.circle,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: nodeIcon,
                    ),
                    SizedBox(height: 6.h),
                    SizedBox(
                      width: 65.w,
                      child: Text(
                        steps[index ~/ 2]['title']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent
                              ? const Color(0xFF0EA5E9)
                              : (isCompleted
                                  ? const Color(0xFF10B981)
                                  : (isDark ? Colors.white54 : Colors.grey[600])),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(bool isDark, Map complaint) {
    final status = complaint['status']?.toString().toLowerCase() ?? 'pending';
    final isResolved = status == 'approved' || status == 'selesai';
    final isRejected = status == 'rejected' || status == 'ditolak';

    Color bannerColor = const Color(0xFFF59E0B);
    String statusLabel = 'Komplain Sedang Ditinjau Admin';
    if (isResolved) {
      bannerColor = const Color(0xFF10B981);
      statusLabel = 'Komplain Telah Disetujui / Selesai';
    } else if (isRejected) {
      bannerColor = const Color(0xFFEF4444);
      statusLabel = 'Komplain Ditolak';
    }

    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: bannerColor, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: bannerColor,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Alasan: ${complaint['reason'] ?? 'Barang bermasalah'}',
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          if (complaint['admin_response'] != null && complaint['admin_response'].toString().isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              'Tanggapan Admin: ${complaint['admin_response']}',
              style: TextStyle(
                fontSize: 11.5.sp,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white60 : const Color(0xFF475569),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasarStoreAndDeliveryCard(bool isDark, Map raw) {
    final regionName = raw['region']?['name'] ?? 'BUMDes Desa';
    final deliveryMethod = raw['delivery_method']?.toString() ?? 'Diantar Kurir Lokal';
    final address = raw['delivery_address']?.toString() ?? 'Alamat sesuai profil';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.storefront_rounded, color: const Color(0xFF0EA5E9), size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toko BUMDes $regionName',
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Penyedia Produk Pasar Lokal Desa',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDark ? Colors.white54 : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 24.h, color: isDark ? Colors.white10 : Colors.grey[200]),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.pin_drop_rounded, color: const Color(0xFF10B981), size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deliveryMethod,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      address,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasarItemsCard(bool isDark, Map raw) {
    final items = (raw['items'] as List?) ?? [];
    final totalAmount = raw['total_amount'] ?? 0;
    final shippingCost = raw['shipping_cost'] ?? 0;
    final grandTotal = raw['grand_total'] ?? _tx['price'];

    String formatRp(dynamic val) {
      if (val == null) return 'Rp 0';
      if (val is num) {
        return 'Rp ${val.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}';
      }
      final parsed = double.tryParse(val.toString()) ?? 0;
      return 'Rp ${parsed.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}';
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Belanjaan',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                '${items.length} Barang',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0EA5E9),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (items.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(height: 18.h, color: isDark ? Colors.white10 : Colors.grey[200]),
              itemBuilder: (context, i) {
                final item = items[i];
                final name = item['name'] ?? 'Produk';
                final qty = item['quantity'] ?? 1;
                final satuan = item['satuan'] ?? 'pcs';
                final price = item['price'] ?? 0;
                final subtotal = item['subtotal'] ?? (qty * price);
                final img = item['image'];

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: Container(
                        width: 46.w,
                        height: 46.h,
                        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                        child: img != null && img.toString().startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: img,
                                fit: BoxFit.cover,
                                memCacheWidth: 500,
                                placeholder: (ctx, url) => Container(color: Colors.grey[200]),
                                errorWidget: (ctx, url, err) => const Icon(Icons.broken_image, color: Colors.grey),
                              )
                            : Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.grey[400],
                                size: 20.sp,
                              ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            '$qty $satuan × ${formatRp(price)}',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: isDark ? Colors.white54 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatRp(subtotal),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                );
              },
            )
          else
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                _tx['title']?.toString() ?? '1 Paket Belanjaan',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ),
          Divider(height: 24.h, color: isDark ? Colors.white10 : Colors.grey[200]),
          _buildCostRow('Subtotal Belanja', formatRp(totalAmount), isDark),
          SizedBox(height: 6.h),
          _buildCostRow(
            'Biaya Pengantaran',
            shippingCost == 0 || shippingCost == '0' ? 'Gratis' : formatRp(shippingCost),
            isDark,
            isGreen: shippingCost == 0 || shippingCost == '0',
          ),
          SizedBox(height: 10.h),
          Divider(height: 1.h, color: isDark ? Colors.white10 : Colors.grey[200]),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                _tx['price']?.toString() ?? formatRp(grandTotal),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0EA5E9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String title, String val, bool isDark, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12.sp,
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
          ),
        ),
        Text(
          val,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isGreen
                ? const Color(0xFF10B981)
                : (isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryProofCard(bool isDark, dynamic proofImg) {
    final imgUrl = proofImg.toString();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.camera_alt_outlined, color: const Color(0xFF10B981), size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                'Foto Bukti Barang Diterima',
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: CachedNetworkImage(
              imageUrl: imgUrl,
              width: double.infinity,
              height: 160.h,
              fit: BoxFit.cover,
              memCacheWidth: 500,
              placeholder: (ctx, url) => Container(color: Colors.grey[200]),
              errorWidget: (ctx, url, err) => const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralDetails(bool isDark, Map raw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rincian Aktivitas',
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16.h),
        _buildDetailRow(context, 'Kategori', _tx['category'] ?? '-', Icons.category_outlined),
        _buildDetailRow(context, 'Waktu Transaksi', _tx['date'] ?? '-', Icons.access_time_outlined),
        if (_tx['payment'] != null && _tx['payment'] != '-')
          _buildDetailRow(context, 'Metode Pembayaran', _tx['payment'], Icons.payment_outlined),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildCatatanCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: const Color(0xFF0EA5E9),
            size: 22.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              _isPasarDaerah
                  ? 'Belanjaan di Pasar Daerah dilindungi garansi BUMDes. Jika barang tidak sesuai, Anda dapat mengajukan komplain sebelum mengonfirmasi terima.'
                  : 'Simpan rincian aktivitas ini sebagai bukti pemesanan yang sah. Jika Anda mengalami kendala, hubungi pengelola BUMDes.',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey[600],
                height: 1.5,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(bool isDark, Color statusColor, Map raw) {
    final statusStr = (_tx['status'] ?? '').toString().toLowerCase();
    final isSelesai = statusStr.contains('selesai') || statusStr.contains('completed');
    final isBatal = statusStr.contains('batal') || statusStr.contains('cancel') || statusStr.contains('reject');
    final hasComplaint = raw['complaint'] != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, MediaQuery.of(context).padding.bottom + 14.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 20),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isPasarDaerah) ...[
            if (!isSelesai && !isBatal) ...[
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: const Color(0xFFF59E0B), size: 15.sp),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        'Periksa belanjaan Anda sebelum konfirmasi terima.',
                        style: TextStyle(
                          color: const Color(0xFFD97706),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: OutlinedButton.icon(
                      onPressed: hasComplaint ? null : _openComplaintDialog,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: BorderSide(
                          color: hasComplaint
                              ? Colors.grey[400]!
                              : const Color(0xFFEF4444).withValues(alpha: 0.6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      icon: Icon(
                        Icons.report_problem_outlined,
                        size: 16.sp,
                        color: hasComplaint ? Colors.grey : const Color(0xFFEF4444),
                      ),
                      label: Text(
                        hasComplaint ? 'Diklaim' : 'Komplain',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: hasComplaint ? Colors.grey : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 6,
                    child: ElevatedButton.icon(
                      onPressed: _showConfirmReceivedSheet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      icon: Icon(Icons.check_circle_outline_rounded, size: 18.sp),
                      label: Text(
                        'Pesanan Diterima',
                        style: TextStyle(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (isSelesai) ...[
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.celebration_outlined, color: const Color(0xFF10B981), size: 15.sp),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        'Pesanan telah tuntas. Bagaimana belanjaan Anda?',
                        style: TextStyle(
                          color: const Color(0xFF059669),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: OutlinedButton.icon(
                      onPressed: _openReceipt,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: BorderSide(
                          color: isDark ? Colors.white24 : const Color(0xFF0EA5E9),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      icon: Icon(
                        Icons.receipt_long_rounded,
                        size: 16.sp,
                        color: const Color(0xFF0EA5E9),
                      ),
                      label: Text(
                        'Unduh Struk',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0EA5E9),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 5,
                    child: ElevatedButton.icon(
                      onPressed: _hasReviewed ? null : _openGiveReviewDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        disabledBackgroundColor: isDark ? Colors.white12 : Colors.grey[300],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      icon: Icon(
                        _hasReviewed ? Icons.check_rounded : Icons.star_rounded,
                        size: 18.sp,
                      ),
                      label: Text(
                        _hasReviewed ? 'Sudah Diulas' : 'Beri Penilaian',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openReceipt,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_outlined),
                  label: const Text('Lihat Detail Pembatalan'),
                ),
              ),
            ],
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                icon: Icon(
                  _tx['category'] == 'Laporan Warga'
                      ? Icons.assignment_outlined
                      : Icons.receipt_long_rounded,
                  size: 18.sp,
                ),
                label: Text(
                  _tx['category'] == 'Laporan Warga'
                      ? 'Lihat Bukti Laporan'
                      : 'Unduh Struk Digital',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openReceipt() {
    final statusColor = _getStatusColor(_tx['status']?.toString() ?? '');
    final raw = _tx['raw_data'] is Map<String, dynamic> ? _tx['raw_data'] : null;

    if (_tx['category'] == 'Laporan Warga') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportReceiptPage(
            reportId: _tx['id']?.toString() ?? 'RPT-12345',
            category: _tx['category'] ?? 'Laporan Warga',
            date: _tx['date'] ?? '12 Juli 2026',
            description: _tx['title'] ?? 'Judul Laporan',
            status: _tx['status'] ?? 'Menunggu',
            statusColor: statusColor,
            rawData: raw,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TransactionReceiptPage(
            orderNumber: raw?['order_number'] ?? _tx['id']?.toString() ?? 'TRX-12345',
            orderTime: _tx['date'] ?? '12 Juli 2026',
            accountName: 'Warga Desa',
            accountEmail: 'warga@siladesbeng.desa.id',
            recipientName: raw?['full_name'] ?? 'Warga Desa',
            address: raw?['delivery_address'] ?? 'Desa Bengkalis',
            deliveryMethod: raw?['delivery_method'] ?? 'Diantar',
            paymentTime: _tx['date'] ?? '12 Juli 2026',
            paymentMethod: _tx['payment'] ?? 'Tunai',
            totalPayment: _tx['price'] ?? 'Rp 0',
            status: _tx['status'] ?? 'Selesai',
            statusColor: statusColor,
            itemName: _tx['title'] ?? 'Layanan',
            qty: 1,
            pricePerItem: _tx['price'] ?? 'Rp 0',
            type: _isPasarDaerah ? 'Pasar' : (_tx['category'] ?? 'Layanan'),
          ),
        ),
      );
    }
  }

  Widget _buildDetailRow(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.white.withAlpha(10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 20.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12.sp),
                ),
                SizedBox(height: 4.h),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
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
