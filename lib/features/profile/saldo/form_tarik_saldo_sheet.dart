import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class FormTarikSaldoSheet extends StatefulWidget {
  final double availableBalance;
  final Map<String, dynamic>? rekeningTerakhir;
  final Function(double amount, String bank, String noRekening, String pemilik, String? catatan) onSubmit;

  const FormTarikSaldoSheet({
    super.key,
    required this.availableBalance,
    this.rekeningTerakhir,
    required this.onSubmit,
  });

  @override
  State<FormTarikSaldoSheet> createState() => _FormTarikSaldoSheetState();
}

class _FormTarikSaldoSheetState extends State<FormTarikSaldoSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _bankController;
  late TextEditingController _noRekeningController;
  late TextEditingController _pemilikController;
  late TextEditingController _catatanController;
  bool _isLoading = false;

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.availableBalance.toInt().toString());
    _bankController = TextEditingController(text: widget.rekeningTerakhir?['nama_bank'] ?? '');
    _noRekeningController = TextEditingController(text: widget.rekeningTerakhir?['no_rekening'] ?? '');
    _pemilikController = TextEditingController(text: widget.rekeningTerakhir?['nama_pemilik'] ?? '');
    _catatanController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bankController.dispose();
    _noRekeningController.dispose();
    _pemilikController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (amount < 20000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penarikan minimal Rp 20.000'), backgroundColor: Colors.red),
      );
      return;
    }
    if (amount > widget.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saldo tidak mencukupi. Maksimal: ${currencyFormatter.format(widget.availableBalance)}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await widget.onSubmit(
      amount,
      _bankController.text.trim(),
      _noRekeningController.text.trim(),
      _pemilikController.text.trim(),
      _catatanController.text.trim().isEmpty ? null : _catatanController.text.trim(),
    );
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
        left: 20.w,
        right: 20.w,
        top: 14.h,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(100),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withAlpha(30),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.account_balance_rounded, color: const Color(0xFF0284C7), size: 22.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ajukan Penarikan Dana',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Tersedia: ${currencyFormatter.format(widget.availableBalance)}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: const Color(0xFF0284C7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),

              // Nominal
              Text(
                'Jumlah Penarikan (Min Rp 20.000)',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: const Color(0xFF0284C7)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Jumlah penarikan wajib diisi';
                  final num = double.tryParse(val);
                  if (num == null || num < 20000) return 'Minimal penarikan adalah Rp 20.000';
                  if (num > widget.availableBalance) return 'Saldo tidak mencukupi';
                  return null;
                },
              ),
              SizedBox(height: 14.h),

              // Bank / E-Wallet & No Rekening
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bank / E-Wallet',
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _bankController,
                          textCapitalization: TextCapitalization.characters,
                          style: TextStyle(fontSize: 13.sp),
                          decoration: InputDecoration(
                            hintText: 'BRI, BSI, DANA',
                            hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                          ),
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Wajib diisi' : null,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nomor Rekening / HP',
                          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _noRekeningController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 13.sp),
                          decoration: InputDecoration(
                            hintText: '1234567890',
                            hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                          ),
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Wajib diisi' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              // Nama Pemilik
              Text(
                'Nama Pemilik Rekening',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _pemilikController,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(fontSize: 13.sp),
                decoration: InputDecoration(
                  hintText: 'Sesuai buku tabungan / akun',
                  hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Nama pemilik wajib diisi' : null,
              ),
              SizedBox(height: 14.h),

              // Catatan Opsional
              Text(
                'Catatan (Opsional)',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _catatanController,
                maxLines: 2,
                style: TextStyle(fontSize: 13.sp),
                decoration: InputDecoration(
                  hintText: 'Pencairan saldo refund pesanan',
                  hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
                ),
              ),
              SizedBox(height: 22.h),

              // Tombol Aksi
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                      ),
                      child: Text('Batal', style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF475569), fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(width: 20.w, height: 20.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Kirim Pengajuan', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
