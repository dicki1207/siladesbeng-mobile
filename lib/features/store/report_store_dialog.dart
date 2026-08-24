import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';

class ReportStoreDialog extends StatefulWidget {
  final String targetName; // Store Name or Product Name
  final String desaName;
  final bool isProduct;

  const ReportStoreDialog({
    super.key,
    required this.targetName,
    required this.desaName,
    this.isProduct = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String targetName,
    required String desaName,
    bool isProduct = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportStoreDialog(
        targetName: targetName,
        desaName: desaName,
        isProduct: isProduct,
      ),
    );
  }

  @override
  State<ReportStoreDialog> createState() => _ReportStoreDialogState();
}

class _ReportStoreDialogState extends State<ReportStoreDialog> {
  String _selectedCategory = 'Penipuan / Harga Tidak Wajar';
  final TextEditingController _descController = TextEditingController();
  final List<String> _evidencePhotos = [];

  final List<String> _categories = [
    'Penipuan / Harga Tidak Wajar',
    'Produk Tidak Layak / Berbahaya',
    'Pelayanan Kasar / Tidak Sopan di Chat',
    'Penyalahgunaan Nama BUMDes / Ilegal',
    'Toko Tidak Mengirimkan Pesanan',
    'Pelanggaran Lainnya',
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_evidencePhotos.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 2 foto screenshot/bukti.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _evidencePhotos.add(image.path));
    }
  }

  void _submitReport() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi detail penjelasan laporan.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.pop(context, true); // Close bottom sheet

    // Show Animated Success Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AnimatedSuccessDialog(
        message: 'Laporan Diterima',
        isLogout: false,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      Navigator.pop(context); // Close success dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isProduct
                            ? 'Laporkan Produk Bermasalah'
                            : 'Laporkan Toko BUMDes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Target: ${widget.targetName} (${widget.desaName})',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 1. Violation Category
            Text(
              '1. Kategori Pelanggaran',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  items: _categories.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(c, style: const TextStyle(fontSize: 12.5)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. Detail Explanation
            Text(
              '2. Detail Penjelasan Laporan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              maxLines: 3,
              style: const TextStyle(fontSize: 12.5),
              decoration: InputDecoration(
                hintText:
                    'Ceritakan secara jelas bukti/masalah yang Anda alami dengan toko/produk ini...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.grey[500],
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white10 : const Color(0xFFCBD5E1),
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

            const SizedBox(height: 14),

            // 3. Evidence Screenshots
            Text(
              '3. Unggah Screenshot / Bukti Foto (Opsional)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 20,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_evidencePhotos.length}/2',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 58,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _evidencePhotos.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(_evidencePhotos[i]),
                                width: 58,
                                height: 58,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _evidencePhotos.removeAt(i)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Official PMD Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.security_rounded,
                    size: 18,
                    color: Color(0xFF0284C7),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Laporan Anda akan ditinjau langsung oleh Admin Pemerintah Desa & Tim Pengawas PMD Kabupaten Bengkalis secara rahasia.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        color: Color(0xFF0369A1),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _submitReport,
                icon: const Icon(
                  Icons.report_problem_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  'Kirim Laporan Pengaduan',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
