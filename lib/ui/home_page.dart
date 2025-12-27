
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import '../services/rss_service.dart';
import '../models/news_item.dart';
import '../constants.dart';
import 'widgets/news_card.dart';
import 'widgets/headline_card.dart';
import 'widgets/sliding_nav_bar.dart';
import 'widgets/detail_overlay.dart';
import 'widgets/glass_container.dart';
import 'widgets/info_overlay.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RssService _rssService = RssService();
  
  List<NewsItem> _allItems = [];
  List<NewsItem> _currentDisplayItems = [];
  bool _isLoading = true;
  int _currentTab = 0; 
  
  // Theme State
  bool _isDark = true;
  
  // Overlay State
  NewsItem? _selectedArticle;
  bool _isOverlayVisible = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    final items = await _rssService.fetchAllFeeds();
    
    if (mounted) {
      setState(() {
        _allItems = items;
        _isLoading = false;
        _updateDisplayItems();
      });
    }
  }

  void _updateDisplayItems() {
    if (_currentTab == 0) {
      
      final now = DateTime.now();
      _currentDisplayItems = _allItems.where((item) {
        return item.dateObj.difference(now).inDays.abs() <= 4 && item.score > 0;
      }).toList();
      _currentDisplayItems.sort((a, b) {
        
        int cmp = b.score.compareTo(a.score);
        if (cmp != 0) return cmp;
        return b.dateObj.compareTo(a.dateObj);
      });
    } else {
      
      _currentDisplayItems = List.from(_allItems);
      _currentDisplayItems.sort((a, b) => b.dateObj.compareTo(a.dateObj));
    }
  }

  void _onTabChange(int index) {
    if (_currentTab == index) return;
    setState(() {
      _currentTab = index;
      _pageController.animateToPage(
        index, 
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut
      );
    });
  }

  void _onCardTap(NewsItem item) {
    setState(() {
      _selectedArticle = item;
      _isOverlayVisible = true;
    });
  }

  void _closeOverlay() {
    setState(() {
      _isOverlayVisible = false;
    });
  }

  PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  
  Widget _buildNewsList(int tabIndex) {
    if (_isLoading) {
      
      return const Center(child: CircularProgressIndicator());
    }

    
    List<NewsItem> items = [];
    if (tabIndex == 0) {
      
      final now = DateTime.now();
      items = _allItems.where((item) {
        return item.dateObj.difference(now).inDays.abs() <= 4 && item.score > 0;
      }).toList();
      items.sort((a, b) {
        int cmp = b.score.compareTo(a.score);
        if (cmp != 0) return cmp;
        return b.dateObj.compareTo(a.dateObj);
      });
    } else {
      
      items = List.from(_allItems);
      items.sort((a, b) => b.dateObj.compareTo(a.dateObj));
    }

    final subtextCol = _isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666);
    final accentCol = _isDark ? Colors.cyan[400]! : Colors.blue[600]!;

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(50.0),
        child: Center(
          child: Text(
            tabIndex == 0 ? "Gündeminizde şu an kritik haber yok.\nGenel akışa bakabilirsiniz." : "Haber listesi boş.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: subtextCol),
          ),
        ),
      );
    }

    return ListView.builder(
      
      key: PageStorageKey<String>("tab_$tabIndex"),
      padding: const EdgeInsets.only(top: 105, bottom: 100, left: 15, right: 15),
      itemCount: items.length,
      itemBuilder: (context, index) {
         if (tabIndex == 0 && index == 0) {
           return HeadlineCard(item: items[0], onTap: _onCardTap, accentColor: accentCol);
         }
         return NewsCard(item: items[index], onTap: _onCardTap, isDark: _isDark);
      },
    );
  }

  void _showInfoDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Info",
      pageBuilder: (context, _, __) {
         return const InfoOverlay();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(opacity: anim1, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    
    final bgColor = _isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final glassColor = _isDark ? const Color(0x1AFFFFFF) : const Color.fromRGBO(255, 255, 255, 0.6);
    final textCol = _isDark ? const Color(0xFFEEEEEE) : Colors.black;
    final subtextCol = _isDark ? const Color(0xFFAAAAAA) : const Color(0xFF666666);
    final iconCol = _isDark ? Colors.white : Colors.black;
    final accentCol = _isDark ? Colors.cyan[400]! : Colors.blue[600]!;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        color: bgColor,
        child: Stack(
        children: [
          
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentTab = index;
              });
            },
            children: [
              _buildNewsList(0), 
              _buildNewsList(1), 
            ],
          ),
          
          
          Positioned(
            top: 20, left: 0, right: 0,
            child: SafeArea( 
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: SizedBox(
                  height: 80,
                  child: GlassContainer(
                    color: glassColor,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppConstants.appTitle, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textCol)),
                            const SizedBox(height: 2),
                            
                            GestureDetector(
                              onTap: () => _showInfoDialog(context),
                              child: Row(
                                children: [
                                  Text("İbrahim Nuryağınlı", style: TextStyle(fontSize: 10, color: subtextCol)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.info_outline, size: 12, color: subtextCol)
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(_isDark ? Icons.light_mode : Icons.dark_mode, color: iconCol),
                              onPressed: () => setState(() => _isDark = !_isDark),
                            ),
                            IconButton(
                              icon: Icon(Icons.refresh, color: iconCol),
                              onPressed: _fetchData,
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          
          Positioned(
            bottom: 30, left: 0, right: 0,
            child: Center(
              child: SlidingNavBar(
                currentIndex: _currentTab,
                onTabChange: _onTabChange,
                activeColor: iconCol,
                inactiveColor: _isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
              ),
            ),
          ),

          
          DetailOverlay(
            article: _selectedArticle,
            onClose: _closeOverlay,
            isVisible: _isOverlayVisible,
            isDark: _isDark,
          ),
        ],
      ),
      ),
    );
  }
}
