import 'package:flutter/material.dart';
import '../models/manga_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_widget.dart'; // Add this import
import 'genre_manga_screen.dart';

class GenresScreen extends StatefulWidget {
  const GenresScreen({super.key});

  @override
  State<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends State<GenresScreen> {
  List<String> _genres = [];
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final genres = await ApiService.getGenres();
      setState(() {
        _genres = genres;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
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
            child: const Column(
              children: [
                Text(
                  'Browse by Genres',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Discover manga by your favorite categories',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildGenresList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenresList() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading genres...');
    }

    if (_hasError) {
      return _buildErrorWidget();
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 3,
        ),
        itemCount: _genres.length,
        itemBuilder: (context, index) {
          final genre = _genres[index];
          return _buildGenreCard(genre);
        },
      ),
    );
  }

  Widget _buildGenreCard(String genre) {
    final colors = [
      AppColors.primaryRed,
      AppColors.accentOrange,
      AppColors.blueGray,
      AppColors.surfaceColor,
    ];
    final color = colors[genre.hashCode % colors.length];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GenreMangaScreen(genre: genre),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.creamWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getGenreIcon(genre),
                    color: AppColors.creamWhite,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    genre,
                    style: const TextStyle(
                      color: AppColors.creamWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
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
        return Icons.rocket_launch;
      case 'slice of life':
        return Icons.home;
      case 'sports':
        return Icons.sports_basketball;
      case 'supernatural':
        return Icons.visibility;
      case 'thriller':
        return Icons.warning;
      default:
        return Icons.book;
    }
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
              'Failed to load genres',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your connection and try again.',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadGenres,
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