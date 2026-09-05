import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/core/api_config.dart';
import 'package:siladesbeng_mobile/core/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AssistantPage extends StatefulWidget {
 const AssistantPage({super.key});

 @override
 State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
 final TextEditingController _messageController = TextEditingController();
 final ScrollController _scrollController = ScrollController();
 final List<Map<String, dynamic>> _messages = [];

 bool _isTyping = false;

 @override
 void initState() {
  super.initState();
  _messages.add({
   'isUser': false,
   'text':
     'Halo! Saya Asisten Virtual SiladesBeng 🤖\n\nAda yang bisa saya bantu terkait layanan desa, sewa alat, gas LPG, pasar daerah, atau laporan keluhan di Bengkalis? Silakan tanyakan langsung ✨.',
   'time':
     '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
  });
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

 Future<void> _sendMessage([String? customText]) async {
  final text = (customText ?? _messageController.text).trim();
  if (text.isEmpty) return;

  setState(() {
   _messages.add({
    'isUser': true,
    'text': text,
    'time':
      '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
   });
   if (customText == null) {
    _messageController.clear();
   }
   _isTyping = true;
  });

  _scrollToBottom();

  try {
   final prefs = await SharedPreferences.getInstance();
   final token = prefs.getString('auth_token');

   // Siapkan history untuk context percakapan
   List<Map<String, String>> history = _messages
     .map(
      (m) => {
       'role': (m['isUser'] as bool) ? 'user' : 'model',
       'text': m['text'].toString(),
      },
     )
     .toList();

   // Jangan kirim pesan terakhir karena akan dikirim sebagai 'message' utama
   if (history.isNotEmpty) {
    history.removeLast();
   }

   final response = await http
     .post(
      Uri.parse('${ApiConfig.baseUrl}/api/chatbot'),
      headers: {
       'Accept': 'application/json',
       'Content-Type': 'application/json',
       if (token != null) 'Authorization': 'Bearer $token',
      },
      body: json.encode({'message': text, 'history': history}),
     )
     .timeout(const Duration(seconds: 30));

   if (!mounted) return;

   setState(() {
    _isTyping = false;
   });

   if (response.statusCode == 200) {
    final data = json.decode(response.body);
    setState(() {
     _messages.add({
      'isUser': false,
      'text': data['reply'] ?? 'Maaf, saya tidak mengerti.',
      'time':
        '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
     });
    });
   } else {
    // Backend sekarang selalu mengirim 'reply' bahkan saat fallback
    final data = json.decode(response.body);
    final replyText =
      data['reply'] ??
      data['error'] ??
      'Maaf, terjadi kesalahan. Coba lagi nanti ya.';
    setState(() {
     _messages.add({
      'isUser': false,
      'text': replyText,
      'time':
        '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
     });
    });
   }
  } on TimeoutException {
   if (!mounted) return;
   setState(() {
    _isTyping = false;
    _messages.add({
     'isUser': false,
     'text':
       'Waktu tunggu habis. Server AI mungkin sedang sibuk. Coba lagi dalam beberapa saat ya ',
     'time':
       '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    });
   });
  } catch (e) {
   if (!mounted) return;
   setState(() {
    _isTyping = false;
    _messages.add({
     'isUser': false,
     'text': 'Koneksi gagal. Periksa jaringan Anda.',
     'time':
       '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    });
   });
  }

  _scrollToBottom();
 }

 @override
 Widget build(BuildContext context) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;

  return Scaffold(
   backgroundColor: isDark ? AppTheme.bgDark : const Color(0xFFF8FAFC),
   appBar: AppBar(
    title: Text(
     'SiladesBeng Assistant',
     style: GoogleFonts.inter(
      fontSize: 17.sp,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      letterSpacing: 0.3,
     ),
    ),
    centerTitle: true,
    elevation: 0,
    backgroundColor: const Color(0xFF2563EB),
    iconTheme: const IconThemeData(color: Colors.white),
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
   body: Column(
    children: [
     Expanded(
      child: ListView.builder(
       controller: _scrollController,
       padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
       itemCount: _messages.length,
       itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildMessageBubble(msg, isDark);
       },
      ),
     ),
     if (_isTyping) _buildTypingIndicator(isDark),
     _buildMessageInput(isDark),
    ],
   ),
  );
 }

 Widget _buildTypingIndicator(bool isDark) {
  return Padding(
   padding: EdgeInsets.only(left: 16.w, bottom: 8.h),
   child: Row(
    children: [
     const CircleAvatar(
      radius: 12,
      backgroundImage: AssetImage('logodomain.png'),
      backgroundColor: Colors.transparent,
     ),
     SizedBox(width: 8.w),
     Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
       color: isDark ? AppTheme.cardDark : Colors.white,
       borderRadius: BorderRadius.circular(20.r),
       border: Border.all(
        color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05),
       ),
       boxShadow: [
        BoxShadow(
         color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
         blurRadius: 5,
         offset: const Offset(0, 2),
        ),
       ],
      ),
      child: Text(
       'Mengetik...',
       style: GoogleFonts.inter(
        color: isDark ? AppTheme.textGrayDark : Colors.grey,
        fontSize: 12.sp,
        fontStyle: FontStyle.italic,
       ),
      ),
     ),
    ],
   ),
  );
 }

 Widget _buildMessageBubble(Map<String, dynamic> msg, bool isDark) {
  final isUser = msg['isUser'] as bool;

  return Padding(
   padding: EdgeInsets.only(bottom: 16.h),
   child: Row(
    mainAxisAlignment: isUser
      ? MainAxisAlignment.end
      : MainAxisAlignment.start,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
     if (!isUser) ...[
      const CircleAvatar(
       radius: 16,
       backgroundImage: AssetImage('logodomain.png'),
       backgroundColor: Colors.transparent,
      ),
      SizedBox(width: 8.w),
     ],
     Flexible(
      child: Container(
       padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
       decoration: BoxDecoration(
        color: isUser
          ? (isDark ? AppTheme.primaryDark : AppTheme.primaryLight)
          : (isDark ? AppTheme.cardDark : Colors.white),
        borderRadius: BorderRadius.only(
         topLeft: Radius.circular(18.r),
         topRight: Radius.circular(18.r),
         bottomLeft: Radius.circular(isUser ? 18 : 2),
         bottomRight: Radius.circular(isUser ? 2 : 18),
        ),
        border: isUser
          ? null
          : Border.all(
            color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
           ),
        boxShadow: [
         BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
         Text(
          msg['text'].toString().replaceAll('*', ''),
          style: GoogleFonts.inter(
           color: isUser
             ? Colors.white
             : (isDark ? AppTheme.textLight : AppTheme.textDark),
           fontSize: 14.sp,
           height: 1.45,
          ),
         ),
         SizedBox(height: 5.h),
         Text(
          msg['time'],
          style: GoogleFonts.inter(
           color: isUser
             ? Colors.white70
             : (isDark
                ? AppTheme.textGrayDark
                : AppTheme.textGrayLight),
           fontSize: 10.sp,
          ),
         ),
        ],
       ),
      ),
     ),
     if (isUser) SizedBox(width: 24.w),
     if (!isUser) SizedBox(width: 24.w),
    ],
   ),
  );
 }

 Widget _buildMessageInput(bool isDark) {
  return Container(
   padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
   decoration: BoxDecoration(
    color: isDark ? AppTheme.cardDark : Colors.white,
    border: Border(
     top: BorderSide(
      color: isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05),
     ),
    ),
    boxShadow: [
     BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
      blurRadius: 10,
      offset: const Offset(0, -3),
     ),
    ],
   ),
   child: SafeArea(
    child: Row(
     children: [
      Expanded(
       child: Container(
        decoration: BoxDecoration(
         color: isDark ? AppTheme.bgDark : const Color(0xFFF1F5F9),
         borderRadius: BorderRadius.circular(24.r),
         border: Border.all(
          color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.transparent,
         ),
        ),
        child: TextField(
         controller: _messageController,
         style: GoogleFonts.inter(
          color: isDark ? AppTheme.textLight : AppTheme.textDark,
          fontSize: 14.sp,
         ),
         cursorColor: isDark
           ? AppTheme.primaryDark
           : AppTheme.primaryLight,
         decoration: InputDecoration(
          hintText: 'Ketik pesan Anda...',
          hintStyle: GoogleFonts.inter(
           color: isDark ? AppTheme.textGrayDark : Colors.black45,
           fontSize: 14.sp,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
           horizontal: 18.w,
           vertical: 12.h,
          ),
         ),
         onSubmitted: (_) => _sendMessage(),
        ),
       ),
      ),
      SizedBox(width: 10.w),
      GestureDetector(
       onTap: () => _sendMessage(),
       child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
         color: isDark ? AppTheme.primaryDark : AppTheme.primaryLight,
         shape: BoxShape.circle,
        ),
        child: Icon(
         Icons.send_rounded,
         color: Colors.white,
         size: 20.sp,
        ),
       ),
      ),
     ],
    ),
   ),
  );
 }
}
