import 'package:siladesbeng_mobile/core/api_config.dart';

class NotificationModel {
  final int id;
  final String title;
  final String message;
  final String? type;
  final String? image;
  final String? link;
  final int? laporanId;
  final int? adminId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.type,
    this.image,
    this.link,
    this.laporanId,
    this.adminId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  String? get fullImageUrl {
    if (image == null || image!.trim().isEmpty) return null;
    if (image!.startsWith('http://') || image!.startsWith('https://')) {
      return image;
    }
    final cleanPath = image!.startsWith('/') ? image!.substring(1) : image;
    return '${ApiConfig.baseUrl}/storage/$cleanPath';
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'],
      image: json['image'],
      link: json['link'],
      laporanId: json['laporan_id'] != null ? int.tryParse(json['laporan_id'].toString()) : null,
      adminId: json['admin_id'] != null ? int.tryParse(json['admin_id'].toString()) : null,
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == '1',
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at'].toString()) : null,
      createdAt: json['created_at'] != null 
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    String? image,
    String? link,
    int? laporanId,
    int? adminId,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      image: image ?? this.image,
      link: link ?? this.link,
      laporanId: laporanId ?? this.laporanId,
      adminId: adminId ?? this.adminId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

