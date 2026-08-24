import 'package:flutter/material.dart';

class HelpFaqPage extends StatefulWidget {
  const HelpFaqPage({super.key});

  @override
  State<HelpFaqPage> createState() => _HelpFaqPageState();
}

class _HelpFaqPageState extends State<HelpFaqPage> {
  final List<Map<String, String>> _faqs = [
    {
      'question': 'Apa itu aplikasi SiladesBeng?',
      'answer':
          'SiladesBeng adalah Sistem Informasi Layanan Desa dan BUMDes di Kabupaten Bengkalis. Aplikasi ini memudahkan masyarakat desa dalam mengakses layanan publik, penyewaan BUMDes, laporan, hingga panggilan darurat.',
    },
    {
      'question': 'Bagaimana cara meminjam Fasilitas Umum / BUMDes?',
      'answer':
          'Masuk ke menu Peminjaman BUMDes di Beranda, pilih kategori fasilitas yang ingin dipinjam, tentukan tanggal, lalu isi formulir. Jika acara bersifat sosial, biayanya adalah Rp 0 (gratis). Untuk acara pribadi, berlaku tarif sewa sesuai BUMDes.',
    },
    {
      'question': 'Apakah fitur Panggilan Darurat dikenakan biaya?',
      'answer':
          'Tidak. Fitur Panggilan Darurat terhubung langsung dengan nomor telepon layanan darurat seperti Ambulans, Pemadam Kebakaran, atau Polisi setempat, dan sepenuhnya gratis.',
    },
    {
      'question': 'Mengapa wajah saya gagal diverifikasi (Liveness Check)?',
      'answer':
          'Pastikan Anda berada di tempat yang cukup cahaya, tidak memakai kacamata gelap atau masker, dan posisi kamera sejajar dengan wajah. Ikuti instruksi di layar (misal: Tengok kanan/kiri) secara perlahan.',
    },
    {
      'question': 'Bagaimana cara mengganti kata sandi?',
      'answer':
          'Buka menu Profil, lalu masuk ke halaman Edit Profil. Pilih tab Akun, dan tekan tombol "Ubah Sandi" untuk mengatur kata sandi Anda yang baru.',
    },
    {
      'question': 'Hubungi Bantuan Teknis',
      'answer':
          'Jika kendala Anda belum terjawab, Anda bisa menghubungi tim dukungan teknis kami melalui email support@siladesbeng.id atau WhatsApp ke 0812-XXXX-XXXX.',
    },
  ];

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqs.where((faq) {
      return faq['question']!.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pusat Bantuan & FAQ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Halo, ada yang bisa kami bantu?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari pertanyaan...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: filteredFaqs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Pertanyaan tidak ditemukan',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final isContactInfo =
                          filteredFaqs[index]['question'] ==
                          'Hubungi Bantuan Teknis';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isContactInfo
                              ? Theme.of(context).primaryColor.withAlpha(20)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isContactInfo
                                ? Theme.of(context).primaryColor.withAlpha(50)
                                : Colors.grey.withAlpha(30),
                          ),
                        ),
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            iconColor: isContactInfo
                                ? Theme.of(context).primaryColor
                                : null,
                            collapsedIconColor: isContactInfo
                                ? Theme.of(context).primaryColor
                                : null,
                            leading: Icon(
                              isContactInfo
                                  ? Icons.headset_mic_rounded
                                  : Icons.help_outline_rounded,
                              color: isContactInfo
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[600],
                            ),
                            title: Text(
                              filteredFaqs[index]['question']!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isContactInfo
                                    ? Theme.of(context).primaryColor
                                    : null,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  20,
                                ),
                                child: Text(
                                  filteredFaqs[index]['answer']!,
                                  style: TextStyle(
                                    height: 1.5,
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
