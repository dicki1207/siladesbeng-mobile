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
    if (_newsItem.containsKey('images') && _newsItem['images'] is List && (_newsItem['images'] as List).isNotEmpty) {
      _images = List<dynamic>.from(_newsItem['images']);
    } else if (_newsItem.containsKey('image') && _newsItem['image'] != null) {
      _images = [_newsItem['image']];
    }
  }

  Future<void> _fetchDetails() async {
    if (_newsItem['id'] == null) return;
    try {
      final detail = await NewsService().getNewsDetail(_newsItem['id']);
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
      final String category = _newsItem['category']?.toString() ?? 'Pengumuman';
      // If it's Pengumuman, fetch Pengumuman, otherwise try to fetch Berita
      final String postCat = category.toLowerCase().contains('pengumuman') ? 'Pengumuman' : 'Berita';
      
      final news = await NewsService().getNews(postCategory: postCat);
      if (mounted) {
        setState(() {
          _otherNews = news.where((n) => n['id'] != _newsItem['id']).take(5).toList();
          _isLoadingOther = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOther = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(30),
              child: Container(
                height: 30,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (_images.isEmpty)
                    Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                    )
                  else
                    PageView.builder(
                      controller: _pageController,
                      itemCount: _images.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return CustomCachedImage(
                          _images[index]?.toString() ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                          ),
                        );
                      },
                    ),

                  // Gradient overlay agar panah & tombol back tetap terlihat jelas
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(150),
                          Colors.transparent,
                          Colors.black.withAlpha(150),
                        ],
                      ),
                    ),
                  ),

                  // Navigation Arrows & Dots (Slider Interaktif)
                  if (_images.length > 1) ...[
                    // Panah Kiri
                    if (_currentImageIndex > 0)
                      Positioned(
                        left: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: InkWell(
                            onTap: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(150),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                            ),
                          ),
                        ),
                      ),
                      
                    // Panah Kanan
                    if (_currentImageIndex < _images.length - 1)
                      Positioned(
                        right: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: InkWell(
                            onTap: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(150),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                            ),
                          ),
                        ),
                      ),
                      
                    // Image dots indicator (Gaya Kapsul Hitam Transparan)
                    Positioned(
                      bottom: 45,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(120),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: List.generate(_images.length, (index) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentImageIndex == index ? 12 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _currentImageIndex == index ? Colors.white : Colors.white.withAlpha(100),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(100),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Kategori & Tombol Share
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor, // Warna solid agar menonjol
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withAlpha(60),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          (_newsItem['category']?.toString() ?? 'Pengumuman').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Colors.white, // Teks putih kontras tinggi
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined),
                        color: Colors.grey[600],
                        iconSize: 22,
                        splashRadius: 20,
                        onPressed: () {
                          // TODO: Tambahkan fitur share link berita
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 2. Judul Berita
                  Text(
                    _newsItem['title']?.toString() ?? 'Tidak ada judul',
                    style: TextStyle(
                      fontSize: 26, // Lebih besar
                      fontWeight: FontWeight.w900, // Lebih tebal
                      letterSpacing: -0.5,
                      height: 1.35,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 3. Profil Penulis & Tanggal (Gaya Editorial)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                        child: Icon(Icons.person_outline, color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pemerintah Desa',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _newsItem['date']?.toString() ?? '-',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.bookmark_border_rounded, color: Colors.grey[400], size: 24),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.withAlpha(50), thickness: 1),
                  const SizedBox(height: 24),
                  
                  // 4. Konten Utama (Lebih Gelap & Rapi)
                  Text(
                    _newsItem['desc']?.toString() ?? _newsItem['content']?.toString() ?? _newsItem['description']?.toString() ?? 'Tidak ada konten.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.85, // Jarak antar baris lebih nyaman
                      letterSpacing: 0.2, // Spasi antar huruf
                      // Gunakan warna gelap tegas (slate) di mode terang agar mata tidak sakit
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white.withAlpha(200) 
                          : const Color(0xFF2D3748), 
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Berita Lainnya Section
                  Text(
                    'Berita Lainnya',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_isLoadingOther)
                    const Center(child: CircularProgressIndicator())
                  else if (_otherNews.isEmpty)
                    Center(
                      child: Text(
                        'Tidak ada berita lainnya.',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    )
                  else
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _otherNews.length,
                        itemBuilder: (context, index) {
                          final item = _otherNews[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NewsDetailPage(newsItem: item),
                                ),
                              );
                            },
                            child: _buildOtherNewsCard(item),
                          );
                        },
                      ),
                    ),
                    
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherNewsCard(Map<String, dynamic> item) {
    String imageUrl = item['image']?.toString() ?? '';
    if (imageUrl.isEmpty && item['images'] != null && item['images'] is List && (item['images'] as List).isNotEmpty) {
      imageUrl = item['images'][0].toString();
    }
    
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 110,
              width: double.infinity,
              child: CustomCachedImage(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['date']?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      item['title']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
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
}
