import 'package:flutter/material.dart';
import 'package:siladesbeng_mobile/features/news/news_page.dart';
import 'package:siladesbeng_mobile/widgets/premium_header.dart';

class KabarDaerahPage extends StatelessWidget {
  const KabarDaerahPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            PremiumHeader(
              bottomPadding: 0, // TabBar has its own padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Kabar Daerah',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Informasi terbaru dan kegiatan seputar daerah Anda.',
                    style: TextStyle(
                      color: Colors.white.withAlpha(230),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Modern TabBar
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: const Color(0xFF1E88E5),
                      unselectedLabelColor: Colors.white,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      tabs: const [
                        Tab(text: 'Berita Daerah'),
                        Tab(text: 'Pengumuman'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            
            // TabBarView for Content
            const Expanded(
              child: TabBarView(
                physics: BouncingScrollPhysics(),
                children: [
                  NewsPage(postCategory: 'Berita', isEmbedded: true),
                  NewsPage(postCategory: 'Pengumuman', isEmbedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
