import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                Text(
                  'Ketuk kartu',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            _buildCompactSteps(context, isDark),
            SizedBox(height: 26.h),

            // Section Title: Keuntungan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                Text(
                  'Lihat detail',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: primaryBlue,
                    fontWeight: FontWeight.w600,
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
    return AnimatedTouchCard(
      onTap: () {
        _showIntroDetailModal(context, isDark);
      },
      child: Container(
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Transformasi Digital Terpadu',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.touch_app_rounded,
                        size: 16.sp,
                        color: const Color(0xFF2FA2F1).withAlpha(150),
                      ),
                    ],
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
      ),
    );
  }

  Widget _buildCompactSteps(BuildContext context, bool isDark) {
    final steps = [
      {
        'num': '1',
        'title': 'Daftar',
        'sub': 'Isi data desa & SK legalitas',
        'detail':
            'Kepala Desa atau staf operator mengisi profil singkat desa, kontak resmi kantor, dan melampirkan file SK Pengesahan Desa/BUMDes langsung dari aplikasi tanpa proses rumit.',
        'icon': Icons.edit_document,
        'color': const Color(0xFF2FA2F1),
      },
      {
        'num': '2',
        'title': 'Verifikasi',
        'sub': 'Validasi Admin Kabupaten',
        'detail':
            'Tim Administrator Diskominfotik / DPMD Kabupaten Bengkalis memvalidasi keabsahan pendaftaran maksimal 1x24 jam kerja untuk menjamin keamanan dan keaslian data desa Anda.',
        'icon': Icons.verified_user_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'num': '3',
        'title': 'Aktif',
        'sub': 'Kelola RT/RW & layanan',
        'detail':
            'Sistem SilaDesBeng untuk desa Anda langsung aktif! Akun Kepala Desa, Sekdes, Ketua RT/RW, dan pengelola BUMDes siap melayani warga secara digital.',
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
          child: AnimatedTouchCard(
            scaleValue: 0.94,
            onTap: () {
              _showStepDetailModal(context, step, isDark);
            },
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
        'highlights': [
          'Digitalisasi unit usaha BUMDes (Gas LPG, sewa tenda/alat, rental mobil desa, dan pasar produk lokal warga).',
          'Sistem pencatatan transaksi otomatis, transparan, dan mengurangi selisih kas fisik.',
          'Membuka saluran penjualan online untuk meningkatkan Pendapatan Asli Desa (PADes).',
        ],
      },
      {
        'title': 'Manajemen RT/RW',
        'desc': 'Struktur kependudukan mandiri & rapi.',
        'icon': Icons.account_tree_rounded,
        'color': const Color(0xFF8B5CF6),
        'highlights': [
          'Akun portal khusus Ketua RT dan RW untuk persetujuan surat pengantar dan mutasi domisili warga secara online.',
          'Buku administrasi penduduk digital dengan pencarian NIK & nomor KK instan.',
          'Mempermudah penyaluran bansos atau agenda kemasyarakatan agar tepat sasaran.',
        ],
      },
      {
        'title': 'Laporan Real-Time',
        'desc': 'Rekapitulasi otomatis dalam dasbor desa.',
        'icon': Icons.query_stats_rounded,
        'color': const Color(0xFF10B981),
        'highlights': [
          'Dasbor eksekutif khusus Kepala Desa untuk memantau pendapatan BUMDes dan aktivitas warga kapan saja dari HP.',
          'Fitur pelaporan pengaduan warga dengan tracking status penanganan yang cepat dan terbuka.',
          'Rekapitulasi data siap ekspor untuk laporan pertanggungjawaban desa ke kecamatan dan kabupaten.',
        ],
      },
      {
        'title': 'Pendampingan Resmi',
        'desc': 'Pelatihan operasional gratis dari kabupaten.',
        'icon': Icons.support_agent_rounded,
        'color': const Color(0xFFF59E0B),
        'highlights': [
          'Bimbingan teknis (Bimtek) dan pelatihan operasional gratis bagi operator dan staf desa.',
          'Dukungan teknis prioritas dari tim pengembang sistem jika desa mengalami kendala.',
          'Pembaruan fitur keamanan dan sistem secara berkala tanpa biaya lisensi tambahan.',
        ],
      },
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildBenefitCard(context, benefits[0], isDark)),
            SizedBox(width: 10.w),
            Expanded(child: _buildBenefitCard(context, benefits[1], isDark)),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(child: _buildBenefitCard(context, benefits[2], isDark)),
            SizedBox(width: 10.w),
            Expanded(child: _buildBenefitCard(context, benefits[3], isDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildBenefitCard(BuildContext context, Map<String, dynamic> item, bool isDark) {
    final color = item['color'] as Color;

    return AnimatedTouchCard(
      scaleValue: 0.95,
      onTap: () {
        _showBenefitDetailModal(context, item, isDark);
      },
      child: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(item['icon'] as IconData, size: 20.sp, color: color),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12.sp,
                  color: color.withAlpha(120),
                ),
              ],
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
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return AnimatedTouchCard(
      scaleValue: 0.97,
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PartnershipRegistrationPage(),
          ),
        );
      },
      child: Container(
        width: double.infinity,
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
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 22.sp),
            SizedBox(width: 8.w),
            Text(
              'Daftarkan Desa Sekarang',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIntroDetailModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2FA2F1).withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.stars_rounded, color: const Color(0xFF2FA2F1), size: 24.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Transformasi Digital Desa',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20.sp, color: isDark ? Colors.white60 : Colors.grey[600]),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Text(
                'SilaDesBeng (Sistem Informasi Layanan Desa Terpadu Bengkalis) dirancang khusus untuk memajukan tata kelola desa di era digital.',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                  height: 1.45,
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF2FA2F1).withAlpha(12),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: const Color(0xFF2FA2F1).withAlpha(40)),
                ),
                child: Column(
                  children: [
                    _buildBulletPoint('Meningkatkan transparansi dan kepercayaan masyarakat desa.', isDark),
                    SizedBox(height: 6.h),
                    _buildBulletPoint('Memudahkan warga mengurus administrasi tanpa harus antre di kantor desa.', isDark),
                    SizedBox(height: 6.h),
                    _buildBulletPoint('Menggerakkan perekonomian desa lewat unit usaha digital BUMDes.', isDark),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PartnershipRegistrationPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2FA2F1),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Daftarkan Desa Sekarang',
                    style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildBulletPoint(String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_rounded, size: 15.sp, color: const Color(0xFF2FA2F1)),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  void _showStepDetailModal(BuildContext context, Map<String, dynamic> step, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final color = step['color'] as Color;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(step['icon'] as IconData, color: color, size: 22.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Langkah ${step['num']}: ${step['title']}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          step['sub'] as String,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20.sp, color: isDark ? Colors.white60 : Colors.grey[600]),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: color.withAlpha(15),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: color.withAlpha(40)),
                ),
                child: Text(
                  step['detail'] as String? ?? step['sub'] as String,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                    height: 1.45,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PartnershipRegistrationPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Mulai Pendaftaran Desa',
                    style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBenefitDetailModal(BuildContext context, Map<String, dynamic> item, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final color = item['color'] as Color;
        final List<String> highlights = item['highlights'] as List<String>? ?? [];

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 18.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(item['icon'] as IconData, color: color, size: 24.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          item['desc'] as String,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 20.sp, color: isDark ? Colors.white60 : Colors.grey[600]),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                'Fasilitas & Manfaat untuk Desa:',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 10.h),
              ...highlights.map((h) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16.sp, color: color),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        h,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PartnershipRegistrationPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Ajukan Kemitraan Desa Ini',
                    style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget helper untuk memberikan animasi tekan membal (bouncy scale)
/// serta umpan balik getaran taktil (haptic feedback) saat disentuh.
class AnimatedTouchCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleValue;

  const AnimatedTouchCard({
    super.key,
    required this.child,
    this.onTap,
    this.scaleValue = 0.95,
  });

  @override
  State<AnimatedTouchCard> createState() => _AnimatedTouchCardState();
}

class _AnimatedTouchCardState extends State<AnimatedTouchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleValue).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        _controller.forward();
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        _controller.reverse();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: widget.child,
        ),
      ),
    );
  }
}
