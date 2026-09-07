import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HelpFaqPage extends StatefulWidget {
  const HelpFaqPage({super.key});

  @override
  State<HelpFaqPage> createState() => _HelpFaqPageState();
}

class _HelpFaqPageState extends State<HelpFaqPage> {
  String _selectedCategory = 'Semua';
  String _searchQuery = "";

  final List<String> _categories = [
    'Semua',
    'Unit Pelayanan',
    'Kemitraan Desa',
    'Akun & Teknis',
  ];

  final List<Map<String, dynamic>> _faqs = [
    // ==========================================
    // UNIT PELAYANAN BUMDES
    // ==========================================
    {
      'category': 'Unit Pelayanan',
      'icon': Icons.local_gas_station_rounded,
      'question': 'Bagaimana cara memesan gas LPG melalui aplikasi?',
      'answer':
          'Masuk ke menu Gas LPG di Beranda, pilih tabung yang dibutuhkan (3kg, 5.5kg, atau 12kg), tentukan kuantitas pemesanan, pilih metode pengantaran (antar ke rumah atau ambil mandiri di pangkalan BUMDes), lalu klik "Pesan Sekarang". Pastikan alamat dan nomor telepon Anda sudah lengkap.',
    },
    {
      'category': 'Unit Pelayanan',
      'icon': Icons.verified_user_rounded,
      'question': 'Apa syarat pembelian Gas LPG 3kg (Subsidi)?',
      'answer':
          'Pembeli wajib merupakan warga terdaftar yang akunnya telah lolos verifikasi kependudukan (NIK/KK) di wilayah desa setempat. Selain itu, Anda wajib menyiapkan dan menyerahkan tabung kosong ukuran 3kg dalam kondisi fisik layak saat penukaran barang.',
    },
    {
      'category': 'Unit Pelayanan',
      'icon': Icons.delivery_dining_rounded,
      'question': 'Apakah pesanan gas LPG bisa diantar langsung ke rumah?',
      'answer':
          'Ya, BUMDes menyediakan opsi pengantaran langsung ke rumah oleh kurir lokal desa. Tarif biaya pengantaran tertera transparan pada rincian pesanan sesuai jarak dusun tempat tinggal Anda.',
    },
    {
      'category': 'Unit Pelayanan',
      'icon': Icons.inventory_2_rounded,
      'question': 'Bagaimana jika stok tabung gas di pangkalan sedang kosong?',
      'answer':
          'Jumlah stok tabung gas di aplikasi diperbarui secara realtime sesuai ketersediaan fisik di pangkalan BUMDes. Apabila stok kosong (0), tombol pesan otomatis dinonaktifkan. Anda dapat memanfaatkan fitur Chat Petugas di halaman terkait untuk menanyakan jadwal pasokan tabung berikutnya.',
    },
    {
      'category': 'Unit Pelayanan',
      'icon': Icons.handyman_rounded,
      'question': 'Alat dan mesin apa saja yang dapat disewa dari BUMDes?',
      'answer':
          'BUMDes menyediakan berbagai perlengkapan acara warga (tenda, kursi, sound system), peralatan pertukangan dan konstruksi (molen semen, vibrator beton), serta mesin pertanian (traktor mini, mesin pemotong rumput) sesuai unit inventaris desa Anda.',
    },
    {
      'category': 'Unit Pelayanan',
      'icon': Icons.category_rounded,
      'question': 'Apa perbedaan "Paket Alat Desa" dan "Buat Paket Sendiri"?',
      'answer':
          'Paket Alat Desa adalah bundel lengkap siap pakai yang dirancang BUMDes dengan harga sewa yang lebih hemat. Sedangkan opsi Buat Paket Sendiri memberikan fleksibilitas bagi warga untuk memilih alat satuan dan menentukan jumlah unit sesuai kebutuhan spesifik kegiatan.',
    },
    {
      'category': 'Unit Pelayanan',
      'icon': Icons.gavel_rounded,
      'question': 'Bagaimana tanggung jawab jika alat sewa mengalami kerusakan?',
      'answer':
          'Sebelum serah terima, petugas BUMDes dan penyewa akan melakukan pengecekan fisik bersama. Segala kerusakan fungsi atau kehilangan komponen akibat kelalaian operasional penyewa menjadi tanggung jawab penyewa sesuai surat perjanjian serah terima sewa.',
    },
    {
      'category': 'Unit Pelayanan',
      'icon': Icons.schedule_rounded,
      'question': 'Kapan batas waktu pengembalian alat dan mesin sewa?',
      'answer':
          'Alat sewa wajib dikembalikan ke kantor/gudang BUMDes paling lambat pukul 17.00 WIB pada hari terakhir durasi sewa dalam kondisi bersih dan berfungsi baik. Keterlambatan pengembalian tanpa konfirmasi dapat dikenakan biaya sewa harian tambahan.',
    },
    {
      'category': 'Unit Pelayanan',
      'icon': Icons.directions_car_rounded,
      'question': 'Bagaimana prosedur peminjaman mobil operasional desa?',
      'answer':
          'Buka menu Penyewaan Mobil di Beranda, pilih unit mobil yang tersedia, tentukan durasi dan tanggal sewa, serta lampirkan foto KTP saat pengajuan formulir. Layanan ini sudah termasuk supir dari petugas BUMDes.',
    },
    {
      'category': 'Unit Pelayanan',
      'icon': Icons.medical_services_rounded,
      'question': 'Apakah peminjaman Ambulans Desa dikenakan biaya tarif?',
      'answer':
          'Untuk kebutuhan medis darurat dan rujukan pasien warga desa, layanan ambulans desa diprioritaskan dan disubsidi penuh (gratis) oleh pemerintah desa. Untuk kebutuhan transportasi medis terjadwal atau ke luar kabupaten, berlaku tarif retribusi penggantian bahan bakar operasional.',
    },
    {
      'category': 'Unit Pelayanan',
      'icon': Icons.account_balance_rounded,
      'question': 'Kapan peminjaman fasilitas umum (aula/gedung desa) digratiskan?',
      'answer':
          'Peminjaman fasilitas umum dan aula serbaguna desa digratiskan penuh (Rp 0) untuk kegiatan sosial, musyawarah dusun, gotong royong, kegiatan keagamaan umum, posyandu, dan rapat kedinasan desa.',
    },
    {
      'category': 'Unit Pelayanan',
      'icon': Icons.celebration_rounded,
      'question': 'Bagaimana jika ingin menyewa aula desa untuk hajatan pribadi?',
      'answer':
          'Untuk acara pribadi seperti resepsi pernikahan atau syukuran keluarga, pemohon dikenakan biaya retribusi kebersihan dan pemeliharaan gedung. Pengajuan sewa disarankan dilakukan minimal H-7 acara melalui menu Fasilitas Umum di aplikasi.',
    },
    {
      'category': 'Unit Pelayanan',
      'icon': Icons.storefront_rounded,
      'question': 'Apa itu layanan Pasar Daerah di aplikasi?',
      'answer':
          'Pasar Daerah adalah pasar digital terintegrasi untuk memasarkan produk lokal, hasil bumi, makanan khas, dan kerajinan tangan dari pelaku UMKM serta kelompok tani binaan desa di Kabupaten Bengkalis.',
    },
    {
      'category': 'Unit Pelayanan',
      'icon': Icons.payment_rounded,
      'question': 'Metode pembayaran apa saja yang didukung di Pasar Daerah?',
      'answer':
          'Pasar Daerah mendukung opsi Tunai/COD (bayar saat barang diterima), Transfer Rekening Bank Manual, hingga pembayaran instan otomatis menggunakan QRIS dan Virtual Account.',
    },

    // ==========================================
    // GABUNG KEMITRAAN DESA
    // ==========================================
    {
      'category': 'Kemitraan Desa',
      'icon': Icons.handshake_rounded,
      'question': 'Apa itu Program Kemitraan Desa SiladesBeng?',
      'answer':
          'Program Kemitraan Desa adalah inisiatif integrasi digital resmi yang memungkinkan Pemerintah Desa dan BUMDes memiliki portal operasional mandiri di dalam ekosistem SiladesBeng untuk mengelola katalog usaha, retribusi kas PADes, persewaan aset, dan pelayanan publik secara transparan.',
    },
    {
      'category': 'Kemitraan Desa',
      'icon': Icons.badge_rounded,
      'question': 'Siapa saja yang berhak mendaftarkan desa untuk bermitra?',
      'answer':
          'Pendaftaran kemitraan dapat diajukan oleh Kepala Desa, Sekretaris Desa, Direktur/Pengurus BUMDes, atau staf operator desa yang ditunjuk resmi dengan surat tugas dari pemerintah desa setempat.',
    },
    {
      'category': 'Kemitraan Desa',
      'icon': Icons.file_present_rounded,
      'question': 'Dokumen apa saja yang wajib disiapkan saat mendaftar kemitraan?',
      'answer':
          '1) Data profil kantor desa dan BUMDes.\n2) File scan Surat Keputusan (SK) Pendirian BUMDes atau Peraturan Desa (Perdes).\n3) KTP elektronik penanggung jawab / pemohon.\n4) Alamat email dan nomor WhatsApp resmi kantor desa.',
    },
    {
      'category': 'Kemitraan Desa',
      'icon': Icons.timer_outlined,
      'question': 'Berapa lama proses verifikasi pendaftaran kemitraan desa?',
      'answer':
          'Proses verifikasi dokumen legalitas membutuhkan waktu 1 hingga 3 hari kerja oleh tim administrator kabupaten. Pemberitahuan status aktivasi akun admin akan dikirimkan melalui notifikasi aplikasi dan email terdaftar.',
    },
    {
      'category': 'Kemitraan Desa',
      'icon': Icons.money_off_rounded,
      'question': 'Apakah bergabung dalam kemitraan SiladesBeng dipungut biaya?',
      'answer':
          'Tidak ada biaya pendaftaran maupun biaya langganan bulanan (Gratis). Program ini didukung penuh untuk mempercepat digitalisasi desa dan transparansi Pendapatan Asli Desa (PADes) di Kabupaten Bengkalis.',
    },
    {
      'category': 'Kemitraan Desa',
      'icon': Icons.dashboard_customize_rounded,
      'question': 'Apa saja keuntungan dan akses yang didapatkan Desa Mitra?',
      'answer':
          'Desa mitra akan mendapatkan:\n• Dashboard Admin Web mandiri untuk mengelola produk gas, inventaris sewa, dan fasilitas desanya sendiri.\n• Pembukuan dan rekapitulasi transaksi kas masuk/keluar otomatis secara realtime.\n• Akses verifikasi pengaduan masyarakat di wilayah desa.\n• Fitur chat terpadu untuk merespons kebutuhan dan pertanyaan warga secara langsung.',
    },
    {
      'category': 'Kemitraan Desa',
      'icon': Icons.pin_drop_rounded,
      'question': 'Bagaimana cara warga mengetahui jika desanya sudah bermitra?',
      'answer':
          'Setelah verifikasi disetujui, nama desa akan langsung aktif pada pilihan wilayah (region) di aplikasi warga. Warga di desa tersebut dapat langsung melihat katalog barang, tarif sewa, serta memesan layanan resmi BUMDes lokal.',
    },
    {
      'category': 'Kemitraan Desa',
      'icon': Icons.add_business_rounded,
      'question': 'Bagaimana jika BUMDes ingin menambah unit usaha baru di kemudian hari?',
      'answer':
          'BUMDes yang telah bermitra dapat mengaktifkan unit usaha tambahan baru (seperti Pengelolaan Air Bersih PAMSIMAS, Unit Wisata Desa, atau Pengolahan Sampah) kapan saja melalui panel admin tanpa perlu melakukan pendaftaran kemitraan dari awal.',
    },

    // ==========================================
    // AKUN & TEKNIS
    // ==========================================
    {
      'category': 'Akun & Teknis',
      'icon': Icons.apps_rounded,
      'question': 'Apa itu aplikasi SiladesBeng?',
      'answer':
          'SiladesBeng adalah Sistem Informasi Layanan Desa dan BUMDes di Kabupaten Bengkalis. Aplikasi ini memudahkan masyarakat desa dalam mengakses layanan publik, penyewaan fasilitas, pemesanan gas, pasar daerah, pengaduan warga, hingga panggilan darurat.',
    },
    {
      'category': 'Akun & Teknis',
      'icon': Icons.emergency_rounded,
      'question': 'Apakah fitur Panggilan Darurat dikenakan biaya?',
      'answer':
          'Tidak. Fitur Panggilan Darurat terhubung langsung dengan nomor telepon layanan darurat seperti Ambulans, Pemadam Kebakaran, atau Polsek setempat, dan sepenuhnya bebas biaya tambahan.',
    },
    {
      'category': 'Akun & Teknis',
      'icon': Icons.face_retouching_natural_rounded,
      'question': 'Mengapa wajah saya gagal diverifikasi (Liveness Check)?',
      'answer':
          'Pastikan Anda berada di ruangan dengan pencahayaan yang cukup, tidak memakai kacamata hitam atau masker, dan posisi kamera sejajar dengan wajah. Ikuti gerakan petunjuk pada layar (seperti menoleh atau mengedip) secara perlahan.',
    },
    {
      'category': 'Akun & Teknis',
      'icon': Icons.lock_reset_rounded,
      'question': 'Bagaimana cara mengganti kata sandi akun?',
      'answer':
          'Buka menu Profil, lalu masuk ke halaman Edit Profil. Pilih tab Akun, dan tekan tombol "Ubah Sandi" untuk mengatur kata sandi baru Anda.',
    },
    {
      'category': 'Akun & Teknis',
      'icon': Icons.support_agent_rounded,
      'question': 'Hubungi Bantuan Teknis',
      'answer':
          'Jika kendala Anda belum terjawab, Anda bisa menghubungi tim dukungan teknis kami melalui email support@siladesbeng.id atau melalui layanan WhatsApp BUMDes resmi di jam operasional kantor.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final filteredFaqs = _faqs.where((faq) {
      final matchesCategory = _selectedCategory == 'Semua' ||
          faq['category'] == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          faq['question'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['answer'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
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
          // Search Header Card
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 14.h),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24.r),
                bottomRight: Radius.circular(24.r),
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
                  style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12.h),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.withAlpha(30),
                    ),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari pertanyaan atau kata kunci...',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13.5.sp,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 13.h,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),

                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0EA5E9)
                                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0EA5E9)
                                    : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : const Color(0xFF475569)),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 6.h),

          // FAQ List
          Expanded(
            child: filteredFaqs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 56.sp,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          'Pertanyaan tidak ditemukan',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Coba kata kunci lain atau pilih kategori "Semua"',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final item = filteredFaqs[index];
                      final isContactInfo =
                          item['question'] == 'Hubungi Bantuan Teknis';
                      final IconData iconData =
                          (item['icon'] as IconData?) ?? Icons.help_outline_rounded;

                      return Container(
                        margin: EdgeInsets.only(bottom: 10.h),
                        decoration: BoxDecoration(
                          color: isContactInfo
                              ? primaryColor.withAlpha(20)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isContactInfo
                                ? primaryColor.withAlpha(50)
                                : (isDark ? Colors.white10 : Colors.grey.withAlpha(30)),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 20 : 4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            iconColor: isContactInfo ? primaryColor : primaryColor,
                            collapsedIconColor: isContactInfo
                                ? primaryColor
                                : (isDark ? Colors.white54 : Colors.grey[500]),
                            leading: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: (isContactInfo ? primaryColor : const Color(0xFF0284C7))
                                    .withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                iconData,
                                color: isContactInfo
                                    ? primaryColor
                                    : const Color(0xFF0284C7),
                                size: 19.sp,
                              ),
                            ),
                            title: Text(
                              item['question']!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5.sp,
                                color: isContactInfo
                                    ? primaryColor
                                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                            ),
                            subtitle: Padding(
                              padding: EdgeInsets.only(top: 3.h),
                              child: Text(
                                item['category']!,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: isDark ? Colors.white38 : Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  20.w,
                                  0,
                                  20.w,
                                  16.h,
                                ),
                                child: Text(
                                  item['answer']!,
                                  style: TextStyle(
                                    height: 1.55,
                                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    fontSize: 13.sp,
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
