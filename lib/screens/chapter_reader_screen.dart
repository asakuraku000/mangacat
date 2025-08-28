import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/manga_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../widgets/loading_widget.dart'; // Add this import
import '../utils/app_theme.dart';

class ChapterReaderScreen extends StatefulWidget {
  final String mangaId;
  final String chapterId;
  final String title;

  const ChapterReaderScreen({
    super.key,
    required this.mangaId,
    required this.chapterId,
    required this.title,
  });

  @override
  State<ChapterReaderScreen> createState() => _ChapterReaderScreenState();
}

class _ChapterReaderScreenState extends State<ChapterReaderScreen> {
  ChapterContent? _chapterContent;
  bool _isLoading = true;
  bool _isDownloading = false;
  bool _isOffline = false;
  int _currentPage = 0;
  MangaDetail? _mangaDetail;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadChapterContent();
    _checkOfflineStatus();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Calculate current page based on scroll position
    if (_chapterContent != null && _chapterContent!.imageUrls.isNotEmpty) {
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final currentScrollPosition = _scrollController.offset;
      final totalPages = _chapterContent!.imageUrls.length;
      
      if (maxScrollExtent > 0) {
        final progress = (currentScrollPosition / maxScrollExtent).clamp(0.0, 1.0);
        final newPage = (progress * totalPages).round();
        
        if (newPage != _currentPage) {
          setState(() {
            _currentPage = newPage;
          });
          _saveReadingProgress();
        }
      }
    }
  }

  Future<void> _saveReadingProgress() async {
    if (_chapterContent != null && _mangaDetail != null) {
      await LocalStorageService.saveReadingProgress(
        mangaId: widget.mangaId,
        mangaTitle: widget.title,
        mangaImageUrl: _mangaDetail!.imageUrl,
        chapterId: widget.chapterId,
        currentPage: _currentPage,
        totalPages: _chapterContent!.imageUrls.length,
      );
    }
  }

  Future<void> _loadChapterContent() async {
    try {
      final content = await ApiService.getChapterContent(widget.mangaId, widget.chapterId);
      final mangaDetail = await ApiService.getMangaDetail(widget.mangaId);
      
      setState(() {
        _chapterContent = content;
        _mangaDetail = mangaDetail;
        _isLoading = false;
      });
      
      // Save initial reading progress
      _saveReadingProgress();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading chapter: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _checkOfflineStatus() async {
    final isOffline = await LocalStorageService.isChapterOffline(widget.mangaId, widget.chapterId);
    setState(() {
      _isOffline = isOffline;
    });
  }

  Future<void> _downloadChapter() async {
    if (_chapterContent == null || _isDownloading || _mangaDetail == null) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      await LocalStorageService.downloadChapterForOffline(
        mangaId: widget.mangaId,
        mangaTitle: widget.title,
        mangaImageUrl: _mangaDetail!.imageUrl,
        mangaAuthor: _mangaDetail!.author,
        chapterContent: _chapterContent!,
      );

      setState(() {
        _isOffline = true;
        _isDownloading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chapter downloaded for offline reading'),
            backgroundColor: AppColors.accentOrange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading chapter: $e'),
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
      appBar: AppBar(
        backgroundColor: AppColors.darkNavy,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                color: AppColors.creamWhite,
                fontSize: 16,
              ),
            ),
            Row(
              children: [
                Text(
                  _chapterContent?.chapter ?? widget.chapterId,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (_chapterContent != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${_currentPage + 1}/${_chapterContent!.imageUrls.length}',
                    style: const TextStyle(
                      color: AppColors.accentOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: AppColors.creamWhite),
        actions: [
          if (_chapterContent != null)
            IconButton(
              icon: _isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.creamWhite),
                      ),
                    )
                  : Icon(
                      _isOffline ? Icons.download_done : Icons.download,
                      color: _isOffline ? AppColors.accentOrange : AppColors.creamWhite,
                    ),
              onPressed: _isOffline || _isDownloading ? null : _downloadChapter,
              tooltip: _isOffline 
                  ? 'Downloaded for offline reading'
                  : _isDownloading 
                      ? 'Downloading...' 
                      : 'Download for offline reading',
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading chapter...')
          : _chapterContent == null
              ? const Center(
                  child: Text(
                    'Failed to load chapter',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : Column(
                  children: [
                    // Progress bar
                    if (_chapterContent!.imageUrls.isNotEmpty)
                      Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: LinearProgressIndicator(
                          value: _chapterContent!.imageUrls.isEmpty 
                              ? 0.0 
                              : (_currentPage + 1) / _chapterContent!.imageUrls.length,
                          backgroundColor: AppColors.cardBackground,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentOrange),
                        ),
                      ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _chapterContent!.imageUrls.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: CachedNetworkImage(
                              imageUrl: _chapterContent!.imageUrls[index],
                              fit: BoxFit.fitWidth,
                              placeholder: (context, url) => Container(
                                height: 200,
                                color: AppColors.cardBackground,
                                child: const Center(
                                  child: LoadingWidget(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 200,
                                color: AppColors.cardBackground,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: AppColors.errorColor,
                                    size: 50,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "scroll_to_top",
            mini: true,
            backgroundColor: AppColors.accentOrange,
            onPressed: () {
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
            child: const Icon(Icons.keyboard_arrow_up, color: AppColors.creamWhite),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "scroll_to_bottom",
            mini: true,
            backgroundColor: AppColors.accentOrange,
            onPressed: () {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            },
            child: const Icon(Icons.keyboard_arrow_down, color: AppColors.creamWhite),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}