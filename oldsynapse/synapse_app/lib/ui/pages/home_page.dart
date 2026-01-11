import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/news_provider.dart';
import '../../constants.dart';
import '../widgets/glass_container.dart';
import '../widgets/sliding_nav_bar.dart';
import '../widgets/news_card.dart';
import '../widgets/headline_card.dart';
import '../widgets/detail_overlay.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Initial fetch
    Future.microtask(() => 
      Provider.of<NewsProvider>(context, listen: false).fetchNews()
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NewsProvider>(context);
    final theme = Theme.of(context);
    final isAgenda = provider.mode == NewsMode.agenda;

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 500) {
             provider.setMode(0); // Swipe Right -> Agenda
          } else if (details.primaryVelocity! < -500) {
             provider.setMode(1); // Swipe Left -> General
          }
        },
        child: Stack(
          children: [
            // Background is simplified to Scaffold background, handles animation implicitly by theme switch
            // But we can add an animated container if we want smooth color transition like Flet
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: theme.brightness == Brightness.dark
                      ? [const Color(0xFF000000), const Color(0xFF1E1E1E)]
                      : [const Color(0xFFF2F2F7), const Color(0xFFD1D1D6)],
                ),
              ),
              child: SafeArea(
                 bottom: false,
                 child: RefreshIndicator(
                   color: provider.accentColor,
                   onRefresh: () async {
                     await provider.fetchNews();
                   },
                   child: Column(
                     children: [
                       const SizedBox(height: 100), // Space for header
                       Expanded(
                         child: AnimatedSwitcher(
                           duration: const Duration(milliseconds: 500),
                           transitionBuilder: (Widget child, Animation<double> animation) {
                             return FadeTransition(opacity: animation, child: child);
                           },
                           child: provider.isLoading 
                             ? Center(child: CircularProgressIndicator(color: provider.accentColor))
                             : _buildNewsList(provider),
                         ),
                       ),
                       const SizedBox(height: 100), // Space for bottom nav
                     ],
                   ),
                 ),
              ),
            ),
            
            // Header
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 15,
              right: 15,
              child: GlassContainer(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppConstants.appTitle, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text("İbrahim Nuryağınlı", style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.bug_report, size: 20),
                          onPressed: () => _showDebugConsole(context, provider),
                        ),
                        IconButton(
                          icon: Icon(theme.brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode),
                          onPressed: () => provider.toggleTheme(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => provider.fetchNews(),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),

            // Bottom Nav
            const Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: SlidingNavBar(),
            ),
          ],
        ),
      ),
    );
  }

  void _showDebugConsole(BuildContext context, NewsProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Debug Console", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white54),
              Expanded(
                child: Consumer<NewsProvider>(
                  builder: (context, prov, child) {
                    if (prov.logs.isEmpty) {
                      return const Center(child: Text("No logs yet.", style: TextStyle(color: Colors.white54)));
                    }
                    return ListView.builder(
                      itemCount: prov.logs.length,
                      itemBuilder: (context, index) {
                         return Padding(
                           padding: const EdgeInsets.symmetric(vertical: 2.0),
                           child: Text(prov.logs[index], style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'Courier')),
                         );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewsList(NewsProvider provider) {
    if (provider.news.isEmpty) {
      final msg = provider.mode == NewsMode.agenda 
          ? "Gündeminizde şu an kritik haber yok. Genel akışa bakabilirsiniz."
          : "Haber listesi boş.";
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      itemCount: provider.news.length,
      separatorBuilder: (_, __) => const SizedBox(height: 15),
      itemBuilder: (context, index) {
        final item = provider.news[index];
        // In Agenda mode, first item is HeadlineCard
        if (provider.mode == NewsMode.agenda && index == 0) {
          return HeadlineCard(
            article: item,
            onTap: (article) => showArticleDetail(context, article),
          );
        }
        return NewsCard(
          article: item,
          onTap: (article) => showArticleDetail(context, article),
        );
      },
    );
  }
}
