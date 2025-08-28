import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../models/manga_model.dart';
import '../widgets/manga_card.dart';
import '../widgets/loading_widget.dart'; // Add this import
import '../utils/app_theme.dart';
import '../utils/error_handler.dart';
import 'manga_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  List<Manga> _searchResults = [];
  List<String> _searchSuggestions = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _showSuggestions = false;
  String _errorMessage = '';
  Timer? _debounceTimer;

  // Popular search terms and genres for suggestions
  final List<String> _popularSearches = [
    // Popular manga titles
    'Attack on Titan',
    'One Piece',
    'Naruto',
    'Dragon Ball',
    'Death Note',
    'Demon Slayer',
    'My Hero Academia',
    'Tokyo Ghoul',
    'Bleach',
    'One Punch Man',
    'Jujutsu Kaisen',
    'Chainsaw Man',
    // Popular genres
    'Action',
    'Romance',
    'Comedy',
    'Fantasy',
    'Horror',
    'Drama',
    'Adventure',
    'Supernatural',
    'Slice of life',
    'Mystery',
    'Thriller',
    'Sci fi',
    'Historical',
    'Sports',
    'Manhwa',
    'Webtoons',
    'Isekai',
    'Magic',
    'Martial arts',
    'School life',
    'Psychological',
    'Harem',
    'Shounen',
    'Shoujo',
    'Seinen',
    'Josei',
    'Yaoi',
    'Yuri',
    'Ecchi',
    'Mecha',
    'Medical',
    'Military',
    'Cooking',
    'Music',
    'Time Travel',
    'Reincarnation',
    'Vampires',
    'Zombies',
    'Demons',
    'Monsters',
    'Superhero',
    'Survival',
    'Game'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _searchSuggestions.clear();
      });
      return;
    }

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Create new timer for debounced search suggestions
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _updateSearchSuggestions(query);
    });
  }

  void _onFocusChanged() {
    if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty) {
      _updateSearchSuggestions(_searchController.text);
    } else {
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _updateSearchSuggestions(String query) {
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _searchSuggestions.clear();
      });
      return;
    }

    final suggestions = _popularSearches
        .where((search) => search.toLowerCase().contains(query.toLowerCase()))
        .take(5)
        .toList();

    setState(() {
      _searchSuggestions = suggestions;
      _showSuggestions = suggestions.isNotEmpty && _searchFocusNode.hasFocus;
    });
  }

  Future<void> _searchManga(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
        _errorMessage = '';
        _showSuggestions = false;
      });
      return;
    }

    // Hide suggestions and unfocus
    setState(() {
      _showSuggestions = false;
    });
    _searchFocusNode.unfocus();

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _errorMessage = '';
    });

    try {
      print('Searching for: $query'); // Debug log
      final result = await ApiService.searchManga(query);
      print('Search result: ${result.manga.length} manga found'); // Debug log
      
      if (mounted) {
        setState(() {
          _searchResults = result.manga;
          _isLoading = false;
        });
        
        if (result.manga.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No manga found for "$query"'),
              backgroundColor: AppColors.blueGray,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Search error: $e'); // Debug log
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage(e);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: AppColors.primaryRed,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: AppColors.creamWhite,
              onPressed: () => _searchManga(query),
            ),
          ),
        );
      }
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your connection.';
    } else if (errorString.contains('timeout')) {
      return 'Request timeout. Please try again.';
    } else if (errorString.contains('404')) {
      return 'Search service not found.';
    } else if (errorString.contains('500')) {
      return 'Server error. Please try again later.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _hasSearched = false;
      _errorMessage = '';
      _showSuggestions = false;
      _searchSuggestions.clear();
    });
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    _searchManga(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      resizeToAvoidBottomInset: true, // This helps with keyboard overflow
      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        title: const Text(
          'Search Manga',
          style: TextStyle(
            color: AppColors.creamWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.creamWhite),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar - Fixed at top
            _buildSearchBar(),
            // Results area - Expandable
            Expanded(
              child: Stack(
                children: [
                  _buildSearchResults(),
                  // Suggestions overlay positioned relative to search bar
                  if (_showSuggestions) _buildSuggestionsOverlay(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search for manga titles, authors...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(
                  Icons.search, 
                  color: AppColors.accentOrange,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: _clearSearch,
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.accentOrange,
                    width: 2,
                  ),
                ),
              ),
              onSubmitted: _searchManga,
              textInputAction: TextInputAction.search,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.accentOrange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _searchManga(_searchController.text),
              icon: const Icon(
                Icons.search,
                color: AppColors.creamWhite,
              ),
              tooltip: 'Search',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsOverlay() {
    return Positioned(
      top: 10, // Small gap from search bar
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        color: AppColors.cardBackground,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            shrinkWrap: true,
            itemCount: _searchSuggestions.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: AppColors.surfaceColor,
            ),
            itemBuilder: (context, index) {
              final suggestion = _searchSuggestions[index];
              return ListTile(
                dense: true,
                leading: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                title: Text(
                  suggestion,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                trailing: const Icon(
                  Icons.call_made,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
                onTap: () => _selectSuggestion(suggestion),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Searching...');
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorWidget();
    }

    if (!_hasSearched) {
      return _buildEmptySearchState();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResultsWidget();
    }

    return RefreshIndicator(
      onRefresh: () => _searchManga(_searchController.text),
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
                  const Text(
                    'Search Results',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_searchResults.length} manga found',
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
              childCount: _searchResults.length,
              itemBuilder: (context, index) {
                final manga = _searchResults[index];
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
                  child: MangaCard(manga: manga),
                );
              },
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
              'Search Failed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _searchManga(_searchController.text),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                foregroundColor: AppColors.creamWhite,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.search_off,
              size: 60,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Results Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No manga found for "${_searchController.text}"\nTry different keywords or check your spelling.',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _clearSearch,
                icon: const Icon(Icons.clear),
                label: const Text('Clear Search'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _searchManga(_searchController.text),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  foregroundColor: AppColors.creamWhite,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.search,
              size: 60,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Search for Manga',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter a manga title, author name, or keyword to find your next great read.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildPopularSearches(),
        ],
      ),
    );
  }

  Widget _buildPopularSearches() {
    final displaySearches = _popularSearches.take(10).toList();

    return Column(
      children: [
        const Text(
          'Popular Searches:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: displaySearches.map((search) {
            return GestureDetector(
              onTap: () {
                _searchController.text = search;
                _searchManga(search);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accentOrange.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  search,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}