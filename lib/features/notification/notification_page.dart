import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';
import 'package:siladesbeng_mobile/features/notification/models/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          setState(() {
            _notifications = (data['data']['notifications'] as List)
                .map((item) => NotificationModel.fromJson(item))
                .toList();
            _unreadCount = data['data']['unreadCount'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/$id/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _fetchNotifications();
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return;

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
          const SnackBar(
            content: Text('Semua notifikasi ditandai sudah dibaca'),
          ),
        );
        _fetchNotifications();
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  Future<void> _deleteAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
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
          const SnackBar(content: Text('Semua notifikasi berhasil dihapus')),
        );
        _fetchNotifications();
      }
    } catch (e) {
      debugPrint('Error deleting notifications: $e');
    }
  }

  IconData _getIconForType(String? type) {
    if (type == null) return Icons.notifications;
    if (type.contains('selesai') || type.contains('success')) {
      return Icons.check_circle;
    }
    if (type.contains('pesanan') || type.contains('gas')) {
      return Icons.propane_tank;
    }
    return Icons.notifications;
  }

  Color _getColorForType(String? type) {
    if (type == null) return Colors.blue;
    if (type.contains('selesai') || type.contains('success')) {
      return Colors.green;
    }
    if (type.contains('pesanan') || type.contains('gas')) {
      return Colors.blueAccent;
    }
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifikasi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 1,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchNotifications,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Text(
                      'Anda memiliki $_unreadCount notifikasi belum dibaca',
                      style: TextStyle(
                        color:
                            Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color?.withAlpha(150) ??
                            Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _unreadCount > 0 ? _markAllAsRead : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Tandai Semua',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _notifications.isNotEmpty
                              ? _deleteAll
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withAlpha(20),
                            foregroundColor: Colors.red,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Hapus Semua',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_notifications.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada notifikasi',
                              style: TextStyle(
                                color:
                                    Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withAlpha(150) ??
                                    Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._notifications.map(
                      (notif) => _buildNotificationCard(notif),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notif) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(50)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getColorForType(notif.type).withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconForType(notif.type),
                color: _getColorForType(notif.type),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                notif.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!notif.isRead) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy HH:mm').format(notif.createdAt),
                        style: TextStyle(
                          color:
                              Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color?.withAlpha(150) ??
                              Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notif.message,
                    style: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!notif.isRead)
                    InkWell(
                      onTap: () => _markAsRead(notif.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Tandai Sudah Dibaca',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Sudah Dibaca',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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
