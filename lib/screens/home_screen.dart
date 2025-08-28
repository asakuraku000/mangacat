import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/sidebar_drawer.dart';
import '../widgets/manga_grid.dart';
import '../widgets/category_tabs.dart';
import '../widgets/loading_widget.dart'; // Add this import
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../models/manga_model.dart'; // This already contains ReadingProgress
import '../utils/app_theme.dart';
import 'search_screen.dart';
import 'manga_detail_screen.dart';
import 'chapter_reader_screen.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Manga> _mangaList = [];
  List<Manga> _topPicksManga = [];
  List<ReadingProgress> _continueReading = [];
  bool _isLoading = true;
  String _selectedGenre = 'all';
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();
  final PageController _carouselController = PageController();
  Timer? _carouselTimer;
  int _currentCarouselIndex = 0;
  
  final List<Map<String, String>> _categories = [
    {'name': 'All', 'value': 'all'},
    {'name': 'Action', 'value': 'action'},
    {'name': 'Romance', 'value': 'romance'},
    {'name': 'Comedy', 'value': 'comedy'},
    {'name': 'Drama', 'value': 'drama'},
    {'name': 'Fantasy', 'value': 'fantasy'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadHomeData();
    _scrollController.addListener(_onScroll);
  }

  void _startCarouselAutoScroll() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_topPicksManga.isNotEmpty && _carouselController.hasClients) {
        _currentCarouselIndex = (_currentCarouselIndex + 1) % _topPicksManga.length;
        _carouselController.animateToPage(
          _currentCarouselIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopCarouselAutoScroll() {
    _carouselTimer?.cancel();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreManga();
    }
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoading = true;
    });
    
    await Future.wait([
      _loadContinueReading(),
      _loadTopPicks(),
      _loadMangaList(),
    ]);
    
    setState(() {
      _isLoading = false;
    });
    
    // Start auto-scroll after data is loaded
    if (_topPicksManga.isNotEmpty) {
      _startCarouselAutoScroll();
    }
  }

  Future<void> _loadContinueReading() async {
    try {
      final readingHistory = await LocalStorageService.getReadingHistory();
      setState(() {
        _continueReading = readingHistory.take(10).toList();
      });
    } catch (e) {
      print('Error loading continue reading: $e');
    }
  }

  Future<void> _loadTopPicks() async {
    try {
      // Load top picks (you can modify this to use a specific API endpoint)
      final manga = await ApiService.getMangaList(1);
      setState(() {
        _topPicksManga = manga.take(5).toList();
      });
    } catch (e) {
      print('Error loading top picks: $e');
    }
  }

  Future<void> _loadMangaList() async {
    try {
      List<Manga> manga;
      if (_selectedGenre == 'all') {
        manga = await ApiService.getMangaList(_currentPage);
      } else {
        final response = await ApiService.getMangaByGenre(_selectedGenre, _currentPage);
        manga = response.manga;
      }
      
      setState(() {
        if (_currentPage == 1) {
          _mangaList = manga;
        } else {
          _mangaList.addAll(manga);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading manga: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreManga() async {
    if (!_isLoading) {
      setState(() {
        _currentPage++;
      });
      await _loadMangaList();
    }
  }

  void _onCategoryChanged(String genre) {
    setState(() {
      _selectedGenre = genre;
      _currentPage = 1;
    });
    _loadMangaList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _carouselController.dispose();
    _stopCarouselAutoScroll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      drawer: const SidebarDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        title: const Text(
          'Manga Cat',
          style: TextStyle(
            color: AppColors.creamWhite,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            icon: const Icon(Icons.search, color: AppColors.creamWhite),
          ),
        ],
        iconTheme: const IconThemeData(color: AppColors.creamWhite),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading manga...')
          : RefreshIndicator(
              onRefresh: _loadHomeData,
              color: AppColors.accentOrange,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Top Picks Carousel
                  if (_topPicksManga.isNotEmpty) _buildTopPicksCarousel(),
                  
                  // Continue Reading Section
                  if (_continueReading.isNotEmpty) _buildContinueReadingSection(),
                  
                  // Category Tabs
                  SliverToBoxAdapter(
                    child: CategoryTabs(
                      categories: _categories,
                      onCategoryChanged: _onCategoryChanged,
                      selectedGenre: _selectedGenre,
                    ),
                  ),
                  
                  // Manga Grid with increased spacing
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // Added top padding for spacing from tabs
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 20, // Increased from 16 to 20
                        mainAxisSpacing: 20,  // Increased from 16 to 20
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final manga = _mangaList[index];
                          return _buildMangaCard(manga);
                        },
                        childCount: _mangaList.length,
                      ),
                    ),
                  ),
                  
                  // Loading indicator for pagination
                  if (_isLoading && _mangaList.isNotEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: LoadingWidget(message: 'Loading more...'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildTopPicksCarousel() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Top Picks',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTapDown: (_) => _stopCarouselAutoScroll(),
            onTapUp: (_) => _startCarouselAutoScroll(),
            onTapCancel: () => _startCarouselAutoScroll(),
            child: SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _carouselController,
                onPageChanged: (index) {
                  setState(() {
                    _currentCarouselIndex = index;
                  });
                },
                itemCount: _topPicksManga.length,
                itemBuilder: (context, index) {
                  final manga = _topPicksManga[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MangaDetailScreen(
                            mangaId: manga.id,
                            title: manga.title,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: manga.imgUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => Container(
                                color: AppColors.cardBackground,
                                child: const Center(
                                  child: LoadingWidget(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.cardBackground,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: AppColors.errorColor,
                                  size: 50,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  manga.title,
                                  style: const TextStyle(
                                    color: AppColors.creamWhite,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (manga.latestChapter != null)
                                  Text(
                                    manga.latestChapter!,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Page indicators
          if (_topPicksManga.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _topPicksManga.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentCarouselIndex == index
                        ? AppColors.accentOrange
                        : AppColors.textSecondary.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildContinueReadingSection() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Continue Reading',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            height: 170, // Increased height more for better proportions
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _continueReading.length,
              itemBuilder: (context, index) {
                final progress = _continueReading[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChapterReaderScreen(
                          mangaId: progress.mangaId,
                          chapterId: progress.lastReadChapter,
                          title: progress.mangaTitle,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image with increased height
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            height: 120, // Increased image height significantly
                            width: 100,
                            child: CachedNetworkImage(
                              imageUrl: progress.mangaImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.cardBackground,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.accentOrange,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.cardBackground,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: AppColors.errorColor,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Text area with proper wrapping and flexible sizing
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Manga title with auto-wrap and conditional auto-resize
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final titleTextPainter = TextPainter(
                                      text: TextSpan(
                                        text: progress.mangaTitle,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      maxLines: 2,
                                      textDirection: TextDirection.ltr,
                                    )..layout(maxWidth: constraints.maxWidth);
                                    
                                    final bool needsResize = titleTextPainter.didExceedMaxLines;
                                    
                                    return needsResize 
                                        ? FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.topLeft,
                                            child: SizedBox(
                                              width: constraints.maxWidth,
                                              child: Text(
                                                progress.mangaTitle,
                                                style: const TextStyle(
                                                  color: AppColors.textPrimary,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 2,
                                                textAlign: TextAlign.left,
                                              ),
                                            ),
                                          )
                                        : Text(
                                            progress.mangaTitle,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          );
                                  },
                                ),
                              ),
                              // Chapter info
                              Text(
                                'Chapter ${progress.lastReadChapter}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMangaCard(Manga manga) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MangaDetailScreen(
              mangaId: manga.id,
              title: manga.title,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: manga.imgUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) => Container(
                    color: AppColors.cardBackground,
                    child: const Center(
                      child: LoadingWidget(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.cardBackground,
                    child: const Icon(
                      Icons.broken_image,
                      color: AppColors.errorColor,
                      size: 50,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manga.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (manga.latestChapter != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      manga.latestChapter!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}