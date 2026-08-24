import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';

class GiveReviewDialog extends StatefulWidget {
  final String productName;
  final String tokoName;
  final String? productImage;
  final String? desaName;

  const GiveReviewDialog({
    super.key,
    required this.productName,
    required this.tokoName,
    this.productImage,
    this.desaName,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String productName,
    required String tokoName,
    String? productImage,
    String? desaName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GiveReviewDialog(
        productName: productName,
        tokoName: tokoName,
        productImage: productImage,
        desaName: desaName,
      ),
    );
  }

  @override
  State<GiveReviewDialog> createState() => _GiveReviewDialogState();
}

class _GiveReviewDialogState extends State<GiveReviewDialog> {
  int _selectedRating = 5;
  final TextEditingController _commentController = TextEditingController();
  final List<String> _selectedTags = [];
  final List<String> _imagePaths = [];

  final List<String> _availableTags = [
    '🚚 Pengiriman Cepat',
    '🥬 Kualitas Segar & Bagus',
    '💬 Admin BUMDes Ramah',
    '📦 Kemasan Rapi & Aman',
    '💰 Harga Pas & Transparan',
    '🌟 Produk Asli Desa',
  ];

  final Map<int, String> _ratingLabels = {
    1: 'Sangat Kecewa 😞',
    2: 'Kurang Puas 😐',
    3: 'Cukup Baik 🙂',
    4: 'Puas & Rekomended! 😊',
    5: 'Sangat Puas & Luar Biasa! ⭐',
  };

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_imagePaths.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 3 foto ulasan.'),
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
      setState(() => _imagePaths.add(image.path));
    }
  }

  void _submitReview() async {
    Navigator.pop(context, true); // Close bottom sheet

    // Show modern Animated Success Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AnimatedSuccessDialog(
        message: 'Ulasan Terkirim',
        isLogout: false,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      Navigator.pop(context); // Close success dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF0EA5E9);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
                const Icon(
                  Icons.rate_review_rounded,
                  color: Color(0xFFF59E0B),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Beri Ulasan & Penilaian',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Product & Store Card Preview
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.productImage != null
                        ? Image.network(
                            widget.productImage!,
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 46,
                              height: 46,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.storefront,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            width: 46,
                            height: 46,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.storefront,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.productName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.tokoName} • ${widget.desaName ?? "Desa Senggoro"}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Interactive Star Rating
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedRating = starValue),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: AnimatedScale(
                            scale: _selectedRating >= starValue ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _selectedRating >= starValue
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 40,
                              color: _selectedRating >= starValue
                                  ? const Color(0xFFF59E0B)
                                  : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _ratingLabels[_selectedRating] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Quick Feedback Tags
            Text(
              'Apa yang kamu suka dari BUMDes ini?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  selectedColor: const Color(
                    0xFFF59E0B,
                  ).withValues(alpha: 0.18),
                  backgroundColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFFD97706)
                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFF59E0B)
                        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Comment Box
            TextField(
              controller: _commentController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText:
                    'Ceritakan pengalaman belanja produk desa ini (kualitas, rasa, pengiriman, dll)...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.grey[500],
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: primaryColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),

            const SizedBox(height: 14),

            // Photo Upload
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
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 20,
                          color: primaryColor,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_imagePaths.length}/3',
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
                      itemCount: _imagePaths.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(_imagePaths[i]),
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
                                    setState(() => _imagePaths.removeAt(i)),
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

            const SizedBox(height: 22),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _submitReview,
                icon: const Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  'Kirim Ulasan BUMDes',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
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
