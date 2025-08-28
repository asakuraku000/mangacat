import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/manga_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/manga_card.dart';
import '../widgets/loading_widget.dart';
import 'manga_detail_screen.dart';

class GenreMangaScreen extends StatefulWidget {
  final String genre;

  const GenreMangaScreen({super.key, required this.genre});

  @override
  State<GenreMangaScreen> createState() => _GenreMangaScreenState();
}

class _GenreMangaScreenState extends State<GenreMangaScreen> {
  List<Manga> _mangaList = [];
  bool _isLoading = false;
  bool _hasError = false;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMangaByGenre();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreManga();
    }
  }

  Future<void> _loadMangaByGenre() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final genreResponse = await ApiService.getMangaByGenre(widget.genre, _currentPage);
      setState(() {
        _mangaList = genreResponse.manga;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreManga() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final genreResponse = await ApiService.getMangaByGenre(widget.genre, nextPage);
      setState(() {
        _mangaList.addAll(genreResponse.manga);
        _currentPage = nextPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshMangaList() async {
    setState(() {
      _currentPage = 1;
    });
    await _loadMangaByGenre();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: Text(
          widget.genre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.creamWhite,
          ),
        ),
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.creamWhite),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _mangaList.isEmpty) {
      return LoadingWidget(message: 'Loading ${widget.genre} manga...');
    }

    if (_hasError && _mangaList.isEmpty) {
      return _buildErrorWidget();
    }

    return RefreshIndicator(
      onRefresh: _refreshMangaList,
      color: AppColors.accentOrange,
      backgroundColor: AppColors.cardBackground,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.genre} Manga',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_mangaList.length} manga found',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childCount: _mangaList.length,
              itemBuilder: (context, index) {
                final manga = _mangaList[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MangaDetailScreen(
                          mangaId: manga.id,
                          title: manga.title, // Added the missing title parameter
                        ),
                      ),
                    );
                  },
                  child: MangaCard(manga: manga),
                );
              },
            ),
          ),
          if (_isLoading && _mangaList.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LoadingWidget(message: 'Loading more ${widget.genre} manga...'),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load ${widget.genre} manga. Please try again.',
              style: const TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMangaByGenre,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                foregroundColor: AppColors.creamWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}