import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:siladesbeng_mobile/widgets/custom_cached_image.dart';
import 'package:siladesbeng_mobile/services/news_service.dart';

class NewsDetailPage extends StatefulWidget {
  final Map<String, dynamic> newsItem;

  const NewsDetailPage({super.key, required this.newsItem});

  @override
  State<NewsDetailPage> createState() => _NewsDetailPageState();
}

class _NewsDetailPageState extends State<NewsDetailPage> {
  late Map<String, dynamic> _newsItem;
  int _currentImageIndex = 0;
  List<dynamic> _images = [];
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  List<dynamic> _otherNews = [];
  bool _isLoadingOther = true;

  // Warna aksen khas jurnalisme portal berita (iniriau / detik / kompas)
  static const Color _newsAccentRed = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _newsItem = widget.newsItem;
    _parseImages();
    _fetchDetails();
    _fetchOtherNews();
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        if (_scrollController.offset > 280 && !_showScrollToTop) {
          setState(() => _showScrollToTop = true);
        } else if (_scrollController.offset <= 280 && _showScrollToTop) {
          setState(() => _showScrollToTop = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _parseImages() {
    if (_newsItem.containsKey('images') &&
        _newsItem['images'] is List &&
        (_newsItem['images'] as List).isNotEmpty) {
      _images = List<dynamic>.from(_newsItem['images']);
    } else if (_newsItem.containsKey('image') &&
        _newsItem['image'] != null &&
        _newsItem['image'].toString().isNotEmpty) {
      _images = [_newsItem['image']];
    }
  }

  Future<void> _fetchDetails() async {
    if (_newsItem['id'] == null) return;
    try {
      final id = int.tryParse(_newsItem['id'].toString());
      if (id == null) return;
      final detail = await NewsService().getNewsDetail(id);
      if (detail != null && mounted) {
        setState(() {
          _newsItem = detail;
          _parseImages();
        });
      }
    } catch (_) {
      // ignore errors
    }
  }

  Future<void> _fetchOtherNews() async {
    try {
      final news = await NewsService().getNews();
      if (mounted) {
        final currentId = _newsItem['id']?.toString();
        final filtered = news
            .where((n) => n['id']?.toString() != currentId)
            .toList();

        setState(() {
          _otherNews = filtered;
          _isLoadingOther = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOther = false);
    }
  }

  void _openFullScreenImage(int initialIndex) {
    if (_images.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
            title: Text(
              '${initialIndex + 1}/${_images.length}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            centerTitle: true,
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.5,
                child: Center(
                  child: CustomCachedImage(
                    _images[index]?.toString() ?? '',
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _shareToSocial(String platform) async {
    final title = _newsItem['title']?.toString() ?? 'Kabar Daerah Bengkalis';
    final newsId = _newsItem['id']?.toString() ?? '';
    final url = 'https://siladesbeng.inovasia.site/kabar-daerah/$newsId';
    final text = '$title - Baca selengkapnya di Sila-DesBeng:\n$url';

    if (platform == 'whatsapp') {
      final waUri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: title,
      ),
    );
  }

  void _copyNewsLink() {
    final title = _newsItem['title']?.toString() ?? 'Kabar Daerah Bengkalis';
    final newsId = _newsItem['id']?.toString() ?? '';
    final url = 'https://siladesbeng.inovasia.site/kabar-daerah/$newsId';
    Clipboard.setData(ClipboardData(text: '$title\n$url'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Tautan berita berhasil disalin ke papan klip'),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // 1. App Bar Bersih & Natural
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.share_outlined,
                size: 20,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              onPressed: () => _shareToSocial('general'),
            ),
          ),
        ],
      ),

      // Floating Action Button: Scroll to Top (Tombol Merah Panah Atas)
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: _newsAccentRed,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.keyboard_arrow_up_rounded, size: 24),
            )
          : null,

      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Breadcrumb Portal Berita (Home > Bengkalis > Bengkalis)
            _buildBreadcrumb(isDark),
            const SizedBox(height: 12),

            // 2. Judul Berita Utama (Besar, Tebal, Proporsional)
            Text(
              _newsItem['title']?.toString() ?? 'Tidak ada judul',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                height: 1.35,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),

            const SizedBox(height: 14),

            // 3. Info Penulis & Tanggal (Avatar, Nama Wartawan/Humas, Jam Rilis)
            _buildAuthorInfoBar(isDark),

            const SizedBox(height: 16),

            // 4. Slider Gambar / Cover Utama
            if (_images.isNotEmpty) ...[
              _buildImageCard(isDark),
              // 5. Keterangan Foto (Photo Caption)
              _buildPhotoCaption(isDark),
            ],

            const SizedBox(height: 12),

            // 6. Baris Tombol Berbagi Sosial Cepat (Facebook, X, WhatsApp, Telegram, Link)
            _buildSocialShareBar(isDark),

            const SizedBox(height: 18),
            Divider(color: Colors.grey.withAlpha(35), thickness: 1),
            const SizedBox(height: 14),

            // 7. Konten Artikel Paragraf dengan Sisipan "Baca Juga >"
            _buildArticleContentWithInlines(isDark),

            const SizedBox(height: 36),

            // 8. Bagian "PILIHAN REDAKSI" (Grid 2 Kolom Berita Bergambar)
            if (!_isLoadingOther && _otherNews.length > 1) ...[
              _buildPilihanRedaksiSection(isDark),
              const SizedBox(height: 36),
            ],

            // 9. Bagian "BERITA TERPOPULER" (Daftar Bernomor 1, 2, 3...)
            if (!_isLoadingOther && _otherNews.length > 3) ...[
              _buildBeritaPopulerSection(isDark),
              const SizedBox(height: 36),
            ],

            // 10. Bagian "BERITA LAINNYA" (Daftar Berita Vertikal dengan Thumbnail)
            _buildRelatedNewsSection(isDark),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ===== 1. BREADCRUMB WIDGET =====
  Widget _buildBreadcrumb(bool isDark) {
    final category = _newsItem['category']?.toString() ?? 'Kabar Daerah';
    final location = _newsItem['location']?.toString() ?? 'Bengkalis';

    return Row(
      children: [
        Icon(
          Icons.home_outlined,
          size: 14,
          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
        ),
        const SizedBox(width: 4),
        Icon(
          Icons.chevron_right_rounded,
          size: 14,
          color: Colors.grey[400],
        ),
        const SizedBox(width: 2),
        Text(
          category,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 2),
        Icon(
          Icons.chevron_right_rounded,
          size: 14,
          color: Colors.grey[400],
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            location,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _newsAccentRed,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ===== 3. INFO PENULIS & TANGGAL =====
  Widget _buildAuthorInfoBar(bool isDark) {
    final author = _newsItem['author']?.toString() ?? 'Humas Pemerintah Daerah';
    String dateStr = _newsItem['date']?.toString() ?? '-';
    if (!dateStr.contains('WIB') && !dateStr.contains('wib')) {
      dateStr = '$dateStr WIB';
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          child: const Icon(
            Icons.person_rounded,
            size: 22,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                author,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===== 5. KETERANGAN FOTO (PHOTO CAPTION) =====
  Widget _buildPhotoCaption(bool isDark) {
    final caption = _newsItem['caption']?.toString() ??
        'Dokumentasi liputan resmi Kabar Daerah Kabupaten Bengkalis.';

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        caption,
        style: TextStyle(
          fontSize: 11.5,
          fontStyle: FontStyle.italic,
          height: 1.35,
          color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
        ),
      ),
    );
  }

  // ===== 6. SOCIAL SHARE TOOLBAR =====
  Widget _buildSocialShareBar(bool isDark) {
    return Row(
      children: [
        // Facebook (Biru)
        _buildSocialButton(
          icon: Icons.facebook,
          color: const Color(0xFF1877F2),
          onTap: () => _shareToSocial('facebook'),
        ),
        const SizedBox(width: 8),
        // X / Twitter (Hitam)
        _buildSocialButton(
          label: '𝕏',
          color: const Color(0xFF0F1419),
          onTap: () => _shareToSocial('x'),
        ),
        const SizedBox(width: 8),
        // WhatsApp (Hijau)
        _buildSocialButton(
          icon: Icons.chat_bubble_rounded,
          color: const Color(0xFF25D366),
          onTap: () => _shareToSocial('whatsapp'),
        ),
        const SizedBox(width: 8),
        // Telegram (Biru Langit)
        _buildSocialButton(
          icon: Icons.send_rounded,
          color: const Color(0xFF229ED9),
          onTap: () => _shareToSocial('telegram'),
        ),
        const SizedBox(width: 8),
        // Salin Tautan
        _buildSocialButton(
          icon: Icons.link_rounded,
          color: const Color(0xFF475569),
          onTap: () => _copyNewsLink(),
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    IconData? icon,
    String? label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 38,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: label != null
              ? Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : Icon(icon, color: Colors.white, size: 17),
        ),
      ),
    );
  }

  // ===== 7. KONTEN ARTIKEL DENGAN SISIPAN "BACA JUGA >" =====
  Widget _buildArticleContentWithInlines(bool isDark) {
    final content = _newsItem['desc']?.toString() ??
        _newsItem['content']?.toString() ??
        _newsItem['description']?.toString() ??
        'Tidak ada konten.';

    // Bersihkan tag HTML jika ada
    final cleanContent = content
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .trim();

    final paragraphs = cleanContent
        .split(RegExp(r'\n+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    // Ambil berita pertama dari list untuk 'Baca Juga'
    final bacaJugaItem = _otherNews.isNotEmpty ? _otherNews[0] : null;

    if (paragraphs.length <= 2 || bacaJugaItem == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildParagraphText(cleanContent, isDark, isFirst: true),
          if (bacaJugaItem != null) ...[
            const SizedBox(height: 10),
            _buildBacaJugaWidget(bacaJugaItem, isDark),
          ],
        ],
      );
    }

    // Sisipkan kartu 'Baca Juga' setelah paragraf ke-2
    List<Widget> widgets = [];
    for (int i = 0; i < paragraphs.length; i++) {
      widgets.add(_buildParagraphText(paragraphs[i], isDark, isFirst: i == 0));
      widgets.add(const SizedBox(height: 14));
      if (i == 1 && bacaJugaItem != null) {
        widgets.add(_buildBacaJugaWidget(bacaJugaItem, isDark));
        widgets.add(const SizedBox(height: 14));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildParagraphText(String text, bool isDark, {bool isFirst = false}) {
    // Paragraf pertama diberi awalan bold lokasi jika belum ada
    Widget textWidget;
    if (isFirst && !text.toUpperCase().contains('BENGKALIS')) {
      textWidget = SelectableText.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: 'BENGKALIS – ',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            TextSpan(text: text),
          ],
        ),
        style: TextStyle(
          fontSize: 15.5,
          height: 1.85,
          letterSpacing: 0.15,
          color: isDark ? Colors.white.withAlpha(210) : const Color(0xFF2D3748),
        ),
      );
    } else {
      textWidget = SelectableText(
        text,
        style: TextStyle(
          fontSize: 15.5,
          height: 1.85,
          letterSpacing: 0.15,
          color: isDark ? Colors.white.withAlpha(210) : const Color(0xFF2D3748),
        ),
      );
    }

    return textWidget;
  }

  // WIDGET SISIPAN "BACA JUGA >"
  Widget _buildBacaJugaWidget(Map<String, dynamic> item, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailPage(newsItem: item),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2E1717) : const Color(0xFFFFF1F0),
          borderRadius: BorderRadius.circular(8),
          border: const Border(
            left: BorderSide(
              color: _newsAccentRed,
              width: 4,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  'Baca Juga',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: _newsAccentRed,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: _newsAccentRed,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item['title']?.toString() ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 8. BAGIAN "PILIHAN REDAKSI" (2 KOLOM KARTU BERGAMBAR) =====
  Widget _buildPilihanRedaksiSection(bool isDark) {
    // Ambil 2 artikel bergambar
    final editorialItems = _otherNews.length > 1
        ? _otherNews.sublist(1, math.min(3, _otherNews.length))
        : <dynamic>[];

    if (editorialItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('PILIHAN REDAKSI', isDark),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildEditorialCard(editorialItems[0], isDark),
            ),
            if (editorialItems.length > 1) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildEditorialCard(editorialItems[1], isDark),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEditorialCard(Map<String, dynamic> item, bool isDark) {
    String imageUrl = item['image']?.toString() ?? '';
    if (imageUrl.isEmpty &&
        item['images'] != null &&
        item['images'] is List &&
        (item['images'] as List).isNotEmpty) {
      imageUrl = item['images'][0].toString();
    }

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailPage(newsItem: item),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: CustomCachedImage(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_outlined, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item['title']?.toString() ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.35,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 11,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item['date']?.toString() ?? '',
                  style: TextStyle(fontSize: 10.5, color: Colors.grey[500]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== 9. BAGIAN "BERITA TERPOPULER" (DAFTAR BERNOMOR 1, 2, 3...) =====
  Widget _buildBeritaPopulerSection(bool isDark) {
    final popularItems = _otherNews.length > 3
        ? _otherNews.sublist(3, math.min(6, _otherNews.length))
        : <dynamic>[];

    if (popularItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('BERITA TERPOPULER', isDark),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: popularItems.length,
          separatorBuilder: (context, index) => Divider(
            color: Colors.grey.withAlpha(25),
            height: 18,
          ),
          itemBuilder: (context, index) {
            final item = popularItems[index];
            final rank = index + 1;

            return InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewsDetailPage(newsItem: item),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$rank',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _newsAccentRed,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 11,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item['date']?.toString() ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
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
            );
          },
        ),
      ],
    );
  }

  // ===== 10. BAGIAN "BERITA LAINNYA" (LIST DENGAN THUMBNAIL) =====
  Widget _buildRelatedNewsSection(bool isDark) {
    // Tampilkan berita sisanya atau fallback ke seluruh berita
    final itemsToShow = _otherNews.length > 6
        ? _otherNews.sublist(6)
        : (_otherNews.length > 3 ? _otherNews.sublist(3) : _otherNews);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('BERITA LAINNYA', isDark),
        const SizedBox(height: 14),
        if (_isLoadingOther)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (itemsToShow.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'Tidak ada kabar lainnya.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemsToShow.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.grey.withAlpha(25),
              height: 20,
            ),
            itemBuilder: (context, index) {
              final item = itemsToShow[index];
              return _buildRelatedNewsTile(item, isDark);
            },
          ),
      ],
    );
  }

  Widget _buildRelatedNewsTile(Map<String, dynamic> item, bool isDark) {
    String imageUrl = item['image']?.toString() ?? '';
    if (imageUrl.isEmpty &&
        item['images'] != null &&
        item['images'] is List &&
        (item['images'] as List).isNotEmpty) {
      imageUrl = item['images'][0].toString();
    }

    final category = (item['category']?.toString() ?? 'BENGKALIS').toUpperCase();

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailPage(newsItem: item),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail Foto
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 100,
              height: 72,
              child: CustomCachedImage(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_outlined, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Kategori, Judul & Tanggal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: _newsAccentRed,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item['title']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item['date']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // HEADER JUDUL SECTION DENGAN AKSEN MERAH
  Widget _buildSectionHeader(String title, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: _newsAccentRed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const Text(
              'INDEX >',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _newsAccentRed,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: 80,
          height: 2.5,
          color: _newsAccentRed,
        ),
      ],
    );
  }

  // COVER IMAGE SLIDER
  Widget _buildImageCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _openFullScreenImage(index),
                    child: CustomCachedImage(
                      _images[index]?.toString() ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Fullscreen Icon Button
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => _openFullScreenImage(_currentImageIndex),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(140),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

              // Navigasi Kiri & Kanan jika gambar > 1
              if (_images.length > 1) ...[
                if (_currentImageIndex > 0)
                  Positioned(
                    left: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(140),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),

                if (_currentImageIndex < _images.length - 1)
                  Positioned(
                    right: 10,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(140),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Indikator Dots
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(140),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(_images.length, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentImageIndex == index ? 14 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index
                                  ? Colors.white
                                  : Colors.white.withAlpha(100),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
