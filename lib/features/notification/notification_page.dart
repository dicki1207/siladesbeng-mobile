import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';
import 'package:siladesbeng_mobile/features/notification/models/notification_model.dart';
import 'package:siladesbeng_mobile/features/notification/notification_detail_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'unread', 'pesan_admin', 'status'

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('auth_token');
      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List rawList = data['data']['notifications'] ?? [];
          setState(() {
            _notifications = rawList
                .map((item) => NotificationModel.fromJson(item))
                .toList();
            _unreadCount =
                data['data']['unreadCount'] ??
                _notifications.where((n) => !n.isRead).length;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(int id, {bool silent = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('auth_token');
      if (token == null) return;

      // Optimistic update locally
      setState(() {
        final idx = _notifications.indexWhere((n) => n.id == id);
        if (idx != -1 && !_notifications[idx].isRead) {
          _notifications[idx] = _notifications[idx].copyWith(isRead: true);
          if (_unreadCount > 0) _unreadCount--;
        }
      });

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/$id/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200 && !silent) {
        _fetchNotifications();
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('auth_token');
      if (token == null) return;

      // Optimistic update locally
      setState(() {
        _notifications = _notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();
        _unreadCount = 0;
      });

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/read-all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
                SizedBox(width: 8.w),
                Text('Semua notifikasi ditandai sudah dibaca'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      } else {
        _fetchNotifications();
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> _showDeleteConfirmDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFDC2626),
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'Hapus Semua?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
              ),
            ),
          ],
        ),
        content: Text(
          'Semua notifikasi Anda (kecuali pengumuman sistem) akan dihapus secara permanen.',
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF475569),
            fontSize: 14.sp,
            height: 1.4,
          ),
        ),
        actionsPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Batal',
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: Text(
              'Ya, Hapus Semua',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteAll();
    }
  }

  Future<void> _deleteAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('auth_token');
      if (token == null) return;

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/delete-all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
                SizedBox(width: 8.w),
                Text('Semua notifikasi berhasil dihapus'),
              ],
            ),
            backgroundColor: const Color(0xFF0EA5E9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
        _fetchNotifications();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus notifikasi.')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting notifications: $e');
    }
  }

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

  void _openDetail(NotificationModel notif) {
    if (!notif.isRead) {
      _markAsRead(notif.id, silent: true);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationDetailPage(notification: notif),
      ),
    ).then((_) => _fetchNotifications());
  }

  List<NotificationModel> get _filteredNotifications {
    if (_selectedFilter == 'unread') {
      return _notifications.where((n) => !n.isRead).toList();
    } else if (_selectedFilter == 'pesan_admin') {
      return _notifications.where((n) => n.type == 'pesan_admin').toList();
    } else if (_selectedFilter == 'status') {
      return _notifications.where((n) => n.type != 'pesan_admin').toList();
    }
    return _notifications;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1120)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Notifikasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFF2FA2F1),
        foregroundColor: Colors.white,
        elevation: 0,
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
            // Glowing circle 1 (Top Right)
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(22),
                ),
              ),
            ),
            // Glowing circle 2 (Bottom Left)
            Positioned(
              bottom: -25,
              left: -15,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(14),
                ),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all_rounded, color: Colors.white),
              tooltip: 'Tandai Semua Dibaca',
              onPressed: _markAllAsRead,
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
              ),
              tooltip: 'Hapus Semua',
              onPressed: _showDeleteConfirmDialog,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              color: const Color(0xFF2563EB),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                children: [
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'Semua (${_notifications.length})',
                          'all',
                        ),
                        SizedBox(width: 8.w),
                        _buildFilterChip(
                          'Belum Dibaca ($_unreadCount)',
                          'unread',
                        ),
                        SizedBox(width: 8.w),
                        _buildFilterChip('Pesan Admin', 'pesan_admin'),
                        SizedBox(width: 8.w),
                        _buildFilterChip('Status & Transaksi', 'status'),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Notifications List
                  if (_filteredNotifications.isEmpty)
                    _buildEmptyState()
                  else
                    ..._filteredNotifications.map(
                      (notif) => _buildNotificationCard(notif),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0EA5E9)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0EA5E9)
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF0EA5E9).withAlpha(50),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(top: 30.h),
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 54.sp,
              color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Belum Ada Notifikasi',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Notifikasi dan pesan dari admin desa akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final typeDetails = _getTypeDetails(notif.type, notif.title, notif.message);
    final String formattedDate = DateFormat(
      'dd MMM yyyy HH:mm',
    ).format(notif.createdAt);
    final imageUrl = notif.fullImageUrl;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: notif.isRead
            ? (isDark ? const Color(0xFF1E293B) : Colors.white)
            : (isDark ? const Color(0xFF334155) : const Color(0xFFF0F9FF)),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: notif.isRead
              ? (isDark ? Colors.white12 : const Color(0xFFE2E8F0))
              : (isDark
                    ? const Color(0xFF0EA5E9).withValues(alpha: 0.5)
                    : const Color(0xFFBAE6FD)),
          width: notif.isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(50)
                : const Color(0xFF64748B).withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => _openDetail(notif),
          child: Padding(
            padding: EdgeInsets.all(14.0.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Thumbnail Image OR Type Icon
                if (imageUrl != null)
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isDark
                            ? Colors.white12
                            : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      imageUrl,
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: typeDetails['lightBg'] as Color,
                        child: Icon(
                          typeDetails['icon'] as IconData,
                          color: typeDetails['textColor'] as Color,
                          size: 26.sp,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: typeDetails['gradient'] as List<Color>,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: (typeDetails['gradient'] as List<Color>).first
                              .withAlpha(60),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        typeDetails['icon'] as IconData,
                        color: Colors.white,
                        size: 26.sp,
                      ),
                    ),
                  ),

                SizedBox(width: 14.w),

                // Right: Content Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Title + Unread Indicator + Time
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    notif.title,
                                    style: TextStyle(
                                      fontWeight: notif.isRead
                                          ? FontWeight.w600
                                          : FontWeight.bold,
                                      fontSize: 14.5.sp,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!notif.isRead) ...[
                                  SizedBox(width: 6.w),
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.lightBlue
                                          : const Color(0xFF0284C7),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF94A3B8),
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 4.h),

                      // Type Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7.w,
                          vertical: 2.5.h,
                        ),
                        decoration: BoxDecoration(
                          color: typeDetails['lightBg'] as Color,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          typeDetails['label'] as String,
                          style: TextStyle(
                            color: typeDetails['textColor'] as Color,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      SizedBox(height: 6.h),

                      // Message snippet
                      Text(
                        notif.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF475569),
                          fontSize: 12.5.sp,
                          height: 1.35,
                        ),
                      ),

                      SizedBox(height: 10.h),

                      // Action Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (!notif.isRead)
                            InkWell(
                              onTap: () => _markAsRead(notif.id),
                              borderRadius: BorderRadius.circular(6.r),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 9.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(
                                          0xFF0EA5E9,
                                        ).withValues(alpha: 0.2)
                                      : const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      size: 13.sp,
                                      color: Color(0xFF0284C7),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Tandai Dibaca',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.lightBlue
                                            : const Color(0xFF0284C7),
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.done_all_rounded,
                                  size: 14.sp,
                                  color: Color(0xFF94A3B8),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'Sudah Dibaca',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF94A3B8),
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                          // Lihat Detail Link
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lihat Detail',
                                style: TextStyle(
                                  color: Color(0xFF0EA5E9),
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10.sp,
                                color: Color(0xFF0EA5E9),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
