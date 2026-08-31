import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:siladesbeng_mobile/features/news/news_page.dart';

class KabarDaerahPage extends StatelessWidget {
  const KabarDaerahPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Kabar Daerah',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          backgroundColor: isDark
              ? const Color(0xFF0F172A)
              : const Color(0xFF2563EB),
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                        : [const Color(0xFF2FA2F1), const Color(0xFF0284C7)],
                  ),
                ),
              ),
              // Glowing circle 1 (Top Right)
              Positioned(
                top: -35,
                right: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(22),
                  ),
                ),
              ),
              // Glowing circle 2 (Bottom Left)
              Positioned(
                bottom: -25,
                left: -15,
                child: Container(
                  width: 85,
                  height: 85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(14),
                  ),
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(25.r),
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(22.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: isDark ? Colors.white : primaryColor,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.85),
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
                unselectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.newspaper_rounded, size: 16.sp),
                        SizedBox(width: 6.w),
                        Text('Berita Daerah'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_rounded, size: 16.sp),
                        SizedBox(width: 6.w),
                        Text('Pengumuman'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          physics: BouncingScrollPhysics(),
          children: [
            NewsPage(postCategory: 'Berita', isEmbedded: true),
            NewsPage(postCategory: 'Pengumuman', isEmbedded: true),
          ],
        ),
      ),
    );
  }
}
