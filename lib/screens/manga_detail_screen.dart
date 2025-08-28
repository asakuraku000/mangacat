import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/manga_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_widget.dart'; // Add this import
import 'chapter_reader_screen.dart';

class MangaDetailScreen extends StatefulWidget {
  final String mangaId;
  final String title;

  const MangaDetailScreen({
    super.key,
    required this.mangaId,
    required this.title,
  });

  @override
  State<MangaDetailScreen> createState() => _MangaDetailScreenState();
}

class _MangaDetailScreenState extends State<MangaDetailScreen> {
  MangaDetail? _mangaDetail;
  bool _isLoading = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadMangaDetail();
    _checkFavoriteStatus();
  }

  Future<void> _loadMangaDetail() async {
    try {
      final detail = await ApiService.getMangaDetail(widget.mangaId);
      setState(() {
        _mangaDetail = detail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading manga details: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final isFavorite = await LocalStorageService.isFavorite(widget.mangaId);
    setState(() {
      _isFavorite = isFavorite;
    });
  }

  Future<void> _toggleFavorite() async {
    if (_mangaDetail == null) return;

    try {
      if (_isFavorite) {
        await LocalStorageService.removeFromFavorites(widget.mangaId);
        setState(() {
          _isFavorite = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removed from favorites'),
              backgroundColor: AppColors.blueGray,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        final favoriteManga = FavoriteManga(
          id: _mangaDetail!.id,
          title: _mangaDetail!.title,
          imgUrl: _mangaDetail!.imageUrl,
          author: _mangaDetail!.author,
          dateAdded: DateTime.now(),
        );
        await LocalStorageService.addToFavorites(favoriteManga);
        setState(() {
          _isFavorite = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to favorites'),
              backgroundColor: AppColors.accentOrange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorites: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: _isLoading
          ? const LoadingWidget(message: 'Loading manga details...')
          : _mangaDetail == null
              ? const Center(
                  child: Text(
                    'Failed to load manga details',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 300,
                      pinned: true,
                      backgroundColor: AppColors.darkNavy,
                      iconTheme: const IconThemeData(color: AppColors.creamWhite),
                      actions: [
                        IconButton(
                          icon: Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite ? AppColors.primaryRed : AppColors.creamWhite,
                          ),
                          onPressed: _toggleFavorite,
                          tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          _mangaDetail!.title,
                          style: const TextStyle(
                            color: AppColors.creamWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: _mangaDetail!.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.cardBackground,
                                child: const Center(
                                  child: LoadingWidget(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.cardBackground,
                                child: const Icon(
                                  Icons.error,
                                  color: AppColors.errorColor,
                                  size: 50,
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    AppColors.darkNavy.withOpacity(0.8),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoSection(),
                            const SizedBox(height: 24),
                            _buildGenreSection(),
                            const SizedBox(height: 24),
                            _buildChapterList(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Information',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Author', _mangaDetail!.author),
            _buildInfoRow('Status', _mangaDetail!.status),
            _buildInfoRow('Views', _mangaDetail!.views),
            _buildInfoRow('Rating', _mangaDetail!.rating),
            _buildInfoRow('Last Updated', _mangaDetail!.lastUpdated),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenreSection() {
    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Genres',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _mangaDetail!.genres.map((genre) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.accentOrange),
                  ),
                  child: Text(
                    genre,
                    style: const TextStyle(
                      color: AppColors.accentOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterList() {
    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chapters (${_mangaDetail!.chapters.length})',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _mangaDetail!.chapters.length,
              separatorBuilder: (context, index) => const Divider(
                color: AppColors.surfaceColor,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final chapter = _mangaDetail!.chapters[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.accentOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    chapter.chapterId,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Views: ${chapter.views} • ${chapter.uploaded}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChapterReaderScreen(
                          mangaId: widget.mangaId,
                          chapterId: chapter.chapterId,
                          title: _mangaDetail!.title,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}