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
  bool _isEscalated = false;

  late List<Map<String, dynamic>> _messages;

  final List<Map<String, dynamic>> _quickReplyChips = [
    {
      'label': 'Chat Pengelola Toko',
      'isEscalate': true,
      'icon': Icons.support_agent_rounded,
    },
    {
      'label': 'Stok ready?',
      'isEscalate': false,
      'icon': Icons.inventory_2_outlined,
    },
    {
      'label': 'Kirim antar-desa?',
      'isEscalate': false,
      'icon': Icons.local_shipping_outlined,
    },
    {
      'label': 'Estimasi ongkir?',
      'isEscalate': false,
      'icon': Icons.payments_outlined,
    },
    {
      'label': 'Bisa bayar COD?',
      'isEscalate': false,
      'icon': Icons.account_balance_wallet_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    final timeStr = DateFormat('HH:mm').format(DateTime.now());
    _messages = [
      {
        'id': 'msg_welcome',
        'sender': 'bot',
        'text':
            'Halo! Selamat datang di layanan chat Toko BUMDes ${widget.tokoDesa}. Asisten otomatis kami siap membantu pertanyaan seputar stok, ongkir, dan pengiriman antar-desa.',
        'time': timeStr,
      },
    ];

    if (widget.productInquiry != null) {
      _showProductInquiryCard = true;
    }
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

  void _escalateToPengelola() {
    if (_isEscalated) return;

    final timeStr = DateFormat('HH:mm').format(DateTime.now());
    setState(() {
      _isEscalated = true;
      _messages.add({
        'id': 'msg_sys_${DateTime.now().millisecondsSinceEpoch}',
        'sender': 'system',
        'text':
            'Percakapan telah dialihkan ke Pengelola Toko BUMDes ${widget.tokoDesa}. Petugas toko akan segera membaca dan merespons pesan Anda di sini.',
        'time': timeStr,
      });
    });

    _scrollToBottom();
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

    if (!_isEscalated) {
      _processBotReply(text, product);
    } else {
      _simulateAdminReply();
    }
  }

  Future<void> _processBotReply(String userQuery, Map<String, dynamic>? product) async {
    setState(() => _isTokoTyping = true);

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    String replyText = '';
    final q = userQuery.toLowerCase();
    bool showEscalateButton = false;

    if (product != null || q.contains('produk:') || q.contains('menanyakan tentang')) {
      replyText =
          'Tentu Kak! Produk tersebut saat ini tercatat ready di etalase Toko BUMDes ${widget.tokoDesa} dan siap segera dikemas.';
    } else if (q.contains('stok') || q.contains('ready') || q.contains('ada')) {
      replyText =
          'Stok produk di Toko BUMDes ${widget.tokoDesa} selalu terpantau aktif dan siap diproses.';
    } else if (q.contains('kirim') ||
        q.contains('kecamatan') ||
        q.contains('desa') ||
        q.contains('antar')) {
      replyText =
          'Tentu bisa! Kami melayani pengiriman kurir lokal antar-desa dan antar-kecamatan se-Kabupaten Bengkalis.';
    } else if (q.contains('ongkir') ||
        q.contains('tarif') ||
        q.contains('biaya')) {
      replyText =
          'Ongkir dalam satu desa flat Rp 5.000. Untuk pengiriman antar-desa berkisar Rp 10.000 (sameday).';
    } else if (q.contains('cod') ||
        q.contains('bayar') ||
        q.contains('transfer') ||
        q.contains('qris')) {
      replyText =
          'Bisa bayar COD tunai saat kurir tiba, atau lewat QRIS dan Transfer Bank Virtual Account saat checkout.';
    } else if (q.contains('alamat') ||
        q.contains('lokasi') ||
        q.contains('toko') ||
        q.contains('ambil')) {
      replyText =
          'Kantor BUMDes kami berlokasi di ${widget.tokoDesa}, ${widget.tokoKecamatan}. Tersedia juga opsi Ambil Sendiri saat checkout tanpa ongkir.';
    } else if (q.contains('rusak') ||
        q.contains('retur') ||
        q.contains('komplain') ||
        q.contains('garansi')) {
      replyText =
          'Jika produk tidak sesuai atau terdapat kerusakan saat diterima, Kakak bisa langsung mengajukan komplain & retur di menu transaksi. Kami menjamin penggantian barang baru atau pengembalian dana 100%.';
    } else {
      replyText =
          'Maaf Kak, asisten otomatis kami belum memahami pertanyaan tersebut. Silakan klik tombol "Chat Pengelola Toko" di bawah agar dapat tersambung langsung dengan petugas pengelola toko kami.';
      showEscalateButton = true;
    }

    final timeStr = DateFormat('HH:mm').format(DateTime.now());

    setState(() {
      _isTokoTyping = false;
      _messages.add({
        'id': 'msg_bot_${DateTime.now().millisecondsSinceEpoch}',
        'sender': 'bot',
        'text': replyText,
        'time': timeStr,
        'canEscalate': showEscalateButton,
      });
    });

    _scrollToBottom();
  }

  Future<void> _simulateAdminReply() async {
    setState(() => _isTokoTyping = true);

    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final timeStr = DateFormat('HH:mm').format(DateTime.now());

    setState(() {
      _isTokoTyping = false;
      _messages.add({
        'id': 'msg_admin_${DateTime.now().millisecondsSinceEpoch}',
        'sender': 'admin',
        'text':
            'Halo, dengan Pengelola Toko BUMDes ${widget.tokoDesa} di sini. Pesan Anda telah kami terima dan kami siap membantu kebutuhan pesanan Anda.',
        'time': timeStr,
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
      _sendMessage(customText: 'Saya mengirimkan foto barang');
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
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFF115789),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        titleSpacing: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFF115789), const Color(0xFF0284C7)],
            ),
          ),
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
            // Store Avatar with Online Indicator
            Stack(
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: widget.tokoAvatar != null
                        ? Image.network(
                            widget.tokoAvatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                            ),
                          )
                        : Image.network(
                            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(widget.tokoDesa)}&background=0284C7&color=fff&size=128',
                            fit: BoxFit.cover,
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
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFF115789),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Store Name & Support Status
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BUMDes',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    _isEscalated
                        ? 'Terhubung dengan Pengelola Toko'
                        : 'Resmi BUMDes • Online',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isEscalated ? const Color(0xFFBAE6FD) : Colors.white70,
                      fontWeight: _isEscalated ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Pinned Product Inquiry Banner (If opened from product page)
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
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: Colors.grey[200],
                            child: const Icon(Icons.shopping_bag, color: Colors.grey),
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
                  ElevatedButton.icon(
                    onPressed: () {
                      _sendMessage(
                        customText:
                            'Halo, saya ingin menanyakan tentang produk: ${widget.productInquiry!['nama_produk'] ?? "ini"}. Apakah stoknya masih tersedia?',
                        product: widget.productInquiry,
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 13, color: Colors.white),
                    label: const Text(
                      'Tanya Produk',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _showProductInquiryCard = false),
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
                return _buildMessageItem(
                  msg: msg,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        Text(
                          _isEscalated ? 'Pengelola Toko sedang mengetik...' : 'Asisten Toko sedang mengetik...',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(width: 6),
                        const SizedBox(
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

          // 4. Quick Reply Action Chips
          Container(
            height: 38,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _quickReplyChips.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final chip = _quickReplyChips[i];
                final bool isEscalateChip = chip['isEscalate'] == true;

                return ActionChip(
                  avatar: Icon(
                    chip['icon'] as IconData,
                    size: 14,
                    color: isEscalateChip
                        ? (isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1))
                        : (isDark ? Colors.white70 : const Color(0xFF0369A1)),
                  ),
                  label: Text(
                    chip['label'] as String,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isEscalateChip ? FontWeight.w700 : FontWeight.w500,
                      color: isEscalateChip
                          ? (isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0369A1))
                          : (isDark ? Colors.white70 : const Color(0xFF0369A1)),
                    ),
                  ),
                  backgroundColor: isEscalateChip
                      ? (isDark ? const Color(0xFF0369A1).withAlpha(50) : const Color(0xFFE0F2FE))
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isEscalateChip
                          ? (isDark ? const Color(0xFF0284C7) : const Color(0xFF7DD3FC))
                          : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      width: isEscalateChip ? 1.5 : 1.0,
                    ),
                  ),
                  onPressed: () {
                    if (isEscalateChip) {
                      _escalateToPengelola();
                    } else {
                      _sendMessage(customText: chip['label'] as String);
                    }
                  },
                );
              },
            ),
          ),

          // 5. Chat Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
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
                    icon: const Icon(
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
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(fontSize: 13.5),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan ke Toko BUMDes...',
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

  Widget _buildMessageItem({
    required Map<String, dynamic> msg,
    required bool isDark,
    required NumberFormat currencyFormat,
  }) {
    final sender = msg['sender'];

    if (sender == 'system') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFBAE6FD),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF0284C7)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  msg['text'] ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF0369A1),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bool isUser = sender == 'user';
    final bool isAdmin = sender == 'admin';
    const primaryColor = Color(0xFF115789);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? primaryColor
              : (isAdmin
                  ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F9FF))
                  : (isDark ? const Color(0xFF1E293B) : Colors.white)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: isAdmin
                      ? const Color(0xFFBAE6FD)
                      : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
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
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Admin Official Badge
            if (isAdmin) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.verified_rounded, size: 13, color: Color(0xFF0284C7)),
                  SizedBox(width: 4),
                  Text(
                    'Pengelola Toko',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0284C7),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // Attached Product Card Inside Bubble
            if (msg['product'] != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUser
                      ? Colors.white.withValues(alpha: 0.18)
                      : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isUser
                        ? Colors.white.withValues(alpha: 0.3)
                        : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: msg['product']['image_url'] != null
                          ? Image.network(
                              msg['product']['image_url'],
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 44,
                                height: 44,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, size: 20, color: Colors.grey),
                              ),
                            )
                          : Container(
                              width: 44,
                              height: 44,
                              color: Colors.grey[200],
                              child: const Icon(Icons.shopping_bag_outlined, size: 20, color: Colors.grey),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['product']['nama_produk'] ?? msg['product']['name'] ?? 'Produk',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isUser ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormat.format(
                              msg['product']['harga'] ?? msg['product']['price'] ?? 0,
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isUser ? const Color(0xFFE0F2FE) : const Color(0xFF0284C7),
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
                  fontSize: 13,
                  height: 1.35,
                  color: isUser
                      ? Colors.white
                      : (isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),

            // Inline Escalate Button (if bot can't answer)
            if (msg['canEscalate'] == true && !_isEscalated) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _escalateToPengelola,
                icon: const Icon(Icons.support_agent_rounded, size: 14, color: Colors.white),
                label: const Text(
                  'Chat Pengelola Toko',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 4),

            // Time & Status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg['time'] ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    color: isUser
                        ? Colors.white70
                        : (isAdmin ? const Color(0xFF0284C7) : const Color(0xFF94A3B8)),
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
