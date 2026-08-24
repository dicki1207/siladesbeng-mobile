import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class TokoChatPage extends StatefulWidget {
  final String tokoName;
  final String tokoDesa;
  final String tokoKecamatan;
  final String? tokoAvatar;
  final Map<String, dynamic>? productInquiry;

  const TokoChatPage({
    super.key,
    required this.tokoName,
    required this.tokoDesa,
    required this.tokoKecamatan,
    this.tokoAvatar,
    this.productInquiry,
  });

  @override
  State<TokoChatPage> createState() => _TokoChatPageState();
}

class _TokoChatPageState extends State<TokoChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTokoTyping = false;
  bool _showProductInquiryCard = true;

  late List<Map<String, dynamic>> _messages;

  final List<String> _quickReplies = [
    'Halo, apakah stok ini masih ready?',
    'Bisa dikirim ke desa/kecamatan saya?',
    'Berapa estimasi ongkir antar-desa?',
    'Bisa bayar COD saat barang sampai?',
  ];

  @override
  void initState() {
    super.initState();
    final timeStr = DateFormat('HH:mm').format(DateTime.now());
    _messages = [
      {
        'id': 'msg_1',
        'sender': 'toko',
        'text':
            'Halo! Selamat datang di layanan chat resmi ${widget.tokoName} (${widget.tokoDesa}, ${widget.tokoKecamatan}). Ada yang bisa kami bantu seputar produk atau pengiriman antar-desa kami?',
        'time': timeStr,
        'hasProduct': false,
      },
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _sendMessage({String? customText, Map<String, dynamic>? product}) {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty && product == null) return;

    final timeStr = DateFormat('HH:mm').format(DateTime.now());

    setState(() {
      _messages.add({
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
        'sender': 'user',
        'text': text,
        'time': timeStr,
        'product': product,
        'isRead': true,
      });
      if (customText == null) {
        _messageController.clear();
      }
      if (product != null) {
        _showProductInquiryCard = false;
      }
    });

    _scrollToBottom();
    _simulateTokoReply(text);
  }

  Future<void> _simulateTokoReply(String userQuery) async {
    setState(() => _isTokoTyping = true);

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    String replyText = 'Baik Kak! Terima kasih sudah menghubungi kami. ';
    final q = userQuery.toLowerCase();

    if (q.contains('stok') || q.contains('ready')) {
      replyText +=
          'Stok produk di toko BUMDes kami selalu ready dan siap dikemas hari ini.';
    } else if (q.contains('kirim') ||
        q.contains('kecamatan') ||
        q.contains('desa')) {
      replyText +=
          'Tentu bisa! Kami melayani pengiriman antar-desa dan antar-kecamatan dengan kurir lokal BUMDes.';
    } else if (q.contains('ongkir') || q.contains('biaya')) {
      replyText +=
          'Ongkir dalam satu desa gratis/flat Rp 5.000, untuk antar-kecamatan berkisar Rp 10.000 - Rp 15.000 sameday.';
    } else if (q.contains('cod') || q.contains('bayar')) {
      replyText +=
          'Bisa COD kak! Kakak juga bisa bayar via QRIS atau Transfer Bank saat checkout.';
    } else {
      replyText +=
          'Pesanan atau pertanyaan Kakak segera kami proses. Silakan lanjutkan pemesanan langsung di katalog toko kami ya Kak.';
    }

    final timeStr = DateFormat('HH:mm').format(DateTime.now());

    setState(() {
      _isTokoTyping = false;
      _messages.add({
        'id': 'msg_toko_${DateTime.now().millisecondsSinceEpoch}',
        'sender': 'toko',
        'text': replyText,
        'time': timeStr,
        'hasProduct': false,
      });
    });

    _scrollToBottom();
  }

  Future<void> _pickImageAttachment() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      final timeStr = DateFormat('HH:mm').format(DateTime.now());
      setState(() {
        _messages.add({
          'id': 'msg_img_${DateTime.now().millisecondsSinceEpoch}',
          'sender': 'user',
          'imagePath': picked.path,
          'text': '',
          'time': timeStr,
          'isRead': true,
        });
      });
      _scrollToBottom();
      _simulateTokoReply('kirim foto');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF0EA5E9);
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 1,
        titleSpacing: 0,
        title: Row(
          children: [
            // Store Avatar with Online Dot
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.storefront_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Store Name & Location
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.tokoName,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BUMDes',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${widget.tokoDesa} • ${widget.tokoKecamatan}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Profil Toko',
            onPressed: () {
              // Navigasi ke profil toko
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Pinned Product Inquiry Banner (If opened from product)
          if (widget.productInquiry != null && _showProductInquiryCard)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.productInquiry!['image_url'] != null
                        ? Image.network(
                            widget.productInquiry!['image_url'],
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 48,
                              height: 48,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.shopping_bag,
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
                          widget.productInquiry!['nama_produk'] ??
                              widget.productInquiry!['name'] ??
                              'Produk BUMDes',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currencyFormat.format(
                            widget.productInquiry!['harga'] ??
                                widget.productInquiry!['price'] ??
                                0,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0EA5E9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _sendMessage(
                        customText:
                            'Halo, saya tertarik dengan produk ${widget.productInquiry!['nama_produk'] ?? "ini"}. Apakah stoknya ready?',
                        product: widget.productInquiry,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Kirim Info',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () =>
                        setState(() => _showProductInquiryCard = false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

          // 2. Chat Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final bool isUser = msg['sender'] == 'user';
                return _buildMessageBubble(
                  msg: msg,
                  isUser: isUser,
                  isDark: isDark,
                  currencyFormat: currencyFormat,
                );
              },
            ),
          ),

          // 3. Typing Indicator
          if (_isTokoTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Admin BUMDes sedang mengetik',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // 4. Quick Reply Suggestions
          Container(
            height: 38,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _quickReplies.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final reply = _quickReplies[i];
                return ActionChip(
                  label: Text(
                    reply,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF0369A1),
                    ),
                  ),
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE0F2FE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isDark ? Colors.white12 : const Color(0xFFBAE6FD),
                    ),
                  ),
                  onPressed: () => _sendMessage(customText: reply),
                );
              },
            ),
          ),

          // 5. Chat Input Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.of(context).viewInsets.bottom + 10,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.image_outlined,
                      color: primaryColor,
                      size: 24,
                    ),
                    onPressed: _pickImageAttachment,
                    tooltip: 'Kirim Gambar',
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(fontSize: 13.5),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan ke toko BUMDes...',
                          hintStyle: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: () => _sendMessage(),
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

  Widget _buildMessageBubble({
    required Map<String, dynamic> msg,
    required bool isUser,
    required bool isDark,
    required NumberFormat currencyFormat,
  }) {
    const primaryColor = Color(0xFF0EA5E9);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? primaryColor
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Attached Product Card Inside Bubble
            if (msg['product'] != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUser
                      ? Colors.white.withValues(alpha: 0.15)
                      : (isDark
                            ? const Color(0xFF0F172A)
                            : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['product']['nama_produk'] ?? 'Produk',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            currencyFormat.format(msg['product']['harga'] ?? 0),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Attached Image
            if (msg['imagePath'] != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(msg['imagePath']),
                  width: 180,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 6),
            ],

            // Text Content
            if (msg['text'] != null && msg['text'].toString().isNotEmpty)
              Text(
                msg['text'],
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: isUser
                      ? Colors.white
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),

            const SizedBox(height: 4),

            // Time & Status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg['time'] ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    color: isUser ? Colors.white70 : const Color(0xFF94A3B8),
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all_rounded,
                    size: 13,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
