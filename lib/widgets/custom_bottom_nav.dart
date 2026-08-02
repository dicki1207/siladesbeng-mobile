import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isAdmin;
  final String adminRoleLabel;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isAdmin = false,
    this.adminRoleLabel = 'Admin RT',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: isAdmin
                ? [
                    _buildNavItem(context, 0, Icons.home_rounded, 'Beranda'),
                    _buildNavItem(context, 1, Icons.article_outlined, 'Kabar Daerah'),
                    _buildAdminNavItem(context, 2, Icons.admin_panel_settings_rounded, adminRoleLabel),
                    _buildNavItem(context, 3, Icons.receipt_long_outlined, 'Aktivitas'),
                    _buildNavItem(context, 4, Icons.person_outline, 'Profil'),
                  ]
                : [
                    _buildNavItem(context, 0, Icons.home_rounded, 'Beranda'),
                    _buildNavItem(context, 1, Icons.article_outlined, 'Kabar Daerah'),
                    _buildNavItem(context, 2, Icons.receipt_long_outlined, 'Aktivitas'),
                    _buildNavItem(context, 3, Icons.person_outline, 'Profil'),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor.withAlpha(30)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : (Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(170)),
                size: 25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : (Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(170)),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = currentIndex == index;
    const Color adminColor = Color(0xFFF59E0B); // Warna emas/amber khas pengurus desa

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? adminColor.withAlpha(45)
                    : adminColor.withAlpha(15),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? adminColor : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? adminColor
                    : adminColor.withAlpha(200),
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                color: isSelected ? adminColor : adminColor.withAlpha(200),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
