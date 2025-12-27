
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/news_item.dart';

class DetailOverlay extends StatefulWidget {
  final NewsItem? article;
  final VoidCallback onClose;
  final bool isVisible;
  final bool isDark;

  const DetailOverlay({
    super.key,
    required this.article,
    required this.onClose,
    required this.isVisible,
    required this.isDark,
  });

  @override
  State<DetailOverlay> createState() => _DetailOverlayState();
}

class _DetailOverlayState extends State<DetailOverlay> {
  // Using AnimatedOpacity/Transform for the scale/fade effect
  
  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      // Use inAppWebView for integrated experience
      if (!await launchUrl(uri, mode: LaunchMode.inAppWebView)) {
         print("Could not launch $url");
      }
    } catch (e) {
      print("Launch error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // If not visible and animation done (implied by using AnimatedOpacity), we want it gone.
    // But for simplicity with Stack, we wrap in IgnorePointer
    
    final bg = widget.isDark ? Colors.black : Colors.white;
    final text = widget.isDark ? const Color(0xFFEEEEEE) : Colors.black;
    final subtext = widget.isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666);
    final accent = widget.isDark ? Colors.cyan[400]! : Colors.blue[600]!;

    return IgnorePointer(
      ignoring: !widget.isVisible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: widget.isVisible ? 1.0 : 0.0,
        child: AnimatedScale(
          scale: widget.isVisible ? 1.0 : 0.9,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          child: Container(
            color: bg,
            child: widget.article == null ? const SizedBox() : ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 40, right: 20),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.close, color: text, size: 30),
                      onPressed: widget.onClose,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (widget.article!.image.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: widget.article!.image,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.black12),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
                  ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(int.parse(widget.article!.sourceColor)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(widget.article!.source, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.article!.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: text, fontFamily: 'Roboto'),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    widget.article!.desc,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: subtext),
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: SizedBox(
                    width: 280,
                    height: 60,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new, color: Colors.white),
                      label: const Text("Kaynağa Git ve Oku", style: TextStyle(color: Colors.white, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 10,
                      ),
                      onPressed: () => _launchUrl(widget.article!.url),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
