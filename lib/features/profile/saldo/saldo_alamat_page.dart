import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:siladesbeng_mobile/services/saldo_alamat_service.dart';
import 'form_tarik_saldo_sheet.dart';
import 'form_alamat_sheet.dart';

class SaldoAlamatPage extends StatefulWidget {
  const SaldoAlamatPage({super.key});

  @override
  State<SaldoAlamatPage> createState() => _SaldoAlamatPageState();
}

class _SaldoAlamatPageState extends State<SaldoAlamatPage> {
  final SaldoAlamatService _service = SaldoAlamatService();
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  bool _isLoading = true;
  double _saldo = 0;
  Map<String, dynamic> _rincian = {
    'tersedia': 0.0,
    'diajukan': 0.0,
    'diproses': 0.0,
    'sudah_cair': 0.0,
    'total_masuk': 0.0,
    'terpakai': 0.0,
  };
  List<dynamic> _riwayat = [];
  List<dynamic> _pengajuan = [];
  Map<String, dynamic>? _rekeningTerakhir;
  List<dynamic> _alamatList = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    final saldoRes = await _service.getSaldo();
    final alamatRes = await _service.getAlamat();

    if (!mounted) return;

    if (saldoRes['success'] == true) {
      final data = saldoRes['data'];
      _saldo = (data['saldo'] ?? 0).toDouble();
      if (data['rincian'] != null) {
        _rincian = {
          'tersedia': (data['rincian']['tersedia'] ?? 0).toDouble(),
          'diajukan': (data['rincian']['diajukan'] ?? 0).toDouble(),
          'diproses': (data['rincian']['diproses'] ?? 0).toDouble(),
          'sudah_cair': (data['rincian']['sudah_cair'] ?? 0).toDouble(),
          'total_masuk': (data['rincian']['total_masuk'] ?? 0).toDouble(),
          'terpakai': (data['rincian']['terpakai'] ?? 0).toDouble(),
        };
      }
      _riwayat = data['riwayat']?['data'] ?? [];
      _pengajuan = data['pengajuan'] ?? [];
      _rekeningTerakhir = data['rekening_terakhir'];
    }

    if (alamatRes['success'] == true) {
      _alamatList = alamatRes['data'] ?? [];
    }

    setState(() => _isLoading = false);
  }

  void _openFormTarik() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FormTarikSaldoSheet(
        availableBalance: _saldo,
        rekeningTerakhir: _rekeningTerakhir,
        onSubmit: (amount, bank, noRek, pemilik, catatan) async {
          final res = await _service.tarikSaldo(
            amount: amount,
            namaBank: bank,
            noRekening: noRek,
            namaPemilik: pemilik,
            catatan: catatan,
          );
          if (!mounted) return;
          if (res['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['message'] ?? 'Pengajuan berhasil dikirim!'), backgroundColor: Colors.green),
            );
            _loadAllData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['message'] ?? 'Gagal mengajukan penarikan'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  void _batalPenarikan(int id, double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: const Text('Batalkan Pengajuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Batalkan pengajuan penarikan ${currencyFormatter.format(amount)}? Saldo Anda akan kembali tersedia.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await _service.batalTarik(id);
              if (!mounted) return;
              if (res['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['message'] ?? 'Pengajuan dibatalkan'), backgroundColor: Colors.green),
                );
                _loadAllData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['message'] ?? 'Gagal membatalkan'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _openFormAlamat({Map<String, dynamic>? alamat}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FormAlamatSheet(
        alamatData: alamat,
        onSubmit: (payload) async {
          final res = (alamat == null)
              ? await _service.tambahAlamat(payload)
              : await _service.updateAlamat(alamat['id'], payload);

          if (!mounted) return;
          if (res['success']) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['message'] ?? 'Alamat berhasil disimpan'), backgroundColor: Colors.green),
            );
            _loadAllData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['message'] ?? 'Gagal menyimpan alamat'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  void _setAlamatUtama(int id) async {
    final res = await _service.setAlamatUtama(id);
    if (!mounted) return;
    if (res['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alamat utama berhasil diperbarui'), backgroundColor: Colors.green),
      );
      _loadAllData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Gagal mengubah alamat utama'), backgroundColor: Colors.red),
      );
    }
  }

  void _hapusAlamat(int id, String nama) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: const Text('Hapus Alamat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Hapus alamat penerima "$nama"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await _service.hapusAlamat(id);
              if (!mounted) return;
              if (res['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alamat berhasil dihapus'), backgroundColor: Colors.green),
                );
                _loadAllData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['message'] ?? 'Gagal menghapus alamat'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFF2FA2F1),
        elevation: 0,
        scrolledUnderElevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [const Color(0xFF2FA2F1), const Color(0xFF0284C7)],
                ),
              ),
            ),
            // Glowing ambient light circle 1 (Top Right)
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(22),
                ),
              ),
            ),
            // Glowing ambient light circle 2 (Bottom Left)
            Positioned(
              bottom: -25,
              left: -15,
              child: Container(
                width: 90.w,
                height: 90.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(14),
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(isDark ? 25 : 35),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 16.sp,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Saldo & Alamat',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16.5.sp,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              'Dompet Warga & Buku Alamat',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(210),
                fontWeight: FontWeight.w500,
                fontSize: 11.sp,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
          : RefreshIndicator(
              onRefresh: _loadAllData,
              color: const Color(0xFF0284C7),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. KARTU SALDO TERSEDIA (Gradient Banner)
                    _buildSaldoBanner(),
                    SizedBox(height: 20.h),

                    // 2. PENGAJUAN DANA
                    _buildPengajuanSection(isDark),
                    SizedBox(height: 20.h),

                    // 3. ALAMAT TERSIMPAN
                    _buildAlamatSection(isDark),
                    SizedBox(height: 20.h),

                    // 4. RIWAYAT SALDO
                    _buildRiwayatSection(isDark),
                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            ),
    );
  }

  /// 1. Kartu Saldo Tersedia (Gradient Blue Card)
  Widget _buildSaldoBanner() {
    final tersedia = _rincian['tersedia'] ?? 0.0;
    final diajukan = _rincian['diajukan'] ?? 0.0;
    final diproses = _rincian['diproses'] ?? 0.0;
    final totalMasuk = _rincian['total_masuk'] ?? 0.0;
    final sudahCair = _rincian['sudah_cair'] ?? 0.0;
    final terpakai = _rincian['terpakai'] ?? 0.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withAlpha(80),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Lingkaran dekoratif putih transparan di pojok kanan atas
          Positioned(
            right: -30.w,
            top: -30.h,
            child: Container(
              width: 140.w,
              height: 140.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(25),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo Tersedia',
                  style: TextStyle(color: Colors.white.withAlpha(230), fontSize: 13.sp, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 4.h),
                Text(
                  currencyFormatter.format(tersedia),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),

                // Status chip jika ada dana yang sedang diajukan/diproses
                if (diajukan > 0 || diproses > 0) ...[
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      if (diajukan > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(45),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            'Menunggu diproses ${currencyFormatter.format(diajukan)}',
                            style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w600),
                          ),
                        ),
                      if (diproses > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(45),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            'Sedang ditransfer ${currencyFormatter.format(diproses)}',
                            style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ],

                SizedBox(height: 16.h),
                Divider(color: Colors.white.withAlpha(60), height: 1),
                SizedBox(height: 14.h),

                // 3 Kolom Rincian Dana
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Masuk', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11.sp)),
                          SizedBox(height: 3.h),
                          Text(
                            currencyFormatter.format(totalMasuk),
                            style: TextStyle(color: Colors.white, fontSize: 12.5.sp, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sudah Cair', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11.sp)),
                          SizedBox(height: 3.h),
                          Text(
                            currencyFormatter.format(sudahCair),
                            style: TextStyle(color: Colors.white, fontSize: 12.5.sp, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Terpakai Belanja', style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 11.sp)),
                          SizedBox(height: 3.h),
                          Text(
                            currencyFormatter.format(terpakai),
                            style: TextStyle(color: Colors.white, fontSize: 12.5.sp, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Section Pengajuan Dana
  Widget _buildPengajuanSection(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pengajuan Dana',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              if (_saldo >= 20000)
                InkWell(
                  onTap: _openFormTarik,
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                    child: Text(
                      '+ Ajukan Penarikan',
                      style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),

          if (_pengajuan.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                _saldo < 20000 ? 'Penarikan tersedia mulai Rp 20.000.' : 'Belum ada pengajuan penarikan.',
                style: TextStyle(fontSize: 12.5.sp, color: Colors.grey),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pengajuan.length,
              separatorBuilder: (_, _) => SizedBox(height: 8.h),
              itemBuilder: (context, idx) {
                final p = _pengajuan[idx];
                final status = p['status']?.toString().toLowerCase() ?? 'menunggu';
                final amount = double.tryParse(p['amount'].toString()) ?? 0.0;
                final isMenunggu = status == 'menunggu';

                Color statusColor;
                Color statusBg;
                String statusLabel;

                switch (status) {
                  case 'selesai':
                    statusColor = const Color(0xFF16A34A);
                    statusBg = const Color(0xFFDCFCE7);
                    statusLabel = 'Selesai';
                    break;
                  case 'diproses':
                    statusColor = const Color(0xFF2563EB);
                    statusBg = const Color(0xFFDBEAFE);
                    statusLabel = 'Sedang Diproses';
                    break;
                  case 'ditolak':
                    statusColor = const Color(0xFFDC2626);
                    statusBg = const Color(0xFFFEE2E2);
                    statusLabel = 'Dibatalkan / Ditolak';
                    break;
                  default:
                    statusColor = const Color(0xFFD97706);
                    statusBg = const Color(0xFFFEF3C7);
                    statusLabel = 'Menunggu Diproses';
                }

                return Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : statusBg.withAlpha(40),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: statusColor.withAlpha(60)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currencyFormatter.format(amount),
                              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${p['nama_bank']} · ${p['no_rekening']} · a.n. ${p['nama_pemilik']}',
                              style: TextStyle(fontSize: 11.5.sp, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              statusLabel,
                              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                            if (p['catatan'] != null && p['catatan'].toString().isNotEmpty) ...[
                              SizedBox(height: 2.h),
                              Text(
                                p['catatan'],
                                style: TextStyle(fontSize: 10.5.sp, color: Colors.grey, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isMenunggu)
                        TextButton(
                          onPressed: () => _batalPenarikan(p['id'], amount),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Batalkan',
                            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// 3. Section Alamat Tersimpan (Buku Alamat)
  Widget _buildAlamatSection(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alamat Tersimpan',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              InkWell(
                onTap: () => _openFormAlamat(),
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                  child: Text(
                    '+ Tambah Alamat',
                    style: TextStyle(fontSize: 12.5.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          if (_alamatList.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'Belum ada alamat tersimpan.',
                style: TextStyle(fontSize: 12.5.sp, color: Colors.grey),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _alamatList.length,
              separatorBuilder: (_, _) => SizedBox(height: 10.h),
              itemBuilder: (context, idx) {
                final a = _alamatList[idx];
                final isUtama = a['is_utama'] == true || a['is_utama'] == 1;

                // Format alamat lengkap
                final parts = <String>[];
                if (a['detail_alamat'] != null && a['detail_alamat'].toString().isNotEmpty) {
                  parts.add(a['detail_alamat']);
                }
                if (a['rt'] != null && a['rt'].toString().isNotEmpty) {
                  parts.add('RT ${a['rt']}');
                }
                if (a['rw'] != null && a['rw'].toString().isNotEmpty) {
                  parts.add('RW ${a['rw']}');
                }
                if (a['region'] != null && a['region']['name'] != null) {
                  parts.add(a['region']['name']);
                }
                if (a['kode_pos'] != null && a['kode_pos'].toString().isNotEmpty) {
                  parts.add(a['kode_pos'].toString());
                }
                final fullAddress = parts.join(', ');

                return Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: isUtama ? (isDark ? const Color(0xFF0369A1).withAlpha(30) : const Color(0xFFEFF6FF)) : (isDark ? const Color(0xFF0F172A) : Colors.white),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isUtama ? const Color(0xFF0284C7) : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      width: isUtama ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8.w,
                              runSpacing: 4.h,
                              children: [
                                Text(
                                  a['nama_penerima'] ?? '',
                                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                ),
                                if (a['label'] != null && a['label'].toString().isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      a['label'],
                                      style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                                    ),
                                  ),
                                if (isUtama)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0284C7).withAlpha(30),
                                      borderRadius: BorderRadius.circular(6.r),
                                    ),
                                    child: Text(
                                      'Utama',
                                      style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0284C7)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        a['no_telepon'] ?? '',
                        style: TextStyle(fontSize: 12.sp, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        fullAddress,
                        style: TextStyle(fontSize: 12.sp, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                      if (a['patokan'] != null && a['patokan'].toString().isNotEmpty) ...[
                        SizedBox(height: 3.h),
                        Text(
                          'Patokan: ${a['patokan']}',
                          style: TextStyle(fontSize: 11.sp, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ],
                      SizedBox(height: 10.h),
                      Divider(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0), height: 1),
                      SizedBox(height: 8.h),

                      // Baris Aksi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!isUtama) ...[
                            InkWell(
                              onTap: () => _setAlamatUtama(a['id']),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                child: Text(
                                  'Jadikan Utama',
                                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF0284C7)),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                          ],
                          InkWell(
                            onTap: () => _openFormAlamat(alamat: a),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              child: Text(
                                'Ubah',
                                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB)),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          InkWell(
                            onTap: () => _hapusAlamat(a['id'], a['nama_penerima'] ?? 'alamat'),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              child: Text(
                                'Hapus',
                                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.redAccent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// 4. Section Riwayat Saldo
  Widget _buildRiwayatSection(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riwayat Saldo',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
          SizedBox(height: 12.h),

          if (_riwayat.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                'Belum ada riwayat saldo.',
                style: TextStyle(fontSize: 12.5.sp, color: Colors.grey),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _riwayat.length,
              separatorBuilder: (_, _) => Divider(color: isDark ? Colors.white12 : const Color(0xFFF1F5F9), height: 16.h),
              itemBuilder: (context, idx) {
                final r = _riwayat[idx];
                final type = r['type']?.toString().toLowerCase() ?? '';
                final isMasuk = type == 'refund';
                final amount = double.tryParse(r['amount'].toString()) ?? 0.0;

                String typeLabel = 'Mutasi Saldo';
                if (type == 'refund') {
                  typeLabel = 'Pengembalian Dana (Refund)';
                } else if (type == 'penarikan') {
                  typeLabel = 'Penarikan Dana';
                } else if (type == 'belanja') {
                  typeLabel = 'Pembayaran Belanja';
                }

                String createdAtStr = r['created_at']?.toString() ?? '';
                if (createdAtStr.isNotEmpty) {
                  try {
                    final dt = DateTime.parse(createdAtStr);
                    createdAtStr = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt);
                  } catch (_) {}
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: isMasuk ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isMasuk ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: isMasuk ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        size: 16.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            typeLabel,
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                          if (r['catatan'] != null && r['catatan'].toString().isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              r['catatan'],
                              style: TextStyle(fontSize: 11.5.sp, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                            ),
                          ],
                          SizedBox(height: 2.h),
                          Text(
                            '$createdAtStr WIB · ${r['status'] ?? ''}',
                            style: TextStyle(fontSize: 10.5.sp, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${isMasuk ? '+' : '−'} ${currencyFormatter.format(amount)}',
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.bold,
                        color: isMasuk ? const Color(0xFF16A34A) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
