import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siladesbeng_mobile/services/unit_chat_service.dart';

class UnitServiceChatPage extends StatefulWidget {
  final String serviceType; // 'gas', 'penyewaan', 'mobil', 'fasilitas_umum'
  final String title;
  final String? itemInquiry;
  final int? regionId;

  const UnitServiceChatPage({
    super.key,
    required this.serviceType,
    required this.title,
    this.itemInquiry,
    this.regionId,
  });

  @override
  State<UnitServiceChatPage> createState() => _UnitServiceChatPageState();
}

class _UnitServiceChatPageState extends State<UnitServiceChatPage> {
  final UnitChatService _chatService = UnitChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isEscalated = false;
  Timer? _pollTimer;

  late List<String> _quickReplies;

  @override
  void initState() {
    super.initState();
    _initQuickReplies();
    _fetchChatHistory();
    _startPolling();
  }

  void _initQuickReplies() {
    switch (widget.serviceType) {
      case 'gas':
        _quickReplies = [
          'Stok tabung ready hari ini?',
          'Bisa diantar ke rumah?',
          'Bagaimana cara tukar tabung?',
        ];
        break;
      case 'penyewaan':
        _quickReplies = [
          'Apakah alat siap pakai?',
          'Berapa tarif sewa per hari?',
          'Ketentuan SOP tanggung jawab sewa?',
        ];
        break;
      case 'mobil':
        _quickReplies = [
          'Armada mobil tersedia?',
          'Bisa lepas kunci atau dengan supir?',
          'Syarat dokumen apa saja?',
        ];
        break;
      case 'fasilitas_umum':
        _quickReplies = [
          'Jadwal gedung kosong kapan?',
          'Berapa kapasitas gedung?',
          'Prosedur peminjaman fasilitas?',
        ];
        break;
      default:
        _quickReplies = [
          'Halo admin, saya ingin bertanya.',
          'Ketersediaan layanan ini?',
        ];
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        _fetchChatHistory(isSilent: true);
      }
    });
  }

  Future<void> _fetchChatHistory({bool isSilent = false}) async {
    if (!isSilent && _messages.isEmpty) {
      setState(() => _isLoading = true);
    }

    final res = await _chatService.getChatHistory(
      widget.serviceType,
      regionId: widget.regionId,
    );

    if (!mounted) return;

    if (res['status'] == 'success' && res['data'] != null) {
      final fetchedMessages = res['data']['messages'] ?? [];
      final isEsc = res['data']['is_escalated'] ?? false;

      setState(() {
        _messages = fetchedMessages;
        _isEscalated = isEsc;
        _isLoading = false;
      });

      if (!isSilent) {
        _scrollToBottom();
      }
    } else {
      if (!isSilent) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = (customText ?? _messageController.text).trim();
    if (text.isEmpty) return;

    if (customText == null) {
      _messageController.clear();
    }

    // Push local dummy message for instant visual responsiveness
    final now = DateTime.now();
    setState(() {
      _messages.add({
        'id': 'temp_${now.millisecondsSinceEpoch}',
        'sender_type': 'user',
        'message': text,
        'created_at': now.toIso8601String(),
      });
    });
    _scrollToBottom();

    final res = await _chatService.sendChatMessage(
      widget.serviceType,
      text,
      regionId: widget.regionId,
      itemReference: widget.itemInquiry,
    );

    if (!mounted) return;

    if (res['status'] == 'success' && res['data'] != null) {
      if (res['data']['bot_message'] != null) {
        setState(() {
          _messages.add(res['data']['bot_message']);
        });
        _scrollToBottom();
      }
      if (res['data']['is_escalated'] == true) {
        setState(() => _isEscalated = true);
      }
    }
  }

  Future<void> _escalateToAdmin() async {
    final res = await _chatService.escalateChat(
      widget.serviceType,
      regionId: widget.regionId,
    );

    if (!mounted) return;

    if (res['status'] == 'success' && res['data'] != null) {
      setState(() {
        _isEscalated = true;
        if (res['data']['bot_message'] != null) {
          _messages.add(res['data']['bot_message']);
        }
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF0EA5E9);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF0F172A)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getServiceIcon(widget.serviceType),
                color: primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isEscalated ? 'Terhubung Petugas Desa' : 'Online BUMDes',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!_isEscalated)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _escalateToAdmin,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF0FDF4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFF86EFAC)),
                  ),
                ),
                icon: const Icon(Icons.support_agent_rounded, size: 16, color: Color(0xFF166534)),
                label: const Text(
                  'Petugas',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Privacy Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Privasi Terjaga: Komunikasi internal aman tanpa nomor HP',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : const Color(0xFF166534),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Inquiry Item Reference Banner (jika ada)
          if (widget.itemInquiry != null && widget.itemInquiry!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                border: Border(
                  bottom: BorderSide(color: primaryColor.withValues(alpha: 0.15)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.bookmark_outline_rounded, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Menanyakan produk/item: ${widget.itemInquiry}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Quick Replies Row
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                if (!_isEscalated)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      onPressed: _escalateToAdmin,
                      avatar: const Icon(Icons.support_agent_rounded, size: 14, color: Colors.white),
                      label: const Text(
                        'Chat Petugas Admin',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ..._quickReplies.map((chip) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      onPressed: () => _sendMessage(chip),
                      label: Text(
                        chip,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      side: BorderSide(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // Message Stream
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'Mulai percakapan dengan petugas layanan',
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildMessageBubble(msg, isDark, primaryColor);
                        },
                      ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _messageController,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tulis pesan...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _sendMessage(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic msg, bool isDark, Color primaryColor) {
    final senderType = msg['sender_type'] ?? 'user';
    final text = msg['message'] ?? '';
    final createdAt = msg['created_at'] != null ? DateTime.tryParse(msg['created_at']) : null;
    final timeStr = createdAt != null ? DateFormat('HH:mm').format(createdAt.toLocal()) : '';

    if (senderType == 'user') {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                text,
                style: const TextStyle(fontSize: 13.5, color: Colors.white, height: 1.35),
              ),
              if (timeStr.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    timeStr,
                    style: TextStyle(fontSize: 9.5, color: Colors.white.withValues(alpha: 0.7)),
                  ),
                ),
            ],
          ),
        ),
      );
    } else if (senderType == 'admin') {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, right: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_rounded, size: 12, color: primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    'Petugas BUMDes',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  height: 1.35,
                ),
              ),
              if (timeStr.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    } else {
      // Bot message
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFBAE6FD),
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white70 : const Color(0xFF0369A1),
              height: 1.35,
            ),
          ),
        ),
      );
    }
  }

  IconData _getServiceIcon(String service) {
    switch (service) {
      case 'gas':
        return Icons.local_gas_station_rounded;
      case 'penyewaan':
        return Icons.handyman_rounded;
      case 'mobil':
        return Icons.directions_car_rounded;
      case 'fasilitas_umum':
        return Icons.apartment_rounded;
      default:
        return Icons.chat_rounded;
    }
  }
}
