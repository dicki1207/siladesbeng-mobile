import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const Color _primaryBlue = Color(0xFF2FA2F1);
  static const Color _darkBlue = Color(0xFF0284C7);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          title: Text(
            'Tentang SiladesBeng',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryBlue, _darkBlue],
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
                        color: Colors.white.withAlpha(25),
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
                        color: Colors.white.withAlpha(15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
        children: [
          // 1. Profil / Brand Card
          _buildBrandCard(isDark),
          SizedBox(height: 20.h),

          // 2. Cerita Kami (Visi Singkat)
          _buildCeritaCard(isDark),
          SizedBox(height: 24.h),

          // 3. Nilai-Nilai Kami (5 Nilai Sesuai Web)
          _buildSectionTitle(
            'Nilai Kami',
            'Prinsip utama pelayanan terpadu SiladesBeng',
            Icons.verified_rounded,
            isDark,
          ),
          SizedBox(height: 12.h),
          _buildNilaiKami(isDark),
          SizedBox(height: 24.h),

          // 4. Misi SiladesBeng (4 Poin)
          _buildSectionTitle(
            'Misi Kami',
            'Komitmen pembangunan ekonomi dan layanan desa',
            Icons.flag_rounded,
            isDark,
          ),
          SizedBox(height: 12.h),
          _buildMisiCard(isDark),
          SizedBox(height: 24.h),

          // 5. Penyelenggara & Dukungan Resmi
          _buildSectionTitle(
            'Dukungan & Legalitas',
            'Pemerintah Daerah & Pengelola BUMDes',
            Icons.account_balance_rounded,
            isDark,
          ),
          SizedBox(height: 12.h),
          _buildOfficialInstitutionCard(isDark),
          SizedBox(height: 28.h),

          // 6. Footer & Kontak
          _buildFooterCard(isDark),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildBrandCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
            ),
            child: Image.asset(
              'logodomain.png',
              width: 54,
              height: 54,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'SiladesBeng',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
              color: _primaryBlue,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: _primaryBlue.withAlpha(15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'Sistem Sinergi Layanan & Aspirasi Desa',
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                color: _primaryBlue,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Kabupaten Bengkalis, Riau',
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCeritaCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 20 : 4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: _primaryBlue.withAlpha(20),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.auto_stories_rounded, size: 18.sp, color: _primaryBlue),
              ),
              SizedBox(width: 10.w),
              Text(
                'Cerita Kami',
                style: TextStyle(
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'SiladesBeng bermula dari visi besar untuk mempercepat digitalisasi pelayanan publik di Kabupaten Bengkalis. Platform ini hadir menghubungkan seluruh jaringan desa ke dalam satu ekosistem digital yang terpadu, transparan, dan mudah diakses oleh seluruh warga.',
            style: TextStyle(
              fontSize: 12.5.sp,
              height: 1.5,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle, IconData icon, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: _primaryBlue.withAlpha(20),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 18.sp, color: _primaryBlue),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5.sp,
                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNilaiKami(bool isDark) {
    final items = [
      {'title': 'Inovatif', 'desc': 'Selalu berinovasi menghadirkan solusi terbaik sesuai kebutuhan daerah.'},
      {'title': 'Efisien', 'desc': 'Mengoptimalkan proses manual menjadi digital demi efisiensi waktu dan sumber daya.'},
      {'title': 'Terpercaya', 'desc': 'Menjaga integritas data publik dengan sistem keamanan yang terpercaya.'},
      {'title': 'Kemudahan', 'desc': 'Menyediakan antarmuka yang intuitif dan mudah digunakan seluruh warga.'},
      {'title': 'Aksesibilitas', 'desc': 'Dapat diakses kapan saja dan di mana saja melalui perangkat seluler.'},
    ];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isLast = idx == items.length - 1;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 3.h),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12.5.sp,
                        height: 1.4,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                      children: [
                        TextSpan(
                          text: '${item['title']}: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        TextSpan(text: item['desc']),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMisiCard(bool isDark) {
    final missions = [
      'Meningkatkan efisiensi dan profesionalitas pengelolaan unit usaha desa (BUMDes).',
      'Menyediakan layanan digital yang mudah diakses masyarakat dan pelaku usaha desa.',
      'Membangun kepercayaan masyarakat melalui transparansi data digital yang akuntabel.',
      'Mendorong digitalisasi desa menuju tata kelola ekonomi mandiri dan modern.',
    ];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: missions.asMap().entries.map((entry) {
          final idx = entry.key;
          final misi = entry.value;
          final isLast = idx == missions.length - 1;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 2.h),
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, size: 10.sp, color: Colors.white),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    misi,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOfficialInstitutionCard(bool isDark) {
    final institutions = [
      {
        'title': 'Pemerintah Kab. Bengkalis',
        'sub': 'Penyelenggara & Pembina Layanan Desa',
        'icon': Icons.account_balance_rounded,
        'color': const Color(0xFF2FA2F1),
      },
      {
        'title': 'BUMDes & Pemerintahan Desa',
        'sub': 'Pengelola Usaha & Layanan Warga',
        'icon': Icons.storefront_rounded,
        'color': const Color(0xFF10B981),
      },
    ];

    return Column(
      children: institutions.map((item) {
        final col = item['color'] as Color;
        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 20 : 3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: col.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'] as IconData, size: 22.sp, color: col),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5.sp,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      item['sub'] as String,
                      style: TextStyle(
                        fontSize: 11.5.sp,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: col.withAlpha(15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Resmi',
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.bold,
                    color: col,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooterCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? Colors.white10 : Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 15.sp, color: _primaryBlue),
              SizedBox(width: 8.w),
              Text(
                'Bengkalis, Riau, Indonesia',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Color(0xFF334155),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Icon(Icons.email_rounded, size: 15.sp, color: _primaryBlue),
              SizedBox(width: 8.w),
              Text(
                'siladesbengdigital@gmail.com',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.grey.withAlpha(50),
          ),
          SizedBox(height: 10.h),
          Text(
            '© 2026 SiladesBeng • Sistem Sinergi Layanan & Aspirasi Desa',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5.sp,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
