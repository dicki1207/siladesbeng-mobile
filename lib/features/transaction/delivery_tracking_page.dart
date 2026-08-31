import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DeliveryTrackingPage extends StatefulWidget {
  final String orderNumber;
  final String type;
  final String deliveryAddress;

  const DeliveryTrackingPage({
    super.key,
    required this.orderNumber,
    required this.type,
    required this.deliveryAddress,
  });

  @override
  State<DeliveryTrackingPage> createState() => _DeliveryTrackingPageState();
}

class _DeliveryTrackingPageState extends State<DeliveryTrackingPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Lacak Pengantaran',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'Bantuan',
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ===== STATUS HEADER =====
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16.r),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimasi tiba 09:23 - 09:33',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: labelColor,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.type == 'Ambulans'
                                ? 'Ambulans sedang menuju ke lokasimu'
                                : 'Supir sedang mengantar pesananmu',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              height: 1.2,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.type == 'Ambulans'
                                ? Icons.emergency
                                : Icons.local_shipping,
                            size: 40.sp,
                            color: widget.type == 'Ambulans'
                                ? Colors.red
                                : const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    // STEPPER BAR
                    Row(
                      children: [
                        _buildStepIndicator(isCompleted: true, isActive: false),
                        _buildStepLine(isCompleted: true),
                        _buildStepIndicator(isCompleted: true, isActive: true),
                        _buildStepLine(isCompleted: false),
                        _buildStepIndicator(isCompleted: false, isActive: false),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'Kami akan memberitahu kamu saat pesanan hampir tiba',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: labelColor,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    SizedBox(height: 12.h),
                    // DRIVER PROFILE
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white, size: 26.sp),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FERDI KURNIAWAN (Supir)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5.sp,
                                  color: textColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 3.h),
                              Row(
                                children: [
                                  Icon(Icons.star_rounded, color: Colors.amber, size: 15.sp),
                                  SizedBox(width: 3.w),
                                  Text(
                                    '4.9',
                                    style: TextStyle(fontSize: 12.sp, color: labelColor),
                                  ),
                                  SizedBox(width: 6.w),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: labelColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Flexible(
                                    child: Text(
                                      'BM 6262 BP',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.sp,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Action buttons
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.withAlpha(50)),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            icon: Icon(Icons.call_outlined, size: 18.sp),
                            color: textColor,
                            onPressed: () {},
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.withAlpha(50)),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                            icon: Icon(Icons.chat_bubble_outline, size: 18.sp),
                            color: textColor,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              // ===== DETAIL LOKASI =====
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16.r),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red[600],
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Diambil dari',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: labelColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.only(left: 22.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unit Pelayanan BUMDes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Jl. Utama Desa, Kantor BUMDes',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: labelColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Padding(
                      padding: EdgeInsets.only(left: 4.w),
                      child: Row(
                        children: [
                          Icon(
                            Icons.more_vert,
                            color: Colors.grey[400],
                            size: 18.sp,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Diantar ke',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: labelColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.only(left: 22.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lokasi Tujuan Anda',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            widget.deliveryAddress,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: labelColor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator({required bool isCompleted, required bool isActive}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isActive || isCompleted ? Colors.orange[800] : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          isCompleted ? Icons.check : (isActive ? Icons.local_shipping : Icons.home),
          size: 14.sp,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStepLine({required bool isCompleted}) {
    return Expanded(
      child: Container(
        height: 4,
        color: isCompleted ? Colors.orange[800] : Colors.grey[300],
      ),
    );
  }
}
