import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/news_item.dart';
import '../../providers/news_provider.dart';

class DetailOverlay extends StatelessWidget {
  final NewsItem article;
  final VoidCallback onClose;

  const DetailOverlay({Key? key, required this.article, required this.onClose}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<NewsProvider>(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Uses opaque background as requested by "Overlay" in Python code was full screen
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20, right: 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(Icons.close, size: 30, color: theme.iconTheme.color),
                    onPressed: onClose,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              CachedNetworkImage(
                imageUrl: article.image,

                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: article.sourceColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  article.source,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  article.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  article.description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text("Kaynağa Git ve Oku"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 10,
                  minimumSize: const Size(280, 60),
                ),
                onPressed: () async {
                   try {
                     String urlStr = article.url.trim();
                     // Fix common malformed URL issues if any
                     if (!urlStr.startsWith("http")) {
                        urlStr = "https://$urlStr";
                     }
                     
                     final Uri url = Uri.parse(urlStr);
                     if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                        debugPrint("Could not launch $url");
                     }
                   } catch (e) {
                     debugPrint("Error launching URL: $e");
                   }
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper to show modal
void showArticleDetail(BuildContext context, NewsItem article) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Close",
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => DetailOverlay(
      article: article, 
      onClose: () => Navigator.of(context).pop(),
    ),
    transitionBuilder: (context, anim1, anim2, child) {
       return FadeTransition(
         opacity: anim1,
         child: ScaleTransition(
           scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack)),
           child: child,
         ),
       );
    },
  );
}
