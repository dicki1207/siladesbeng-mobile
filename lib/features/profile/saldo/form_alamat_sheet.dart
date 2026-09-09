import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:siladesbeng_mobile/services/saldo_alamat_service.dart';

class FormAlamatSheet extends StatefulWidget {
  final Map<String, dynamic>? alamatData; // If null, mode tambah. If not null, mode edit.
  final Function(Map<String, dynamic> payload) onSubmit;

  const FormAlamatSheet({
    super.key,
    this.alamatData,
    required this.onSubmit,
  });

  @override
  State<FormAlamatSheet> createState() => _FormAlamatSheetState();
}

class _FormAlamatSheetState extends State<FormAlamatSheet> {
  final _formKey = GlobalKey<FormState>();
  final SaldoAlamatService _service = SaldoAlamatService();

  late TextEditingController _labelController;
  late TextEditingController _namaController;
  late TextEditingController _telpController;
  late TextEditingController _detailController;
  late TextEditingController _rtController;
  late TextEditingController _rwController;
  late TextEditingController _posController;
  late TextEditingController _patokanController;

  bool _isUtama = false;
  bool _isLoading = false;
  bool _isLoadingRegions = true;

  List<dynamic> _kecamatanList = [];
  Map<String, dynamic>? _selectedKecamatan;
  Map<String, dynamic>? _selectedDesa;

  @override
  void initState() {
    super.initState();
    final d = widget.alamatData;
    _labelController = TextEditingController(text: d?['label'] ?? '');
    _namaController = TextEditingController(text: d?['nama_penerima'] ?? '');
    _telpController = TextEditingController(text: d?['no_telepon'] ?? '');
    _detailController = TextEditingController(text: d?['detail_alamat'] ?? '');
    _rtController = TextEditingController(text: d?['rt'] ?? '');
    _rwController = TextEditingController(text: d?['rw'] ?? '');
    _posController = TextEditingController(text: d?['kode_pos'] ?? '');
    _patokanController = TextEditingController(text: d?['patokan'] ?? '');
    _isUtama = d?['is_utama'] == true || d?['is_utama'] == 1;

    _fetchRegions();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _namaController.dispose();
    _telpController.dispose();
    _detailController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _posController.dispose();
    _patokanController.dispose();
    super.dispose();
  }

  Future<void> _fetchRegions() async {
    final list = await _service.getRegions();
    if (!mounted) return;

    setState(() {
      _kecamatanList = list;
      _isLoadingRegions = false;

      // Jika sedang edit dan punya region_id, cocokkan kecamatan & desa
      final existingRegionId = widget.alamatData?['region_id']?.toString();
      if (existingRegionId != null) {
        for (final kec in _kecamatanList) {
          final children = kec['children'] as List<dynamic>? ?? [];
          final found = children.firstWhere(
            (c) => c['id']?.toString() == existingRegionId,
            orElse: () => null,
          );
          if (found != null) {
            _selectedKecamatan = kec;
            _selectedDesa = found;
            break;
          }
        }
      }
    });
  }

  void _openSearchPicker({
    required String title,
    required List<dynamic> items,
    required ValueChanged<Map<String, dynamic>> onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final filtered = items.where((item) {
            final name = item['name']?.toString().toLowerCase() ?? '';
            return name.contains(searchQuery.toLowerCase());
          }).toList();

          return Container(
            height: 0.65.sh,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              children: [
                SizedBox(height: 12.h),
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(10.r)),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 8.h),
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  child: TextField(
                    onChanged: (val) => setModalState(() => searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari wilayah...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('Tidak ditemukan'))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => Divider(height: 1, color: isDark ? Colors.white12 : Colors.grey[200]),
                          itemBuilder: (context, idx) {
                            final it = filtered[idx];
                            return ListTile(
                              title: Text(it['name'] ?? '', style: TextStyle(fontSize: 14.sp)),
                              onTap: () {
                                onSelected(it);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final payload = <String, dynamic>{
      'label': _labelController.text.trim().isEmpty ? null : _labelController.text.trim(),
      'nama_penerima': _namaController.text.trim(),
      'no_telepon': _telpController.text.trim(),
      if (_selectedDesa != null) 'region_id': _selectedDesa!['id'],
      'detail_alamat': _detailController.text.trim(),
      'rt': _rtController.text.trim().isEmpty ? null : _rtController.text.trim(),
      'rw': _rwController.text.trim().isEmpty ? null : _rwController.text.trim(),
      'kode_pos': _posController.text.trim().isEmpty ? null : _posController.text.trim(),
      'patokan': _patokanController.text.trim().isEmpty ? null : _patokanController.text.trim(),
      'is_utama': _isUtama,
    };

    await widget.onSubmit(payload);
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.alamatData != null;

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
                    child: Icon(
                      isEdit ? Icons.edit_location_alt_rounded : Icons.add_location_alt_rounded,
                      color: const Color(0xFF0284C7),
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      isEdit ? 'Ubah Alamat Pengiriman' : 'Tambah Alamat Pengiriman',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),

              // Label & Nama Penerima
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Label', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _labelController,
                          style: TextStyle(fontSize: 13.sp),
                          decoration: _inputDecoration('Rumah, Kantor', isDark),
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
                        Text('Nama Penerima *', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _namaController,
                          style: TextStyle(fontSize: 13.sp),
                          decoration: _inputDecoration('Nama lengkap', isDark),
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Wajib diisi' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              // Nomor Telepon
              Text('Nomor Telepon *', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569))),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _telpController,
                keyboardType: TextInputType.phone,
                style: TextStyle(fontSize: 13.sp),
                decoration: _inputDecoration('08xxxxxxxxxx', isDark),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Nomor telepon wajib diisi' : null,
              ),
              SizedBox(height: 14.h),

              // Kecamatan & Desa
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kecamatan', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                        SizedBox(height: 6.h),
                        InkWell(
                          onTap: _isLoadingRegions
                              ? null
                              : () {
                                  _openSearchPicker(
                                    title: 'Pilih Kecamatan',
                                    items: _kecamatanList,
                                    onSelected: (kec) {
                                      setState(() {
                                        _selectedKecamatan = kec;
                                        _selectedDesa = null;
                                      });
                                    },
                                  );
                                },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedKecamatan != null ? _selectedKecamatan!['name'] : 'Pilih Kecamatan',
                                    style: TextStyle(
                                      fontSize: 12.5.sp,
                                      color: _selectedKecamatan != null ? (isDark ? Colors.white : Colors.black) : Colors.grey,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Icon(Icons.keyboard_arrow_down_rounded, size: 18.sp, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Desa / Kelurahan', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                        SizedBox(height: 6.h),
                        InkWell(
                          onTap: _selectedKecamatan == null
                              ? () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Pilih kecamatan terlebih dahulu')),
                                  );
                                }
                              : () {
                                  final desas = _selectedKecamatan!['children'] as List<dynamic>? ?? [];
                                  _openSearchPicker(
                                    title: 'Pilih Desa / Kelurahan',
                                    items: desas,
                                    onSelected: (desa) {
                                      setState(() => _selectedDesa = desa);
                                    },
                                  );
                                },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _selectedDesa != null ? _selectedDesa!['name'] : 'Pilih Desa',
                                    style: TextStyle(
                                      fontSize: 12.5.sp,
                                      color: _selectedDesa != null ? (isDark ? Colors.white : Colors.black) : Colors.grey,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Icon(Icons.keyboard_arrow_down_rounded, size: 18.sp, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              // Detail Alamat
              Text('Detail Alamat *', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569))),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _detailController,
                maxLines: 2,
                style: TextStyle(fontSize: 13.sp),
                decoration: _inputDecoration('Nama jalan, nomor rumah, dusun', isDark),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Detail alamat wajib diisi' : null,
              ),
              SizedBox(height: 14.h),

              // RT / RW / Kode Pos
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RT', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _rtController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 13.sp),
                          decoration: _inputDecoration('003', isDark),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('RW', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _rwController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 13.sp),
                          decoration: _inputDecoration('005', isDark),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Kode Pos', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569))),
                        SizedBox(height: 6.h),
                        TextFormField(
                          controller: _posController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 13.sp),
                          decoration: _inputDecoration('28712', isDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              // Patokan
              Text('Patokan (Opsional)', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569))),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _patokanController,
                style: TextStyle(fontSize: 13.sp),
                decoration: _inputDecoration('Seberang masjid, pagar hijau', isDark),
              ),
              SizedBox(height: 14.h),

              // Checkbox Jadikan Utama
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _isUtama,
                onChanged: (val) => setState(() => _isUtama = val ?? false),
                title: Text('Jadikan alamat utama', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: const Color(0xFF0284C7),
              ),
              SizedBox(height: 18.h),

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
                          : Text(isEdit ? 'Simpan Perubahan' : 'Simpan Alamat', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
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

  InputDecoration _inputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5)),
    );
  }
}
