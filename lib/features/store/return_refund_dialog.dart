import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:siladesbeng_mobile/widgets/animated_success_dialog.dart';

class ReturnRefundDialog extends StatefulWidget {
  final String productName;
  final String tokoName;
  final String? orderNumber;
  final double? productPrice;
  final String? productImage;

  const ReturnRefundDialog({
    super.key,
    required this.productName,
    required this.tokoName,
    this.orderNumber,
    this.productPrice,
    this.productImage,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String productName,
    required String tokoName,
    String? orderNumber,
    double? productPrice,
    String? productImage,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReturnRefundDialog(
        productName: productName,
        tokoName: tokoName,
        orderNumber: orderNumber,
        productPrice: productPrice,
        productImage: productImage,
      ),
    );
  }

  @override
  State<ReturnRefundDialog> createState() => _ReturnRefundDialogState();
}

class _ReturnRefundDialogState extends State<ReturnRefundDialog> {
  String _selectedReason = 'Barang rusak / busuk / basi';
  String _selectedSolution = 'refund'; // 'refund' or 'replacement'
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _bankAccountController = TextEditingController();
  String _selectedBank = 'Transfer Bank (BRI)';
  final List<String> _evidencePhotos = [];

  final List<String> _reasons = [
    'Barang rusak / busuk / basi',
    'Jumlah barang kurang / tidak lengkap',
    'Barang salah kirim / berbeda varian',
    'Kadaluarsa / kemasan cacat',
    'Barang tidak sampai / salah antar',
  ];

  final List<String> _bankOptions = [
    'Transfer Bank (BRI)',
    'Transfer Bank (Riau Kepri Syariah)',
    'Transfer Bank (Mandiri)',
    'Transfer Bank (BCA)',
    'E-Wallet (DANA)',
    'E-Wallet (GoPay)',
  ];

  @override
  void dispose() {
    _descController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_evidencePhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 3 foto bukti.'),
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

  void _submitComplaint() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi penjelasan kendala barang.'),
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
        message: 'Komplain Terkirim',
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
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.assignment_return_rounded,
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
                        'Ajukan Pengembalian & Komplain',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Jaminan perlindungan konsumen BUMDes',
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

            const SizedBox(height: 14),

            // Product & Store Card Preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
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
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 48,
                              height: 48,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
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
                          '${widget.tokoName} ${widget.orderNumber != null ? "• #${widget.orderNumber}" : ""}',
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

            const SizedBox(height: 18),

            // 1. Reason Selection
            Text(
              '1. Alasan Pengembalian / Kendala Barang',
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
                  value: _selectedReason,
                  isExpanded: true,
                  dropdownColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  items: _reasons.map((r) {
                    return DropdownMenuItem(
                      value: r,
                      child: Text(r, style: const TextStyle(fontSize: 12.5)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedReason = val);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. Desired Solution (Refund vs Replacement)
            Text(
              '2. Solusi yang Diharapkan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSolution = 'refund'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedSolution == 'refund'
                            ? primaryColor.withValues(alpha: 0.12)
                            : (isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedSolution == 'refund'
                              ? primaryColor
                              : (isDark
                                    ? Colors.white10
                                    : const Color(0xFFCBD5E1)),
                          width: _selectedSolution == 'refund' ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.monetization_on_rounded,
                            size: 22,
                            color: _selectedSolution == 'refund'
                                ? primaryColor
                                : Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kembalikan Dana',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _selectedSolution == 'refund'
                                  ? primaryColor
                                  : (isDark
                                        ? Colors.white70
                                        : Colors.grey[700]),
                            ),
                          ),
                          Text(
                            '(Refund Uang)',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white54 : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedSolution = 'replacement'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedSolution == 'replacement'
                            ? const Color(0xFF10B981).withValues(alpha: 0.12)
                            : (isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedSolution == 'replacement'
                              ? const Color(0xFF10B981)
                              : (isDark
                                    ? Colors.white10
                                    : const Color(0xFFCBD5E1)),
                          width: _selectedSolution == 'replacement' ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cached_rounded,
                            size: 22,
                            color: _selectedSolution == 'replacement'
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ganti Barang Baru',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _selectedSolution == 'replacement'
                                  ? const Color(0xFF10B981)
                                  : (isDark
                                        ? Colors.white70
                                        : Colors.grey[700]),
                            ),
                          ),
                          Text(
                            '(Kirim Ulang)',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white54 : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_selectedSolution == 'refund') ...[
              const SizedBox(height: 14),
              Text(
                'Rekening / E-Wallet Tujuan Pengembalian',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBank,
                    isExpanded: true,
                    dropdownColor: isDark
                        ? const Color(0xFF1E293B)
                        : Colors.white,
                    items: _bankOptions.map((b) {
                      return DropdownMenuItem(
                        value: b,
                        child: Text(b, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedBank = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bankAccountController,
                style: const TextStyle(fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: 'Nomor Rekening / Nomor HP DANA/GoPay...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.grey[500],
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white10 : const Color(0xFFCBD5E1),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 3. Explanation
            Text(
              '3. Penjelasan Kendala',
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
                    'Jelaskan kondisi barang saat diterima (misal: barang rusak di bagian kemasan, sayur layu, dll)...',
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

            // 4. Evidence Photos
            Text(
              '4. Unggah Foto Bukti Barang (Maks. 3)',
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
                          Icons.add_a_photo_outlined,
                          size: 20,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_evidencePhotos.length}/3',
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

            const SizedBox(height: 22),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _submitComplaint,
                icon: const Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  'Kirim Pengajuan Komplain',
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
