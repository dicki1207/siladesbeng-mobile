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
                  
                  // Image dots indicator
                  if (_images.length > 1)
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_images.length, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImageIndex == index ? 12 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index ? Colors.white : Colors.white.withAlpha(128),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),

                  // Gradient overlay to make back button visible
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(150),
                          Colors.transparent,
                          Colors.black.withAlpha(100),
                        ],
                      ),
                    ),
                  ),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).primaryColor.withAlpha(50),
                          ),
                        ),
                        child: Text(
                          _newsItem['category']?.toString() ?? 'Pengumuman',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _newsItem['date']?.toString() ?? '-',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _newsItem['title']?.toString() ?? 'Tidak ada judul',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.withAlpha(50), thickness: 1),
                  const SizedBox(height: 24),
                  Text(
                    _newsItem['desc']?.toString() ?? _newsItem['content']?.toString() ?? _newsItem['description']?.toString() ?? 'Tidak ada konten.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
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
