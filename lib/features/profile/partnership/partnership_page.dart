import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:siladesbeng_mobile/features/profile/partnership/partnership_registration_page.dart';

class PartnershipPage extends StatelessWidget {
  const PartnershipPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const Color primaryBlue = Color(0xFF2FA2F1);
    const Color darkBlue = Color(0xFF0284C7);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Gabung Kemitraan Desa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16.5.sp,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [primaryBlue, darkBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroCard(context, isDark),
            SizedBox(height: 24.h),

            // Section Title: 3 Langkah Mudah
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  '3 Langkah Mudah Bergabung',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            _buildCompactSteps(context, isDark),
            SizedBox(height: 26.h),

            // Section Title: Keuntungan
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Keuntungan Kemitraan Desa',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            _buildBenefitGrid(context, isDark),
            SizedBox(height: 32.h),

            _buildRegisterButton(context),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 6),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFF2FA2F1).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.stars_rounded,
              color: const Color(0xFF2FA2F1),
              size: 26.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transformasi Digital Terpadu',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  'Integrasikan layanan desa, administrasi kependudukan, dan manajemen warga secara mandiri.',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSteps(BuildContext context, bool isDark) {
    final steps = [
      {
        'num': '1',
        'title': 'Daftar',
        'sub': 'Isi data desa & SK legalitas',
        'icon': Icons.edit_document,
        'color': const Color(0xFF2FA2F1),
      },
      {
        'num': '2',
        'title': 'Verifikasi',
        'sub': 'Validasi Admin Kabupaten',
        'icon': Icons.verified_user_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'num': '3',
        'title': 'Aktif',
        'sub': 'Kelola RT/RW & layanan',
        'icon': Icons.rocket_launch_rounded,
        'color': const Color(0xFF10B981),
      },
    ];

    return Row(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        final isLast = i == steps.length - 1;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: isLast ? 0 : 8.w),
            padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 20 : 4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: (step['color'] as Color).withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step['icon'] as IconData,
                    size: 20.sp,
                    color: step['color'] as Color,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  step['title'] as String,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 3.h),
                Text(
                  step['sub'] as String,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBenefitGrid(BuildContext context, bool isDark) {
    final benefits = [
      {
        'title': 'Layanan BUMDes',
        'desc': 'Sewa alat, mobil, gas, dan pasar daerah.',
        'icon': Icons.domain_rounded,
        'color': const Color(0xFF0EA5E9),
      },
      {
        'title': 'Manajemen RT/RW',
        'desc': 'Struktur kependudukan mandiri & rapi.',
        'icon': Icons.account_tree_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Laporan Real-Time',
        'desc': 'Rekapitulasi otomatis dalam dasbor desa.',
        'icon': Icons.query_stats_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Pendampingan Resmi',
        'desc': 'Pelatihan operasional gratis dari kabupaten.',
        'icon': Icons.support_agent_rounded,
        'color': const Color(0xFFF59E0B),
      },
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildBenefitCard(benefits[0], isDark)),
            SizedBox(width: 10.w),
            Expanded(child: _buildBenefitCard(benefits[1], isDark)),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(child: _buildBenefitCard(benefits[2], isDark)),
            SizedBox(width: 10.w),
            Expanded(child: _buildBenefitCard(benefits[3], isDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildBenefitCard(Map<String, dynamic> item, bool isDark) {
    final color = item['color'] as Color;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(item['icon'] as IconData, size: 20.sp, color: color),
          ),
          SizedBox(height: 10.h),
          Text(
            item['title'] as String,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13.sp,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 3.h),
          Text(
            item['desc'] as String,
            style: TextStyle(
              fontSize: 11.sp,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2FA2F1), Color(0xFF0284C7)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2FA2F1).withAlpha(80),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PartnershipRegistrationPage(),
              ),
            );
          },
          icon: Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 22.sp),
          label: Text(
            'Daftarkan Desa Sekarang',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.r),
            ),
          ),
        ),
      ),
    );
  }
}
