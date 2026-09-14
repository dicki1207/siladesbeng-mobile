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
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _profileKey = GlobalKey();
  final GlobalKey _newsKey = GlobalKey();
  final GlobalKey _adminPortalKey = GlobalKey();

  // Track tab yang sudah pernah dikunjungi (lazy loading)
  final Set<int> _initializedTabs = {0}; // Tab 0 (Home) selalu dimuat

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

  /// Membangun widget tab hanya jika tab sudah pernah dikunjungi.
  /// Jika belum, tampilkan placeholder kosong ringan.
  Widget _buildLazyTab(int index, Widget child) {
    if (_initializedTabs.contains(index)) {
      return child;
    }
    // Placeholder ringan — tidak memuat API apapun
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = _userRole == 'rt' || _userRole == 'rw' || _userRole == 'admin';
    final String adminLabel = _userRole == 'rt'
        ? 'Admin RT'
        : (_userRole == 'rw' ? 'Admin RW' : 'Admin');

    final int profileIndex = isAdmin ? 4 : 3;

    final List<Widget> pages = isAdmin
        ? [
            _buildLazyTab(
              0,
              HomePage(
                key: _homeKey,
                onNavigateToProfile: () {
                  _navigateToTab(4);
                },
                onNavigateToNews: () {
                  _navigateToTab(1);
                },
              ),
            ),
            _buildLazyTab(1, KabarDaerahPage(key: _newsKey)),
            _buildLazyTab(2, AdminPortalPage(key: _adminPortalKey)),
            _buildLazyTab(3, TransactionHistoryPage(key: _activityKey)),
            _buildLazyTab(4, ProfilePage(key: _profileKey)),
          ]
        : [
            _buildLazyTab(
              0,
              HomePage(
                key: _homeKey,
                onNavigateToProfile: () {
                  _navigateToTab(profileIndex);
                },
                onNavigateToNews: () {
                  _navigateToTab(1);
                },
              ),
            ),
            _buildLazyTab(1, KabarDaerahPage(key: _newsKey)),
            _buildLazyTab(2, TransactionHistoryPage(key: _activityKey)),
            _buildLazyTab(3, ProfilePage(key: _profileKey)),
          ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        isAdmin: isAdmin,
        adminRoleLabel: adminLabel,
        onTap: (index) {
          _navigateToTab(index);
          final int activityTabIndex = isAdmin ? 3 : 2;
          if (index == activityTabIndex) {
            _activityKey.currentState?.checkLoginStatus();
          }
        },
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
    );
  }

  /// Navigasi ke tab tertentu. Jika tab belum pernah dimuat,
  /// tandai sebagai initialized sehingga widget-nya akan di-build.
  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
      _initializedTabs.add(index); // Tandai tab ini sudah diinisialisasi
    });
  }
}
