import 'package:flutter/material.dart';
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

  List<dynamic> _otherNews = [];
  bool _isLoadingOther = true;

  @override
  void initState() {
    super.initState();
    _newsItem = widget.newsItem;
    _parseImages();
    _fetchDetails();
    _fetchOtherNews();
  }

  @override
  void dispose() {
    _pageController.dispose();
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
      // Fetch all news without strict category filter so other news always appears
      final news = await NewsService().getNews();
      if (mounted) {
        final currentId = _newsItem['id']?.toString();
        final filtered = news
            .where((n) => n['id']?.toString() != currentId)
            .take(5)
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // 1. App Bar Bersih & Natural (Tidak ada balok biru saat di-scroll)
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tautan berita disalin')),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. Kategori & Tanggal Badge Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withAlpha(60),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    (_newsItem['category']?.toString() ?? 'Pengumuman').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _newsItem['date']?.toString() ?? '-',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3. Judul Berita (Besar, Bold, Rapi)
            Text(
              _newsItem['title']?.toString() ?? 'Tidak ada judul',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                height: 1.35,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),

            const SizedBox(height: 16),

            // 4. Info Penulis & Lokasi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : Theme.of(context).primaryColor.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).primaryColor.withAlpha(35),
                    child: Icon(
                      Icons.account_balance_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _newsItem['author']?.toString() ?? 'Pemerintah Desa',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        if (_newsItem['location'] != null &&
                            _newsItem['location'].toString().trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _newsItem['location'].toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 5. Slider Gambar Proporsional (TIDAK KEPOTONG, mirip tampilan web)
            if (_images.isNotEmpty) ...[
              _buildImageCard(isDark),
              const SizedBox(height: 24),
            ],

            Divider(color: Colors.grey.withAlpha(40), thickness: 1),
            const SizedBox(height: 18),

            // 6. Konten Artikel
            SelectableText(
              _newsItem['desc']?.toString() ??
                  _newsItem['content']?.toString() ??
                  _newsItem['description']?.toString() ??
                  'Tidak ada konten.',
              style: TextStyle(
                fontSize: 15.5,
                height: 1.85,
                letterSpacing: 0.2,
                color: isDark
                    ? Colors.white.withAlpha(210)
                    : const Color(0xFF2D3748),
              ),
            ),

            const SizedBox(height: 36),

            // 7. Bagian Kabar Terkait Lainnya (Sekarang muncul & interaktif)
            _buildRelatedNewsSection(isDark),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 10, // Proporsi ideal agar foto tidak terpotong
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Gambar Slider
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

              // Tombol Zoom / Fullscreen di pojok kanan atas
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

              // Panah Navigasi Kiri & Kanan jika gambar > 1
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

                // Indikator Dots Kapsul di Bawah Gambar
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

  Widget _buildRelatedNewsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Kabar Terkait Lainnya',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoadingOther)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_otherNews.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
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
            itemCount: _otherNews.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _otherNews[index];
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

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailPage(newsItem: item),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.white.withAlpha(15) : Colors.grey.withAlpha(40),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail Foto
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 90,
                height: 70,
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
            const SizedBox(width: 14),
            // Teks Berita
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (item['category']?.toString() ?? 'Berita').toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item['date']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['title']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
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
