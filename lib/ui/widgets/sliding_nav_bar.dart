
import 'package:flutter/material.dart';

import 'glass_container.dart';

class SlidingNavBar extends StatefulWidget {
  final Function(int) onTabChange;
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;

  const SlidingNavBar({
    super.key, 
    required this.onTabChange, 
    required this.currentIndex,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  State<SlidingNavBar> createState() => _SlidingNavBarState();
}

class _SlidingNavBarState extends State<SlidingNavBar> {
  @override
  Widget build(BuildContext context) {
    const double totalWidth = 300;
    const double tabWidth = 145;
    
    return GlassContainer(
      borderRadius: 35,
      color: Colors.white.withOpacity(0.1),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: SizedBox(
        width: totalWidth,
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              left: widget.currentIndex == 0 ? 0 : tabWidth + 0, 
              child: Container(
                width: tabWidth,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF29B6F6), 
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTab(0, Icons.flash_on),
                _buildTab(1, Icons.public),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, IconData icon) {
    bool isSelected = widget.currentIndex == index;
    return GestureDetector(
      onTap: () => widget.onTabChange(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 145,
        height: 40,
        child: Center(
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? Colors.white : widget.inactiveColor, 
          ),
        ),
      ),
    );
  }
}
