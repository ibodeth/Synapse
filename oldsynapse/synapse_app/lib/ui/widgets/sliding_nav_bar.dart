import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/news_provider.dart';
import 'glass_container.dart';

class SlidingNavBar extends StatelessWidget {
  const SlidingNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NewsProvider>(context);
    final isAgenda = provider.mode == NewsMode.agenda;

    return Center(
      child: GlassContainer(
        width: 330,
        height: 65,
        borderRadius: 35,
        padding: const EdgeInsets.all(5),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              left: isAgenda ? 0 : 160,
              top: 0,
              bottom: 0,
              width: 160,
              child: Container(
                decoration: BoxDecoration(
                  color: provider.accentColor,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(
                  context,
                  Icons.flash_on,
                  0,
                  isActive: isAgenda,
                  onTap: () => provider.setMode(0),
                ),
                 _buildNavItem(
                  context,
                  Icons.public,
                  1,
                  isActive: !isAgenda,
                  onTap: () => provider.setMode(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, int index, 
      {required bool isActive, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 160,
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: isActive 
              ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white) 
              : (Theme.of(context).brightness == Brightness.dark ? Colors.white54 : Colors.black54),
          size: 28,
        ),
      ),
    );
  }
}
