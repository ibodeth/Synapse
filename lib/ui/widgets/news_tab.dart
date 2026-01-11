import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/news_item.dart';
import 'news_card.dart';
import 'headline_card.dart';

class NewsTab extends StatefulWidget {
  final List<NewsItem> items;
  final Function(NewsItem) onItemTap;
  final bool isDark;
  final bool hasHeadline;
  final String emptyMessage;
  final bool isLoading;

  const NewsTab({
    super.key,
    required this.items,
    required this.onItemTap,
    required this.isDark,
    required this.hasHeadline,
    required this.emptyMessage,
    required this.isLoading,
  });

  @override
  State<NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final subtextCol = widget.isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666);
    final accentCol = widget.isDark ? Colors.cyan[400]! : Colors.blue[600]!;

    if (widget.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(50.0),
        child: Center(
          child: Text(
            widget.emptyMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: subtextCol),
          ),
        ),
      );
    }

    return AnimationLimiter(
      child: ListView.builder(
        // Key logic is handled by parent or standard reconstruction, 
        // but PageStorageKey helps scroll position too.
        // We can accept a key from parent if needed, but AutomaticKeepAlive handles the widget state.
        padding: const EdgeInsets.only(top: 105, bottom: 100, left: 15, right: 15),
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
           Widget child;
           if (widget.hasHeadline && index == 0) {
             child = HeadlineCard(
               item: widget.items[0], 
               onTap: widget.onItemTap, 
               accentColor: accentCol
             );
           } else {
             child = NewsCard(
               item: widget.items[index], 
               onTap: widget.onItemTap, 
               isDark: widget.isDark
             );
           }
           
           return AnimationConfiguration.staggeredList(
             position: index,
             duration: const Duration(milliseconds: 375),
             child: SlideAnimation(
               verticalOffset: 50.0,
               child: FadeInAnimation(
                 child: child,
               ),
             ),
           );
        },
      ),
    );
  }
}
