import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart'; // Add this import
import 'genre_manga_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Map<String, String>> _allCategories = [];
  List<Map<String, String>> _filteredCategories = [];
  String _searchQuery = '';
  bool _isLoading = false;
  String _errorMessage = '';

  // Use the same curated list as home screen, but with more genres
  final List<Map<String, String>> _curatedCategories = [
    {'name': 'Action', 'value': 'action'},
    {'name': 'Adventure', 'value': 'adventure'},
    {'name': 'Comedy', 'value': 'comedy'},
    {'name': 'Drama', 'value': 'drama'},
    {'name': 'Fantasy', 'value': 'fantasy'},
    {'name': 'Horror', 'value': 'horror'},
    {'name': 'Romance', 'value': 'romance'},
    {'name': 'Sci-Fi', 'value': 'sci-fi'},
    {'name': 'Slice of Life', 'value': 'slice-of-life'},
    {'name': 'Sports', 'value': 'sports'},
    {'name': 'Supernatural', 'value': 'supernatural'},
    {'name': 'Thriller', 'value': 'thriller'},
    {'name': 'Mystery', 'value': 'mystery'},
    {'name': 'Historical', 'value': 'historical'},
    {'name': 'Martial Arts', 'value': 'martial-arts'},
    {'name': 'Shounen', 'value': 'shounen'},
    {'name': 'Shoujo', 'value': 'shoujo'},
    {'name': 'Seinen', 'value': 'seinen'},
    {'name': 'Josei', 'value': 'josei'},
    {'name': 'Isekai', 'value': 'isekai'},
    {'name': 'Magic', 'value': 'magic'},
    {'name': 'School Life', 'value': 'school-life'},
    {'name': 'Psychological', 'value': 'psychological'},
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Option 1: Use curated list (recommended)
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate loading
      setState(() {
        _allCategories = _curatedCategories;
        _filteredCategories = _curatedCategories;
        _isLoading = false;
      });

      // Option 2: Validate API genres against working ones (uncomment if you prefer)
      // final apiGenres = await ApiService.getGenres();
      // final validatedCategories = <Map<String, String>>[];
      // 
      // for (final curatedCategory in _curatedCategories) {
      //   if (apiGenres.any((apiGenre) => 
      //       apiGenre.toLowerCase() == curatedCategory['value']!.toLowerCase())) {
      //     validatedCategories.add(curatedCategory);
      //   }
      // }
      // 
      // setState(() {
      //   _allCategories = validatedCategories;
      //   _filteredCategories = validatedCategories;
      //   _isLoading = false;
      // });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load categories. Please try again.';
      });
    }
  }

  void _filterCategories(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCategories = _allCategories;
      } else {
        _filteredCategories = _allCategories
            .where((category) =>
                category['name']!.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text(
          'Categories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.creamWhite,
          ),
        ),
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.creamWhite),
        actions: [
          if (!_isLoading && _allCategories.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCategories,
              tooltip: 'Refresh categories',
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explore Categories',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoading 
                    ? 'Loading categories...'
                    : 'Find manga by genre - ${_filteredCategories.length} categories available',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (!_isLoading && _allCategories.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: _filterCategories,
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surfaceColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _buildCategoriesGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading categories...');
    }

    if (_errorMessage.isNotEmpty) {
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
                'Failed to Load Categories',
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
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadCategories,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
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

    if (_filteredCategories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'No categories found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      color: AppColors.accentOrange,
      backgroundColor: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: _filteredCategories.length,
          itemBuilder: (context, index) {
            final category = _filteredCategories[index];
            return _buildCategoryCard(category);
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, String> category) {
    final colors = [
      AppColors.primaryRed,
      AppColors.accentOrange,
      AppColors.blueGray,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.amber,
      Colors.deepOrange,
    ];
    final color = colors[category['name'].hashCode % colors.length];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GenreMangaScreen(genre: category['value']!),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.creamWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    _getGenreIcon(category['name']!),
                    color: AppColors.creamWhite,
                    size: 28,
                  ),
                ),
                const Spacer(),
                Text(
                  category['name']!,
                  style: const TextStyle(
                    color: AppColors.creamWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manga category',
                  style: TextStyle(
                    color: AppColors.creamWhite,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getGenreIcon(String genre) {
    switch (genre.toLowerCase()) {
      case 'action':
        return Icons.flash_on;
      case 'adventure':
        return Icons.explore;
      case 'comedy':
        return Icons.sentiment_very_satisfied;
      case 'drama':
        return Icons.theater_comedy;
      case 'fantasy':
        return Icons.auto_awesome;
      case 'horror':
        return Icons.psychology;
      case 'romance':
        return Icons.favorite;
      case 'sci-fi':
      case 'science fiction':
        return Icons.rocket_launch;
      case 'slice of life':
        return Icons.home;
      case 'sports':
        return Icons.sports_basketball;
      case 'supernatural':
        return Icons.visibility;
      case 'thriller':
        return Icons.warning;
      case 'mystery':
        return Icons.search;
      case 'historical':
        return Icons.castle;
      case 'martial arts':
        return Icons.sports_martial_arts;
      case 'shounen':
        return Icons.boy;
      case 'shoujo':
        return Icons.girl;
      case 'seinen':
        return Icons.man;
      case 'josei':
        return Icons.woman;
      case 'isekai':
        return Icons.transform;
      case 'magic':
      case 'magical':
        return Icons.auto_fix_high;
      case 'school life':
      case 'school':
        return Icons.school;
      case 'psychological':
        return Icons.psychology_alt;
      default:
        return Icons.book;
    }
  }
}