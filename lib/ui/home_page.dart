
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'dart:async'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../services/rss_service.dart';
import '../models/news_item.dart';
import '../constants.dart';
import 'widgets/news_card.dart';
import 'widgets/headline_card.dart';
import 'widgets/sliding_nav_bar.dart';
import 'widgets/detail_overlay.dart';
import 'widgets/glass_container.dart';
import 'widgets/info_overlay.dart';
import 'widgets/news_tab.dart';

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
    _loadTheme(); // Load theme first
    // Delay fetch slightly to ensure UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDark = prefs.getBool('isDark') ?? true; // Default to dark
    });
  }

  Timer? _processingTimer;
  final List<NewsItem> _incomingBuffer = [];
  final Set<String> _seenTitles = {};

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _allItems = []; 
      _incomingBuffer.clear();
      _seenTitles.clear();
    });
    
    // Start periodic "Ticker" to process the queue smoothly
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_incomingBuffer.isNotEmpty && mounted) {
        // Take a small batch to process (prevents frame drops)
        int batchSize = 15;
        int count = 0;
        List<NewsItem> confirmedNewItems = [];
        
        // Remove from head of queue
        while(_incomingBuffer.isNotEmpty && count < batchSize) {
           var item = _incomingBuffer.removeAt(0);
           
           // Efficient O(1) deduplication
           // We use a normalized title key for better matching
           String key = item.title.trim().toLowerCase();
           if (key.length > 50) key = key.substring(0, 50);
           
           if (!_seenTitles.contains(key)) {
             _seenTitles.add(key);
             confirmedNewItems.add(item);
             count++;
           }
        }

        if (confirmedNewItems.isNotEmpty) {
           setState(() {
             _allItems.addAll(confirmedNewItems);
             
             // If this is the VERY first batch that actually added items, hide loading
             if (_isLoading) {
               _isLoading = false;
             }
             
             _updateDisplayItems();
           });
        }
      } else if (!_isLoading && _incomingBuffer.isEmpty) {
        // Queue is empty and loading done? Maybe slow down timer? 
        // For now, keep it hot or cancel? Better keep it for late arrivals.
      }
    });

    // Start streaming
    await _rssService.streamFeeds(onBatchReceived: (batch) {
      if (!mounted) return;
      // Just add to queue, the Ticker handles the rest
      _incomingBuffer.addAll(batch);
    });
    
    // We don't need a "Final Flush" anymore because the Ticker will handle everything naturally.
    // The previous logic forced a flush, but now we assume the ticker will drain the buffer.
    // However, if the stream ends, we might want to ensure the spinner hides if nothing was ever found.
    
    // Wait a bit to ensure potential last items are processed or spinner is hidden if empty
    if (mounted) {
       // Loop/Wait until buffer is empty? 
       // No, just let the stream finish.
       // Only hide loading if we are truly done and have 0 items.
       // But _isLoading is handled in the Timer. 
       // If buffer stays empty for 2 seconds? 
       
       // Just ensures safe state
       await Future.delayed(const Duration(seconds: 2));
       if (mounted && _isLoading && _allItems.isEmpty && _incomingBuffer.isEmpty) {
          setState(() {
            _isLoading = false;
          });
       }
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
  @override
  void dispose() {
    _processingTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
    _pageController.dispose();
    super.dispose();
  }

  
  // Helper to filter Gündem items
  List<NewsItem> _getGundemItems() {
      final now = DateTime.now();
      var items = _allItems.where((item) {
        return item.dateObj.difference(now).inDays.abs() <= 4 && item.score > 0;
      }).toList();
      items.sort((a, b) {
        int cmp = b.score.compareTo(a.score);
        if (cmp != 0) return cmp;
        return b.dateObj.compareTo(a.dateObj);
      });
      return items;
  }

  // Helper to filter All items
  List<NewsItem> _getAllItemsSorted() {
      var items = List<NewsItem>.from(_allItems);
      items.sort((a, b) => b.dateObj.compareTo(a.dateObj));
      return items;
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
    // final accentCol = _isDark ? Colors.cyan[400]! : Colors.blue[600]!; // Used in NewsTab now

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
              NewsTab(
                items: _getGundemItems(),
                onItemTap: _onCardTap,
                isDark: _isDark,
                hasHeadline: true,
                emptyMessage: "Gündeminizde şu an kritik haber yok.\nGenel akışa bakabilirsiniz.",
                isLoading: _isLoading,
              ),
              NewsTab(
                items: _getAllItemsSorted(),
                onItemTap: _onCardTap,
                isDark: _isDark,
                hasHeadline: false,
                emptyMessage: "Haber listesi boş.",
                isLoading: _isLoading,
              ), 
            ],
          ),
          
          
          Positioned(
            top: 0, left: 0, right: 0, 
            child: SafeArea(
              child: AnimationConfiguration.synchronized(
                duration: const Duration(milliseconds: 800),
                child: SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(
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
                                    onPressed: () async {
                                      setState(() => _isDark = !_isDark);
                                      final prefs = await SharedPreferences.getInstance();
                                      prefs.setBool('isDark', _isDark);
                                    },
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
