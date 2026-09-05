import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siladesbeng_mobile/services/unit_chat_service.dart';

class UnitServiceChatPage extends StatefulWidget {
  final String serviceType; // 'gas', 'penyewaan', 'mobil', 'fasilitas_umum'
  final String title;
  final String? itemInquiry;
  final String? itemImage;
  final String? itemPrice;
  final String? itemUnit;
  final int? regionId;

  const UnitServiceChatPage({
    super.key,
    required this.serviceType,
    required this.title,
    this.itemInquiry,
    this.itemImage,
    this.itemPrice,
    this.itemUnit,
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
  bool _showItemInquiryCard = true;
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

    if (widget.itemInquiry != null && widget.itemInquiry!.isNotEmpty) {
      _quickReplies.insert(0, 'Apakah ${widget.itemInquiry} ready?');
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

      setState(() {
        _messages = fetchedMessages;
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

  Future<void> _sendMessage([String? customText, Map<String, dynamic>? itemData]) async {
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
        'item_data': itemData,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF0EA5E9);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFF2563EB),
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
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(22),
                ),
              ),
            ),
            // Glowing circle 2 (Bottom Left)
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withAlpha(80),
                  width: 1.5,
                ),
              ),
              child: Icon(
                _getServiceIcon(widget.serviceType),
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
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
                        'Petugas BUMDes Online',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withAlpha(210),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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

          // Inquiry Item Card Banner (Mengikutsertakan Gambar Barang)
          if (widget.itemInquiry != null && widget.itemInquiry!.isNotEmpty && _showItemInquiryCard)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Thumbnail Image Barang
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildItemImageWidget(widget.itemImage, 48, 48),
                  ),
                  const SizedBox(width: 10),
                  // Info Barang: Nama & Tarif / Harga
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.itemInquiry!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        if (widget.itemPrice != null && widget.itemPrice!.isNotEmpty) ...[
                          Builder(
                            builder: (_) {
                              final numVal = double.tryParse(widget.itemPrice!);
                              final priceText = numVal != null
                                  ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(numVal)
                                  : widget.itemPrice!;
                              final unitText = widget.itemUnit != null && widget.itemUnit!.isNotEmpty
                                  ? ' ${widget.itemUnit}'
                                  : '';
                              return Text(
                                '$priceText$unitText',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0284C7),
                                ),
                              );
                            },
                          ),
                        ] else ...[
                          Text(
                            'Layanan Desa',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol Tanya Item
                  ElevatedButton.icon(
                    onPressed: () {
                      _sendMessage(
                        'Halo admin, apakah ${widget.itemInquiry} saat ini masih tersedia?',
                        {
                          'name': widget.itemInquiry,
                          'image': widget.itemImage,
                          'price': widget.itemPrice,
                          'unit': widget.itemUnit,
                        },
                      );
                      setState(() => _showItemInquiryCard = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 12, color: Colors.white),
                    label: const Text(
                      'Tanya Item',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Close Button
                  GestureDetector(
                    onTap: () => setState(() => _showItemInquiryCard = false),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: isDark ? Colors.white38 : Colors.grey[400],
                      ),
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
                ..._quickReplies.map((chip) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      onPressed: () {
                        final isItemQuestion = widget.itemInquiry != null && chip.contains(widget.itemInquiry!);
                        _sendMessage(
                          chip,
                          isItemQuestion
                              ? {
                                  'name': widget.itemInquiry,
                                  'image': widget.itemImage,
                                  'price': widget.itemPrice,
                                  'unit': widget.itemUnit,
                                }
                              : null,
                        );
                        if (isItemQuestion) {
                          setState(() => _showItemInquiryCard = false);
                        }
                      },
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
              if (msg['item_data'] != null) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: _buildItemImageWidget(msg['item_data']['image'], 42, 42),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['item_data']['name'] ?? 'Item Layanan',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (msg['item_data']['price'] != null) ...[
                              const SizedBox(height: 2),
                              Builder(
                                builder: (_) {
                                  final numVal = double.tryParse(msg['item_data']['price'].toString());
                                  final priceText = numVal != null
                                      ? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(numVal)
                                      : msg['item_data']['price'].toString();
                                  final unitText = msg['item_data']['unit'] != null && msg['item_data']['unit'].toString().isNotEmpty
                                      ? ' ${msg['item_data']['unit']}'
                                      : '';
                                  return Text(
                                    '$priceText$unitText',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFE0F2FE),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  Widget _buildItemImageWidget(String? imgPath, double width, double height) {
    if (imgPath == null || imgPath.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: Icon(
          _getServiceIcon(widget.serviceType),
          size: width * 0.5,
          color: Colors.grey[500],
        ),
      );
    }
    if (imgPath.startsWith('assets/')) {
      return Image.asset(
        imgPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imgPath,
      width: width,
      height: height,
      fit: BoxFit.cover,
      memCacheWidth: 500,
      placeholder: (ctx, url) => Container(color: Colors.grey[200]),
      errorWidget: (ctx, url, err) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
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
