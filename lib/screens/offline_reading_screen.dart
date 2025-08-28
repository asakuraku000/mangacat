
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:io';
import '../models/manga_model.dart';
import '../services/local_storage_service.dart';
import '../utils/app_theme.dart';
import 'offline_chapter_reader_screen.dart';

class OfflineReadingScreen extends StatefulWidget {
  const OfflineReadingScreen({super.key});

  @override
  State<OfflineReadingScreen> createState() => _OfflineReadingScreenState();
}

class _OfflineReadingScreenState extends State<OfflineReadingScreen> {
  List<OfflineManga> _offlineManga = [];
  bool _isLoading = true;
  double _storageSize = 0;

  @override
  void initState() {
    super.initState();
    _loadOfflineManga();
    _loadStorageSize();
  }

  Future<void> _loadOfflineManga() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final offlineManga = await LocalStorageService.getOfflineManga();
      setState(() {
        _offlineManga = offlineManga;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStorageSize() async {
    final size = await LocalStorageService.getOfflineStorageSize();
    setState(() {
      _storageSize = size;
    });
  }

  Future<void> _deleteOfflineManga(OfflineManga manga) async {
    try {
      for (final chapter in manga.chapters) {
        await LocalStorageService.removeOfflineChapter(manga.id, chapter.chapterId);
      }
      await _loadOfflineManga();
      await _loadStorageSize();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${manga.title} removed from offline storage'),
            backgroundColor: AppColors.blueGray,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing offline manga: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _clearAllOfflineData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Clear All Offline Data',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete all offline manga? This will free up ${_storageSize.toStringAsFixed(1)} MB of storage.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await LocalStorageService.clearAllOfflineData();
                await _loadOfflineManga();
                await _loadStorageSize();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All offline data cleared'),
                      backgroundColor: AppColors.blueGray,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error clearing offline data: $e'),
                      backgroundColor: AppColors.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text(
          'Offline Reading',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.creamWhite,
          ),
        ),
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.creamWhite),
        actions: [
          if (_offlineManga.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAllOfflineData,
              tooltip: 'Clear all offline data',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadOfflineManga();
          await _loadStorageSize();
        },
        color: AppColors.accentOrange,
        backgroundColor: AppColors.cardBackground,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
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
                  'Downloaded Manga',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${_offlineManga.length} manga • ${_storageSize.toStringAsFixed(1)} MB used',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.cloud_off,
                      color: AppColors.accentOrange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.accentOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_offlineManga.isEmpty)
          SliverFillRemaining(
            child: _buildEmptyOfflineWidget(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final manga = _offlineManga[index];
                  return _buildOfflineMangaCard(manga);
                },
                childCount: _offlineManga.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildOfflineMangaCard(OfflineManga manga) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.cardBackground,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: File(manga.imgUrl).existsSync()
                        ? DecorationImage(
                            image: FileImage(File(manga.imgUrl)),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: AppColors.surfaceColor,
                  ),
                  child: !File(manga.imgUrl).existsSync()
                      ? const Icon(
                          Icons.image,
                          color: AppColors.textSecondary,
                          size: 30,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manga.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'By ${manga.author}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.download_done,
                            color: AppColors.accentOrange,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${manga.chapters.length} chapters',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textSecondary,
                  ),
                  color: AppColors.surfaceColor,
                  onSelected: (value) {
                    if (value == 'delete') {
                      _confirmDeleteManga(manga);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppColors.primaryRed, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Downloaded ${_formatDate(manga.downloadedAt)}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: manga.chapters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final chapter = manga.chapters[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OfflineChapterReaderScreen(
                            manga: manga,
                            chapter: chapter,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accentOrange,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Ch ${chapter.chapterId}',
                        style: const TextStyle(
                          color: AppColors.accentOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteManga(OfflineManga manga) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text(
          'Delete Offline Manga',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete "${manga.title}" and all its downloaded chapters?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteOfflineManga(manga);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.primaryRed),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildEmptyOfflineWidget() {
    return Center(
      child: Padding(
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
                Icons.cloud_off,
                size: 60,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Offline Manga',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Download chapters to read them offline without an internet connection. Look for the download button in the chapter reader.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.explore),
              label: const Text('Browse Manga'),
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
}
