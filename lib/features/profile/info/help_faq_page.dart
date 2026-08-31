import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredFaqs = _faqs.where((faq) {
      return faq['question']!.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Pusat Bantuan & FAQ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17.sp,
            letterSpacing: 0.3,
          ),
        ),
        backgroundColor: const Color(0xFF2563EB),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
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
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30.r),
                bottomRight: Radius.circular(30.r),
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
                Text(
                  'Halo, ada yang bisa kami bantu?',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.h),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari pertanyaan...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 15.h,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Expanded(
            child: filteredFaqs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 60.sp,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Pertanyaan tidak ditemukan',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final isContactInfo =
                          filteredFaqs[index]['question'] ==
                          'Hubungi Bantuan Teknis';

                      return Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        decoration: BoxDecoration(
                          color: isContactInfo
                              ? Theme.of(context).primaryColor.withAlpha(20)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(15.r),
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
                                fontSize: 15.sp,
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
                                    fontSize: 14.sp,
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
