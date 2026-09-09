import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:siladesbeng_mobile/services/news_service.dart';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';

class CreateNewsPage extends StatefulWidget {
  final String? initialCategory;

  const CreateNewsPage({
    super.key,
    this.initialCategory,
  });

  @override
  State<CreateNewsPage> createState() => _CreateNewsPageState();
}

class _CreateNewsPageState extends State<CreateNewsPage> {
  final _formKey = GlobalKey<FormState>();
  final NewsService _newsService = NewsService();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String _selectedCategory = 'Berita';
  File? _selectedImage;
  bool _isSubmitting = false;
  DateTime? _rawDate;

  final List<Map<String, dynamic>> _categories = [
    {
      'label': 'Berita',
      'icon': Icons.newspaper_rounded,
      'color': Color(0xFF2563EB),
      'desc': 'Kabar & liputan warga',
    },
    {
      'label': 'Kegiatan',
      'icon': Icons.festival_rounded,
      'color': Color(0xFF10B981),
      'desc': 'Acara, lomba, & sosial',
    },
    {
      'label': 'Artikel',
      'icon': Icons.article_rounded,
      'color': Color(0xFF8B5CF6),
      'desc': 'Informasi & edukasi desa',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null &&
        _categories.any((c) => c['label'] == widget.initialCategory)) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil gambar: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showImageSourcePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih Sumber Foto',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.camera);
                    },
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.camera_alt_rounded,
                              size: 32.sp, color: const Color(0xFF2563EB)),
                          SizedBox(height: 8.h),
                          Text(
                            'Kamera',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickImage(ImageSource.gallery);
                    },
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.photo_library_rounded,
                              size: 32.sp, color: const Color(0xFF10B981)),
                          SizedBox(height: 8.h),
                          Text(
                            'Galeri HP',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _rawDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _rawDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitNews() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final result = await _newsService.createNews(
      title: _titleController.text.trim(),
      type: _selectedCategory,
      description: _descController.text.trim(),
      location: _locationController.text.trim().isNotEmpty
          ? _locationController.text.trim()
          : null,
      eventDate: _dateController.text.trim().isNotEmpty
          ? _dateController.text.trim()
          : null,
      imagePath: _selectedImage?.path,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AnimatedSuccessDialog(
          message: 'Berita Berhasil Dipublikasikan!',
          subMessage:
              'Kabar dari lingkungan Anda kini dapat dibaca oleh seluruh warga.',
          isLogout: false,
        ),
      ).then((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(result['message'] ?? 'Gagal menerbitkan berita'),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Tulis Berita Daerah',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.5.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Citizen Journalism Pengurus RT & RW',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11.sp,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
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
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: cardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 50.h,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitNews,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 2,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 18),
                        SizedBox(width: 8.w),
                        Text(
                          'Terbitkan Berita Sekarang',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(18.w),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Info Banner
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.verified_rounded,
                          size: 18.sp, color: const Color(0xFF2563EB)),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Publikasi Wilayah Resmi',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'Berita yang Anda tulis akan tayang di portal Kabar Daerah warga dan dimoderasi secara terpusat oleh Admin Desa.',
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              color: isDark ? Colors.white70 : Colors.black87,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // 2. Kategori Berita
              Text(
                'Kategori Berita *',
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['label'];
                  final color = cat['color'] as Color;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = cat['label'] as String;
                          });
                        },
                        borderRadius: BorderRadius.circular(14.r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.12)
                                : cardBg,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: isSelected ? color : borderColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                cat['icon'] as IconData,
                                color: isSelected ? color : Colors.grey,
                                size: 22.sp,
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                cat['label'] as String,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? color
                                      : (isDark
                                          ? Colors.white70
                                          : const Color(0xFF475569)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: 20.h),

              // 3. Judul Berita
              Text(
                'Judul Berita *',
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _titleController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul berita tidak boleh kosong';
                  }
                  if (val.trim().length < 5) {
                    return 'Judul minimal 5 karakter';
                  }
                  return null;
                },
                style: TextStyle(
                  fontSize: 13.5.sp,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Contoh: Warga RT 02 Adakan Kerja Bakti Lingkungan...',
                  hintStyle: TextStyle(
                    fontSize: 12.5.sp,
                    color: isDark ? Colors.white38 : Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(
                        color: Color(0xFF2563EB), width: 1.5),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                ),
              ),

              SizedBox(height: 18.h),

              // 4. Lokasi & Tanggal (2 Kolom)
              Row(
                children: [
                  // Lokasi
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lokasi (Opsional)',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        TextFormField(
                          controller: _locationController,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Pos Ronda / Balai...',
                            prefixIcon: Icon(Icons.place_rounded,
                                size: 18.sp, color: Colors.grey),
                            filled: true,
                            fillColor: cardBg,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 12.h),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Tanggal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggal Kejadian',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(14.r),
                          child: IgnorePointer(
                            child: TextFormField(
                              controller: _dateController,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Pilih Tanggal',
                                prefixIcon: Icon(Icons.calendar_month_rounded,
                                    size: 18.sp, color: Colors.grey),
                                filled: true,
                                fillColor: cardBg,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12.w, vertical: 12.h),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 18.h),

              // 5. Upload Foto Dokumentasi
              Text(
                'Foto Dokumentasi Berita',
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 8.h),
              if (_selectedImage != null)
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 180.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        image: DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: borderColor),
                      ),
                    ),
                    Positioned(
                      top: 10.h,
                      right: 10.w,
                      child: InkWell(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.85),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 18.sp, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                )
              else
                InkWell(
                  onTap: _showImageSourcePicker,
                  borderRadius: BorderRadius.circular(16.r),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 24.h),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: borderColor,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB)
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_a_photo_rounded,
                            size: 26.sp,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          'Upload Foto Dokumentasi (Opsional)',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Ambil dari kamera atau galeri smartphone',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isDark ? Colors.white38 : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: 20.h),

              // 6. Isi Berita
              Text(
                'Isi Berita Lengkap *',
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _descController,
                maxLines: 8,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Isi berita tidak boleh kosong';
                  }
                  if (val.trim().length < 15) {
                    return 'Isi berita terlalu pendek (minimal 15 karakter)';
                  }
                  return null;
                },
                style: TextStyle(
                  fontSize: 13.5.sp,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.45,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Tuliskan liputan atau detail kegiatan yang dilaksanakan di lingkungan warga...',
                  hintStyle: TextStyle(
                    fontSize: 12.5.sp,
                    color: isDark ? Colors.white38 : Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: const BorderSide(
                        color: Color(0xFF2563EB), width: 1.5),
                  ),
                  contentPadding: EdgeInsets.all(16.w),
                ),
              ),

              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }
}
