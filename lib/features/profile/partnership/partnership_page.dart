import 'package:flutter/material.dart';
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: primaryBlue,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 14),
              title: const Text(
                'Gabung Kemitraan Desa',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 0.3,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryBlue, darkBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Glowing decorative circles
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(15),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Center Icon Content
                  Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(35),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withAlpha(70),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.handshake_rounded,
                            size: 34,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sinergi Digital Pemerintah Desa & BUMDes',
                          style: TextStyle(
                            color: Colors.white.withAlpha(230),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroCard(context, isDark),
                  const SizedBox(height: 20),
                  _buildStatCard(context, isDark),
                  const SizedBox(height: 28),

                  // Section Title: 3 Langkah Mudah
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '3 Langkah Mudah Bergabung',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildCompactSteps(context, isDark),
                  const SizedBox(height: 28),

                  // Section Title: Keuntungan
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Keuntungan Kemitraan Desa',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildBenefitGrid(context, isDark),
                  const SizedBox(height: 32),

                  _buildRegisterButton(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2FA2F1).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Color(0xFF2FA2F1),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transformasi Digital Terpadu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Integrasikan layanan desa, ekonomi BUMDes, dan administrasi warga dalam satu genggaman.',
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildStatCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2FA2F1), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2FA2F1).withAlpha(60),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(35),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kabupaten Bengkalis',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Desa & Kelurahan Tergabung',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                SizedBox(width: 5),
                Text(
                  'Aktif',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
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
            margin: EdgeInsets.only(right: isLast ? 0 : 8),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (step['color'] as Color).withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step['icon'] as IconData,
                    size: 20,
                    color: step['color'] as Color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  step['title'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                Text(
                  step['sub'] as String,
                  style: TextStyle(
                    fontSize: 10,
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
        'icon': Icons.storefront_rounded,
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
            const SizedBox(width: 10),
            Expanded(child: _buildBenefitCard(benefits[1], isDark)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildBenefitCard(benefits[2], isDark)),
            const SizedBox(width: 10),
            Expanded(child: _buildBenefitCard(benefits[3], isDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildBenefitCard(Map<String, dynamic> item, bool isDark) {
    final color = item['color'] as Color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item['icon'] as IconData, size: 20, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            item['title'] as String,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            item['desc'] as String,
            style: TextStyle(
              fontSize: 11,
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
          borderRadius: BorderRadius.circular(18),
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
          icon: const Icon(Icons.add_business_rounded, color: Colors.white, size: 20),
          label: const Text(
            'Ajukan Kemitraan Desa',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

