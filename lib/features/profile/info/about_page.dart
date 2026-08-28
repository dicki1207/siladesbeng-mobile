import 'package:flutter/material.dart';

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
          title: const Text(
            'Tentang SiladesBeng',
            style: TextStyle(
              fontSize: 17,
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        children: [
          // 1. Profil / Brand Card
          _buildBrandCard(isDark),
          const SizedBox(height: 20),

          // 2. Cerita Kami (Visi Singkat)
          _buildCeritaCard(isDark),
          const SizedBox(height: 24),

          // 3. Nilai-Nilai Kami (5 Nilai Sesuai Web)
          _buildSectionTitle(
            'Nilai Kami',
            'Prinsip utama pelayanan terpadu SiladesBeng',
            Icons.verified_rounded,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildNilaiKami(isDark),
          const SizedBox(height: 24),

          // 4. Misi SiladesBeng (4 Poin)
          _buildSectionTitle(
            'Misi Kami',
            'Komitmen pembangunan ekonomi dan layanan desa',
            Icons.flag_rounded,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildMisiCard(isDark),
          const SizedBox(height: 24),

          // 5. Penyelenggara & Dukungan Resmi
          _buildSectionTitle(
            'Dukungan & Legalitas',
            'Pemerintah Daerah & Pengelola BUMDes',
            Icons.account_balance_rounded,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildOfficialInstitutionCard(isDark),
          const SizedBox(height: 28),

          // 6. Footer & Kontak
          _buildFooterCard(isDark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBrandCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            padding: const EdgeInsets.all(14),
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
          const SizedBox(height: 12),
          const Text(
            'SiladesBeng',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _primaryBlue,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _primaryBlue.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Sistem Sinergi Layanan & Aspirasi Desa',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Kabupaten Bengkalis, Riau',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCeritaCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _primaryBlue.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_stories_rounded, size: 18, color: _primaryBlue),
              ),
              const SizedBox(width: 10),
              Text(
                'Cerita Kami',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'SiladesBeng bermula dari visi besar untuk mempercepat digitalisasi pelayanan publik di Kabupaten Bengkalis. Platform ini hadir menghubungkan seluruh jaringan desa ke dalam satu ekosistem digital yang terpadu, transparan, dan mudah diakses oleh seluruh warga.',
            style: TextStyle(
              fontSize: 12.5,
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _primaryBlue.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: _primaryBlue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11.5,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                  margin: const EdgeInsets.only(top: 3),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _primaryBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12.5,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 10, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    misi,
                    style: TextStyle(
                      fontSize: 12.5,
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
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: col.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'] as IconData, size: 22, color: col),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['sub'] as String,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: col.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Resmi',
                  style: TextStyle(
                    fontSize: 10.5,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 15, color: _primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Bengkalis, Riau, Indonesia',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.email_rounded, size: 15, color: _primaryBlue),
              const SizedBox(width: 8),
              Text(
                'siladesbengdigital@gmail.com',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : Colors.grey.withAlpha(50),
          ),
          const SizedBox(height: 10),
          Text(
            '© 2026 SiladesBeng • Sistem Sinergi Layanan & Aspirasi Desa',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
