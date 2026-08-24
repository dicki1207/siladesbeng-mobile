import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Tentang SiladesBeng',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // 1. Hero Header Card
          _buildHeroHeader(context, primaryColor, isDark),
          const SizedBox(height: 28),

          // 2. Layanan Utama Section
          _buildSectionHeader(
            context,
            title: 'Layanan Utama SiladesBeng',
            subtitle: 'Ekosistem digital terpadu untuk kebutuhan warga desa',
            icon: Icons.apps_rounded,
            primaryColor: primaryColor,
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          _buildServiceCard(
            context: context,
            title: 'Sarana Mobilitas & Ambulans',
            badge: 'Transportasi',
            desc:
                'Penyediaan sarana transportasi operasional dan ambulans desa terpadu guna mendukung efisiensi mobilitas operasional dan penanganan kesehatan masyarakat secara cepat dan gratis.',
            icon: Icons.directions_car_filled_rounded,
            color: const Color(0xFF0284C7),
            isDark: isDark,
          ),
          _buildServiceCard(
            context: context,
            title: 'Pemanfaatan Fasilitas Umum',
            badge: 'Fasilitas',
            desc:
                'Sistem reservasi digital terpadu untuk penggunaan fasilitas umum seperti gedung serbaguna, aula pertemuan, dan lapangan olahraga tanpa khawatir jadwal bentrok.',
            icon: Icons.apartment_rounded,
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
          _buildServiceCard(
            context: context,
            title: 'Unit Penyewaan Alat BUMDes',
            badge: 'Penyewaan',
            desc:
                'Peminjaman dan penyewaan alat pesta, tenda, kursi, meja, sound system, hingga diesel dengan ketersediaan stok real-time, transparansi tarif sewa, dan bukti transaksi digital.',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
          _buildServiceCard(
            context: context,
            title: 'Pendistribusian Gas LPG',
            badge: 'Distribusi',
            desc:
                'Manajemen digital untuk memantau kuota dan antrean pendistribusian gas elpiji 3kg di pangkalan BUMDes secara merata, tepat sasaran, dan bebas antrean fisik yang panjang.',
            icon: Icons.propane_tank_rounded,
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
          _buildServiceCard(
            context: context,
            title: 'Pasar Daerah & UMKM Desa',
            badge: 'Ekonomi',
            desc:
                'Katalog dan platform belanja produk unggulan lokal, hasil pertanian, serta produk kuliner UMKM desa langsung dari tangan warga lokal Bengkalis.',
            icon: Icons.storefront_rounded,
            color: const Color(0xFFEC4899),
            isDark: isDark,
          ),
          _buildServiceCard(
            context: context,
            title: 'Pelaporan Warga & Aspirasi',
            badge: 'Pengaduan',
            desc:
                'Wadah interaktif bagi masyarakat untuk menyampaikan aspirasi, keluhan fasilitas, dan aduan langsung ke aparatur desa dengan pelacakan status laporan secara transparan.',
            icon: Icons.campaign_rounded,
            color: const Color(0xFFEF4444),
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // 3. Nilai Utama (Core Values)
          _buildSectionHeader(
            context,
            title: 'Nilai-Nilai Kami',
            subtitle: 'Prinsip utama pelayanan SiladesBeng bagi masyarakat',
            icon: Icons.verified_rounded,
            primaryColor: primaryColor,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildCoreValuesGrid(context, isDark, primaryColor),

          const SizedBox(height: 28),

          // 4. Misi Section
          _buildSectionHeader(
            context,
            title: 'Misi SiladesBeng',
            subtitle: 'Komitmen pembangunan desa mandiri dan berkelanjutan',
            icon: Icons.flag_rounded,
            primaryColor: primaryColor,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildMisiCard(context, isDark, primaryColor),

          const SizedBox(height: 28),

          // 5. Tim Pengembang (Developers)
          _buildSectionHeader(
            context,
            title: 'Tim Pengembang',
            subtitle: 'Sosok di balik pengembangan platform SiladesBeng',
            icon: Icons.groups_rounded,
            primaryColor: primaryColor,
            isDark: isDark,
          ),
          const SizedBox(height: 14),
          _buildDevelopersSection(context, isDark, primaryColor),

          const SizedBox(height: 32),

          // 6. Kontak & Footer
          _buildFooterCard(context, isDark, primaryColor),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(
    BuildContext context,
    Color primaryColor,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            const Color(0xFF0284C7),
            const Color(0xFF38BDF8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Glowing Logo Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              'logodomain.png',
              width: 52,
              height: 52,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.hub_rounded,
                size: 46,
                color: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'SiladesBeng',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Sistem Sinergi Layanan & Aspirasi Desa Bengkalis',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Platform digital inovatif yang dirancang untuk mempercepat digitalisasi pelayanan publik, memutus kendala jarak, dan mengoptimalkan potensi desa & BUMDes di Kabupaten Bengkalis ke dalam satu ekosistem yang terpadu, transparan, dan akuntabel.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color primaryColor,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required String title,
    required String badge,
    required String desc,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 26, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreValuesGrid(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    final values = [
      {
        'title': 'Inovatif',
        'desc':
            'Terus berinovasi menghadirkan solusi digital mutakhir yang menjawab kebutuhan nyata desa.',
        'icon': Icons.lightbulb_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Efisien',
        'desc':
            'Mengubah birokrasi manual menjadi serba cepat demi penghematan waktu dan biaya warga.',
        'icon': Icons.bolt_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Terpercaya',
        'desc':
            'Menjaga akuntabilitas dan transparansi data transaksi desa dengan sistem yang aman.',
        'icon': Icons.shield_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Aksesibel',
        'desc':
            'Antarmuka yang ramah pengguna, dapat diakses kapan saja dan di mana saja melalui ponsel.',
        'icon': Icons.touch_app_rounded,
        'color': const Color(0xFF8B5CF6),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemCount: values.length,
      itemBuilder: (context, idx) {
        final val = values[idx];
        final col = val['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: col.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(val['icon'] as IconData, size: 18, color: col),
              ),
              const SizedBox(height: 8),
              Text(
                val['title'] as String,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  val['desc'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                    height: 1.35,
                  ),
                  overflow: TextOverflow.fade,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMisiCard(BuildContext context, bool isDark, Color primaryColor) {
    final missions = [
      'Meningkatkan efisiensi dan profesionalitas pengelolaan unit usaha desa (BUMDes).',
      'Menyediakan layanan digital yang mudah diakses oleh seluruh masyarakat dan pelaku usaha lokal.',
      'Membangun kepercayaan publik melalui sistem pencatatan transaksi yang transparan dan akuntabel.',
      'Mendorong digitalisasi desa menuju tata kelola ekonomi yang mandiri, produktif, dan berkelanjutan.',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: missions.map((misi) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
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
                  child: const Icon(Icons.check, size: 12, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    misi,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      height: 1.45,
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

  Widget _buildDevelopersSection(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    final devs = [
      {
        'name': 'Rizqy Hamadi Ken',
        'role': 'Full Stack Developer',
        'icon': Icons.code_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'name': 'Mushlihul Arif',
        'role': 'UI/UX Designer & Frontend',
        'icon': Icons.palette_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'name': 'Dicki Wahyudi',
        'role': 'Mobile Developer',
        'icon': Icons.phone_android_rounded,
        'color': const Color(0xFF10B981),
      },
    ];

    return Row(
      children: devs.map((dev) {
        final col = dev['color'] as Color;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: col.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(dev['icon'] as IconData, size: 22, color: col),
                ),
                const SizedBox(height: 8),
                Text(
                  dev['name'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dev['role'] as String,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: GoogleFonts.inter(
                    fontSize: 9.5,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooterCard(
    BuildContext context,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 16, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                'Bengkalis, Riau, Indonesia',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.email_rounded, size: 16, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                'siladesbengdigital@gmail.com',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.phone_rounded, size: 16, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                '(+62) 822-4921-3061',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            '© 2026 SiladesBeng • Sistem Sinergi Layanan & Aspirasi Desa',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
