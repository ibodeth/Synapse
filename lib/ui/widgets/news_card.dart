
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/news_item.dart';

class NewsCard extends StatelessWidget {
  final NewsItem item;
  final Function(NewsItem) onTap;
  final bool isDark;

  const NewsCard({super.key, required this.item, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color sourceColor = Color(int.parse(item.sourceColor));

    return GestureDetector(
      onTap: () => onTap(item),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141414) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl: item.image,
                width: 85,
                height: 85,
                memCacheWidth: 255, // 85 * 3 (for high pixel density screens)
                memCacheHeight: 255,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(color: Colors.grey),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                         decoration: BoxDecoration(
                           color: sourceColor,
                           borderRadius: BorderRadius.circular(6),
                         ),
                         child: Text(
                           item.source,
                           style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                         ),
                       ),
                       Text(
                         item.dateStr,
                         style: TextStyle(
                           fontSize: 9, 
                           color: isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666)
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 4),
                   Text(
                     item.title,
                     maxLines: 3,
                     overflow: TextOverflow.ellipsis,
                     style: TextStyle(
                       fontSize: 14,
                       fontWeight: FontWeight.bold,
                       color: isDark ? const Color(0xFFEEEEEE) : Colors.black,
                     ),
                   ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
