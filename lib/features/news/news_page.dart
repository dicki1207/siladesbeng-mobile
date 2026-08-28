import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:siladesbeng_mobile/services/news_service.dart';
import 'package:siladesbeng_mobile/features/news/news_detail_page.dart';
import 'package:siladesbeng_mobile/features/profile/event_gotong_royong_page.dart';

class NewsPage extends StatefulWidget {
  final String postCategory; // 'Berita' or 'Pengumuman'
  final bool isEmbedded;

  const NewsPage({
    super.key,
    this.postCategory = 'Pengumuman',
    this.isEmbedded = false,
  });

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';

  final List<String> _categories = [
    'Semua',
    'Pengumuman',
    'Acara / Event',
    'Gotong Royong',
  ];

  List<Map<String, dynamic>> _newsList = [];
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
      final validData = data
          .where((item) => !(item['title']?.toString().toLowerCase().contains('testing') ?? false))
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        _newsList = validData;
        _isLoading = false;
      });
    } else {
      setState(() {
        _newsList = [];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty || rawDate == '-') return '-';
    try {
      final parsed = DateTime.parse(rawDate);
      return DateFormat('d MMM yyyy').format(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pengumuman':
      case 'rapat':
        return Icons.campaign_rounded;
      case 'Acara / Event':
      case 'Event':
      case 'Acara':
      case 'kegiatan_sosial':
        return Icons.festival_rounded;
      case 'Gotong Royong':
      case 'gotong_royong':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Gotong Royong':
      case 'gotong_royong':
        return const Color(0xFF10B981);
      case 'Acara / Event':
      case 'Event':
      case 'Acara':
      case 'kegiatan_sosial':
        return const Color(0xFF8B5CF6);
      case 'Pengumuman':
      case 'rapat':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF0284C7);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredNews = _newsList;
    bool isBerita = widget.postCategory == 'Berita';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: Text(
                isBerita ? 'Berita Daerah' : 'Pengumuman',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              backgroundColor: const Color(0xFF2563EB),
              elevation: 0,
              centerTitle: true,
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
              iconTheme: const IconThemeData(color: Colors.white),
            ),
      floatingActionButton: isBerita
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EventGotongRoyongPage(),
                  ),
                );
              },
              icon: const Icon(Icons.campaign_rounded, color: Colors.white),
              label: const Text(
                'Buat Pengumuman (RT/RW)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              backgroundColor: primaryColor,
              elevation: 4,
            ),
      body: RefreshIndicator(
        onRefresh: _fetchNews,
        color: primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white12
                              : Colors.grey.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.04,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: isBerita
                              ? 'Cari berita daerah...'
                              : 'Cari pengumuman desa...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey[400],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: primaryColor,
                            size: 22,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _fetchNews();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (value) => _fetchNews(),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Categories (Only for Pengumuman)
                  if (!isBerita)
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = category == _selectedCategory;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = category;
                                  });
                                  _fetchNews();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryColor
                                        : (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.05,
                                                )
                                              : Colors.grey[100]),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? primaryColor
                                          : (isDark
                                                ? Colors.white12
                                                : Colors.grey.withValues(
                                                    alpha: 0.2,
                                                  )),
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: primaryColor.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getCategoryIcon(category),
                                        size: 14,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                  ? Colors.white70
                                                  : Colors.grey[700]),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        category,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark
                                                    ? Colors.white70
                                                    : Colors.grey[700]),
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  if (!isBerita) const SizedBox(height: 14),
                ],
              ),
            ),

            // News List
            _isLoading
                ? SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  )
                : filteredNews.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isBerita
                                    ? Icons.newspaper_rounded
                                    : Icons.campaign_outlined,
                                size: 54,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isBerita
                                  ? 'Belum Ada Berita'
                                  : 'Belum Ada Pengumuman',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              isBerita
                                  ? 'Belum ada berita daerah yang dipublikasikan.'
                                  : 'Belum ada pengumuman yang sesuai dengan filter.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey[500],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final news = filteredNews[index];
                        return _buildNewsCard(news, isBerita);
                      }, childCount: filteredNews.length),
                    ),
                  ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news, bool isBerita) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final String categoryName =
        news['category']?.toString() ?? (isBerita ? 'Berita' : 'Pengumuman');
    final Color badgeColor = isBerita
        ? primaryColor
        : _getCategoryColor(categoryName);
    final String formattedDate = _formatDate(news['date']?.toString());
    final String? description =
        news['desc']?.toString() ??
        news['content']?.toString() ??
        news['description']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (news['title'] == 'Tidak ada pengumuman' ||
                news['title'] == 'Belum Ada Berita' ||
                news['title'] == 'Belum Ada Pengumuman') {
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewsDetailPage(newsItem: news),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Thumbnail (Framed with inner padding)
                Hero(
                  tag: 'news_img_${news['id'] ?? news['title']}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.network(
                          news['image']?.toString() ?? '',
                          height: 95,
                          width: 95,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 95,
                              width: 95,
                              color: isDark
                                  ? Colors.grey[800]
                                  : primaryColor.withValues(alpha: 0.08),
                              child: Icon(
                                isBerita
                                    ? Icons.newspaper_rounded
                                    : Icons.campaign_rounded,
                                color: primaryColor.withValues(alpha: 0.5),
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Content (Right)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Badge & Date Row
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: badgeColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isBerita
                                        ? Icons.newspaper_rounded
                                        : _getCategoryIcon(categoryName),
                                    size: 11,
                                    color: badgeColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      categoryName,
                                      style: TextStyle(
                                        color: badgeColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 10,
                                color: isDark
                                    ? Colors.white38
                                    : Colors.grey[500],
                              ),
                              const SizedBox(width: 3),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.grey[600],
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        news['title']?.toString() ?? 'Tidak ada judul',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Snippet or Author info
                      if (description != null &&
                          description.trim().isNotEmpty &&
                          description != 'Tidak ada konten.') ...[
                        Text(
                          description.replaceAll('\n', ' ').trim(),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                            height: 1.25,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_outlined,
                              size: 12,
                              color: primaryColor.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              news['author']?.toString() ?? 'Pemerintah Desa',
                              style: TextStyle(
                                fontSize: 11,
                                color: primaryColor.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
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
        ),
      ),
    );
  }
}
