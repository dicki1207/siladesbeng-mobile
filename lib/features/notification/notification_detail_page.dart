import 'package:flutter/material.dart';
import 'package:siladesbeng_mobile/widgets/custom_cached_image.dart';
import 'package:intl/intl.dart';
import 'package:siladesbeng_mobile/features/notification/models/notification_model.dart';

class NotificationDetailPage extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailPage({super.key, required this.notification});

  // Helper for Type Info (Gradient, Icon, Label)
  Map<String, dynamic> _getTypeDetails(
    String? type,
    String title,
    String message,
  ) {
    final lowerTitle = title.toLowerCase();
    final lowerMessage = message.toLowerCase();
    final isRejected =
        lowerTitle.contains('ditolak') || lowerMessage.contains('ditolak');

    switch (type) {
      case 'pesan_admin':
        return {
          'label': 'Pesan Admin',
          'icon': Icons.admin_panel_settings_rounded,
          'gradient': const [Color(0xFF9333EA), Color(0xFFC084FC)],
          'lightBg': const Color(0xFFF3E8FF),
          'textColor': const Color(0xFF7E22CE),
        };
      case 'status_berubah':
      case 'status_update':
        if (isRejected) {
          return {
            'label': 'Status Ditolak',
            'icon': Icons.cancel_rounded,
            'gradient': const [Color(0xFFDC2626), Color(0xFFF87171)],
            'lightBg': const Color(0xFFFEE2E2),
            'textColor': const Color(0xFFB91C1C),
          };
        }
        return {
          'label': 'Status Berubah',
          'icon': Icons.check_circle_rounded,
          'gradient': const [Color(0xFF10B981), Color(0xFF34D399)],
          'lightBg': const Color(0xFFD1FAE5),
          'textColor': const Color(0xFF047857),
        };
      case 'delivery_proof':
        return {
          'label': 'Bukti Pengiriman',
          'icon': Icons.local_shipping_rounded,
          'gradient': const [Color(0xFF3B82F6), Color(0xFF06B6D4)],
          'lightBg': const Color(0xFFE0F2FE),
          'textColor': const Color(0xFF0369A1),
        };
      case 'cancellation_approved':
        return {
          'label': 'Pembatalan Disetujui',
          'icon': Icons.warning_amber_rounded,
          'gradient': const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
          'lightBg': const Color(0xFFFEF3C7),
          'textColor': const Color(0xFFB45309),
        };
      case 'cancellation_rejected':
        return {
          'label': 'Pembatalan Ditolak',
          'icon': Icons.cancel_outlined,
          'gradient': const [Color(0xFFDC2626), Color(0xFFF87171)],
          'lightBg': const Color(0xFFFEE2E2),
          'textColor': const Color(0xFFB91C1C),
        };
      case 'pengajuan_selesai':
      case 'pembayaran_masuk':
        return {
          'label': 'Transaksi Sukses',
          'icon': Icons.verified_rounded,
          'gradient': const [Color(0xFF0D9488), Color(0xFF14B8A6)],
          'lightBg': const Color(0xFFCCFBF1),
          'textColor': const Color(0xFF0F766E),
        };
      default:
        return {
          'label': 'Informasi',
          'icon': Icons.notifications_active_rounded,
          'gradient': const [Color(0xFF3B82F6), Color(0xFF6366F1)],
          'lightBg': const Color(0xFFEEF2FF),
          'textColor': const Color(0xFF4338CA),
        };
    }
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(220),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              clipBehavior: Clip.none,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomCachedImage(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(20),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    child: Text(
                      'Gagal memuat gambar preview.',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: Icon(
                  Icons.close,
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  size: 28,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withAlpha(120),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeDetails = _getTypeDetails(
      notification.type,
      notification.title,
      notification.message,
    );

    final String formattedDate = DateFormat(
      'dd MMM yyyy, HH:mm',
      'id_ID',
    ).format(notification.createdAt);

    final imageUrl = notification.fullImageUrl;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Detail Pesan & Notifikasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Utama Detail
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withAlpha(50)
                        : const Color(0xFF64748B).withAlpha(15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Type Badge + Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: typeDetails['lightBg'] as Color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              typeDetails['icon'] as IconData,
                              size: 16,
                              color: typeDetails['textColor'] as Color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              typeDetails['label'] as String,
                              style: TextStyle(
                                color: typeDetails['textColor'] as Color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$formattedDate WIB',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF94A3B8),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Header with Icon & Title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: typeDetails['gradient'] as List<Color>,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: (typeDetails['gradient'] as List<Color>)
                                  .first
                                  .withAlpha(80),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            typeDetails['icon'] as IconData,
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  notification.isRead
                                      ? Icons.done_all_rounded
                                      : Icons.fiber_manual_record,
                                  size: 14,
                                  color: notification.isRead
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF3B82F6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  notification.isRead
                                      ? 'Sudah Dibaca'
                                      : 'Pesan Baru',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: notification.isRead
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                  const SizedBox(height: 16),

                  // Image Attachment (if exists)
                  if (imageUrl != null) ...[
                    GestureDetector(
                      onTap: () => _showImagePreview(context, imageUrl),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 260),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white12
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CustomCachedImage(
                              imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 180,
                                      color: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFF1F5F9),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF0EA5E9),
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 120,
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF8FAFC),
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image_rounded,
                                            color: isDark
                                                ? Colors.white54
                                                : Colors.grey,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Gagal memuat gambar',
                                            style: TextStyle(
                                              color: isDark
                                                  ? Colors.white54
                                                  : Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            ),
                            Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(150),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.zoom_in_rounded,
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Perbesar',
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Message Content Body
                  Text(
                    'Isi Pesan:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        height: 1.6,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Info Card Sila-DesBeng
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                      : const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFBFDBFE),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.blue[300]!
                          : const Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sistem Informasi Sila-DesBeng',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E3A8A),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pesan resmi dari Pemerintah Desa / Administrator Sistem.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? Colors.blue[300]!
                                : const Color(0xFF3B82F6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
