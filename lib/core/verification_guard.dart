import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/features/profile/verification/verification_page.dart';

/// Gerbang verifikasi lanjutan (KYC) untuk unit pelayanan.
///
/// Pola yang dipakai: warga tetap boleh melihat-lihat etalase layanan, tapi
/// aksi transaksinya (pesan / sewa) dikunci sampai KYC lolos.
///
/// PENTING: ini murni lapisan UX. `is_verified` cuma bool di SharedPreferences
/// milik HP warga, jadi tidak bisa dijadikan kontrol keamanan — backend tetap
/// wajib menolak request booking dari akun yang belum lolos KYC.
class VerificationGuard {
  const VerificationGuard._();

  static const String prefsKey = 'is_verified';

  /// Menerjemahkan payload user dari API jadi status KYC.
  ///
  /// Sengaja TIDAK memakai keberadaan NIK sebagai bukti: NIK bisa terisi dari
  /// form pendaftaran atau diinput admin tanpa warga pernah lewat KYC (scan
  /// KTP + rekam wajah), jadi "punya NIK" bukan tanda sudah terverifikasi.
  static bool isVerifiedFromApi(Map<String, dynamic>? user) {
    if (user == null) return false;

    const approved = {'verified', 'approved'};
    final status = user['verification_status']?.toString().toLowerCase().trim();
    if (status != null && approved.contains(status)) return true;

    final kycStatus = user['kyc_status']?.toString().toLowerCase().trim();
    if (kycStatus != null && approved.contains(kycStatus)) return true;

    return user['is_verified'] == true;
  }

  static Future<bool> isVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  /// `true` kalau warga boleh lanjut transaksi. Kalau belum terverifikasi,
  /// dialog ajakan KYC ditampilkan dan hasilnya `false`.
  static Future<bool> ensureVerified(
    BuildContext context, {
    required String serviceName,
  }) async {
    if (await isVerified()) return true;
    if (!context.mounted) return false;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Icon(
              Icons.verified_user_outlined,
              color: Theme.of(ctx).primaryColor,
              size: 26.sp,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Verifikasi Diperlukan',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Untuk menggunakan $serviceName, Anda harus memverifikasi identitas '
          '(KYC) terlebih dahulu. Prosesnya cukup sekali: scan KTP lalu rekam '
          'wajah.',
          style: TextStyle(fontSize: 13.5.sp, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nanti', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VerificationPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: const Text(
              'Verifikasi Sekarang',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return false;
  }
}

/// Spanduk peringatan di atas halaman unit pelayanan, supaya warga tahu sejak
/// awal bahwa pemesanan butuh KYC — bukan baru ditolak di langkah terakhir.
/// Otomatis menghilang kalau akunnya sudah terverifikasi.
class VerificationBanner extends StatefulWidget {
  const VerificationBanner({super.key});

  @override
  State<VerificationBanner> createState() => _VerificationBannerState();
}

class _VerificationBannerState extends State<VerificationBanner> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
