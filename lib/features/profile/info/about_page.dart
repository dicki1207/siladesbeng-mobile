import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tentang Layanan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 10),
          _buildHeroHeader(context),
          const SizedBox(height: 30),
          Text(
            'Layanan Utama SiladesBeng',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildServiceCard(
            context,
            'Unit Penyewaan Alat',
            'Masyarakat dapat melakukan pemesanan sewa alat seperti tenda, kursi, meja, sound system, dan diesel secara online. Sistem menampilkan ketersediaan alat secara real-time, harga sewa yang transparan, serta bukti transaksi digital. Hal ini membantu menghindari bentrok jadwal dan mempercepat pelayanan warga tanpa harus datang langsung ke lokasi.',
            Icons.inventory_2_outlined,
            Colors.orange,
          ),
          _buildServiceCard(
            context,
            'Pelaporan dan Monitoring',
            'Laporan keuangan, laporan transaksi, serta kinerja unit usaha secara otomatis dan real-time. Sistem ini membantu meningkatkan akuntabilitas dan mempermudah evaluasi pengelolaan dana desa dengan laporan digital yang rapi dan terintegrasi.',
            Icons.bar_chart_rounded,
            Colors.blueAccent,
          ),
          _buildServiceCard(
            context,
            'Penjualan Gas',
            'Sistem antrean dan pemesanan gas elpiji secara digital. Memastikan distribusi gas tepat sasaran, mengurangi antrean fisik yang panjang, dan memberikan notifikasi langsung kepada warga saat ketersediaan gas sudah ada di pangkalan BUMDes.',
            Icons.propane_tank_outlined,
            Colors.green,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, const Color(0xFF6DC4F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withAlpha(50),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.info_outline, size: 60, color: Colors.white),
          const SizedBox(height: 16),
          const Text(
            'Apa itu SiladesBeng?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sistem Layanan Desa Bengkalis (SiladesBeng) adalah platform digital inovatif yang dirancang untuk mempercepat, mempermudah, dan mentransparansikan berbagai layanan administrasi dan BUMDes di Kabupaten Bengkalis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withAlpha(230),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    String desc,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withAlpha(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.5,
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
