import 'package:flutter/material.dart';
import 'package:siladesbeng_mobile/services/news_service.dart';
import 'package:siladesbeng_mobile/features/news/news_detail_page.dart';
import 'package:siladesbeng_mobile/features/profile/event_gotong_royong_page.dart';
import 'package:siladesbeng_mobile/widgets/premium_header.dart';

class NewsPage extends StatefulWidget {
  final String postCategory; // 'Berita' or 'Pengumuman'
  final bool isEmbedded;

  const NewsPage({super.key, this.postCategory = 'Pengumuman', this.isEmbedded = false});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua',
    'Pengumuman',
    'Event',
    'Gotong Royong',
  ];

  List<Map<String, dynamic>> _mockNews = [];
  bool _isLoading = true;
  final NewsService _newsService = NewsService();

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    setState(() {
      _isLoading = true;
    });

    final data = await _newsService.getNews(
      type: _selectedCategory,
      search: _searchController.text,
      postCategory: widget.postCategory,
    );
    
    if (!mounted) return;
    
    if (data.isNotEmpty) {
      setState(() {
        _mockNews = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } else {
      setState(() {
        _mockNews = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredNews = _mockNews;
    bool isBerita = widget.postCategory == 'Berita';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: isBerita 
          ? null 
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventGotongRoyongPage()),
                );
              },
              icon: const Icon(Icons.campaign, color: Colors.white),
              label: const Text(
                'Buat Pengumuman (RT/RW)',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              backgroundColor: Colors.teal[800],
              elevation: 4,
            ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isEmbedded)
                  PremiumHeader(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            Icon(isBerita ? Icons.newspaper : Icons.announcement, color: Colors.white, size: 30),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            isBerita ? 'Berita Daerah' : 'Pengumuman',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            isBerita 
                                ? 'Dapatkan berita kegiatan terbaru seputar daerah.'
                                : 'Informasi dan acara yang akan datang.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                
                // Content section with negative margin to overlap header
                Transform.translate(
                  offset: Offset(0, widget.isEmbedded ? 0 : -20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: widget.isEmbedded 
                          ? BorderRadius.zero
                          : const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Search bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: isBerita ? 'Cari berita...' : 'Cari pengumuman...',
                                prefixIcon: Icon(Icons.search, color: isBerita ? Colors.blue[700] : Colors.teal[700]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              ),
                              onSubmitted: (value) => _fetchNews(),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Categories (Only for Pengumuman)
                        if (!isBerita)
                          SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final isSelected = category == _selectedCategory;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: ChoiceChip(
                                    label: Text(
                                      category,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.grey[700],
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor: Colors.teal[700],
                                    backgroundColor: Colors.grey[200],
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedCategory = category;
                                        });
                                        _fetchNews();
                                      }
                                    },
                                    elevation: isSelected ? 2 : 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                );
                              },
                            ),
                          ),
                        
                        if (!isBerita) const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // News List
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : filteredNews.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              isBerita ? 'Belum Ada Berita' : 'Belum Ada Pengumuman',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isBerita ? 'Belum ada berita daerah yang dipublikasikan saat ini.' : 'Belum ada pengumuman yang sesuai.',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final news = filteredNews[index];
                            return _buildNewsCard(news, isBerita);
                          },
                          childCount: filteredNews.length,
                        ),
                      ),
                    ),
                
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news, bool isBerita) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (news['title'] == 'Tidak ada pengumuman' || news['title'] == 'Belum Ada Berita' || news['title'] == 'Belum Ada Pengumuman') return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewsDetailPage(newsItem: news),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Hero(
                tag: 'news_img_${news['id'] ?? news['title']}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    news['image'],
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                      );
                    },
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isBerita ? Colors.blue[100] : Colors.teal[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            news['category'],
                            style: TextStyle(
                              color: isBerita ? Colors.blue[800] : Colors.teal[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              news['date'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Title
                    Text(
                      news['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Description snippet
                    Text(
                      news['desc'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
