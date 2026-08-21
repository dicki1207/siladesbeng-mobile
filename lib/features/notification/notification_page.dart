import 'dart:convert';
import 'package:flutter/material.dart';
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
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Semua notifikasi ditandai sudah dibaca'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFDC2626),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hapus Semua?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Semua notifikasi Anda (kecuali pengumuman sistem) akan dihapus secara permanen.',
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF475569),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
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
                borderRadius: BorderRadius.circular(10),
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
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Semua notifikasi berhasil dihapus'),
              ],
            ),
            backgroundColor: const Color(0xFF0EA5E9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifikasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)))
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              color: const Color(0xFF0EA5E9),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                children: [
                  // Header Info Section (Matches Web Gradient & Subtitle)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF115789), Color(0xFF38BDF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF115789).withAlpha(40),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pusat Notifikasi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _unreadCount > 0
                                    ? 'Ada $_unreadCount notifikasi baru belum dibaca'
                                    : 'Semua notifikasi sudah dibaca',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(220),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Action Buttons: Tandai Semua & Hapus Semua (Matches Web Action Buttons)
                  Row(
                    children: [
                      if (_unreadCount > 0)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _markAllAsRead,
                            icon: Icon(Icons.done_all_rounded, size: 16),
                            label: Text(
                              'Tandai Semua Dibaca',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0EA5E9),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      if (_unreadCount > 0 && _notifications.isNotEmpty)
                        const SizedBox(width: 8),
                      if (_notifications.isNotEmpty)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showDeleteConfirmDialog,
                            icon: Icon(Icons.delete_outline_rounded, size: 16),
                            label: Text(
                              'Hapus Semua',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEE2E2),
                              foregroundColor: const Color(0xFFDC2626),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          'Semua (${_notifications.length})',
                          'all',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          'Belum Dibaca ($_unreadCount)',
                          'unread',
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip('Pesan Admin', 'pesan_admin'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Status & Transaksi', 'status'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0EA5E9)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
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
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 54,
              color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum Ada Notifikasi',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Notifikasi dan pesan dari admin desa akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: notif.isRead
            ? (isDark ? const Color(0xFF1E293B) : Colors.white)
            : (isDark ? const Color(0xFF334155) : const Color(0xFFF0F9FF)),
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDetail(notif),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Thumbnail Image OR Type Icon
                if (imageUrl != null)
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
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
                          size: 26,
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
                      borderRadius: BorderRadius.circular(12),
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
                        size: 26,
                      ),
                    ),
                  ),

                const SizedBox(width: 14),

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
                                      fontSize: 14.5,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!notif.isRead) ...[
                                  const SizedBox(width: 6),
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
                          const SizedBox(width: 6),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF94A3B8),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Type Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: typeDetails['lightBg'] as Color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeDetails['label'] as String,
                          style: TextStyle(
                            color: typeDetails['textColor'] as Color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Message snippet
                      Text(
                        notif.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF475569),
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Action Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (!notif.isRead)
                            InkWell(
                              onTap: () => _markAsRead(notif.id),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF0EA5E9).withValues(alpha: 0.2)
                                      : const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check,
                                      size: 13,
                                      color: Color(0xFF0284C7),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Tandai Dibaca',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.lightBlue
                                            : const Color(0xFF0284C7),
                                        fontSize: 11,
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
                                  size: 14,
                                  color: Color(0xFF94A3B8),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Sudah Dibaca',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF94A3B8),
                                    fontSize: 11,
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
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10,
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
