import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siladesbeng_mobile/features/home/home_page.dart';
import 'package:siladesbeng_mobile/features/news/kabar_daerah_page.dart';
import 'package:siladesbeng_mobile/features/transaction/transaction_history_page.dart';
import 'package:siladesbeng_mobile/features/profile/profile_page.dart';
import 'package:siladesbeng_mobile/features/admin/admin_portal_page.dart';
import 'widgets/custom_bottom_nav.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  String _userRole = 'warga';
  final GlobalKey<TransactionHistoryPageState> _activityKey =
      GlobalKey<TransactionHistoryPageState>();

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userRole = prefs.getString('user_role') ?? 'warga';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = _userRole == 'rt' || _userRole == 'rw';
    final String adminLabel = _userRole == 'rt'
        ? 'Admin RT'
        : (_userRole == 'rw' ? 'Admin RW' : 'Admin');

    final List<Widget> pages = isAdmin
        ? [
            HomePage(
              onNavigateToProfile: () {
                setState(() {
                  _currentIndex = 4; // Switch ke tab Profil (indeks ke-4 jika ada Admin Tab)
                });
              },
              onNavigateToNews: () {
                setState(() {
                  _currentIndex = 1; // Switch ke tab Kabar Daerah
                });
              },
            ),
            const KabarDaerahPage(),
            const AdminPortalPage(), // Tab Eksekutif Pengurus di Posisi Pusat Footer Nav
            TransactionHistoryPage(key: _activityKey),
            const ProfilePage(),
          ]
        : [
            HomePage(
              onNavigateToProfile: () {
                setState(() {
                  _currentIndex = 3; // Switch ke tab Profil (indeks ke-3 untuk warga biasa)
                });
              },
              onNavigateToNews: () {
                setState(() {
                  _currentIndex = 1; // Switch ke tab Kabar Daerah
                });
              },
            ),
            const KabarDaerahPage(),
            TransactionHistoryPage(key: _activityKey),
            const ProfilePage(),
          ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        isAdmin: isAdmin,
        adminRoleLabel: adminLabel,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          final int activityTabIndex = isAdmin ? 3 : 2;
          if (index == activityTabIndex) {
            _activityKey.currentState?.checkLoginStatus();
          }
        },
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
    );
  }
}

