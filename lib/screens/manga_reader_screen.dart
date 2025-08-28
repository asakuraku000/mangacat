import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/manga_model.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/loading_widget.dart';

class MangaReaderScreen extends StatefulWidget {
  final String mangaId;
  final String chapterId;
  final String mangaTitle;

  const MangaReaderScreen({
    super.key,
    required this.mangaId,
    required this.chapterId,
    required this.mangaTitle,
  });

  @override
  State<MangaReaderScreen> createState() => _MangaReaderScreenState();
}

class _MangaReaderScreenState extends State<MangaReaderScreen> {
  ChapterContent? _chapterContent;
  bool _isLoading = false;
  bool _hasError = false;
  bool _showAppBar = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadChapterContent();
    _setFullScreen();
  }

  @override
  void dispose() {
    _exitFullScreen();
    _scrollController.dispose();
    super.dispose();
  }

  void _setFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _loadChapterContent() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final chapterContent = await ApiService.getChapterContent(
        widget.mangaId,
        widget.chapterId,
      );
      setState(() {
        _chapterContent = chapterContent;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _toggleAppBar() {
    setState(() {
      _showAppBar = !_showAppBar;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      extendBodyBehindAppBar: true,
      appBar: _showAppBar
          ? AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.mangaTitle,
                    style: const TextStyle(
                      color: AppColors.creamWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Chapter ${widget.chapterId}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.darkNavy.withOpacity(0.9),
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.creamWhite),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: _showReaderSettings,
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleAppBar,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(
        message: 'Loading chapter...',
      );
    }

    if (_hasError || _chapterContent == null) {
      return _buildErrorWidget();
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _chapterContent!.imageUrls.length,
      itemBuilder: (context, index) {
        return _buildPageImage(index);
      },
    );
  }

  Widget _buildPageImage(int index) {
    final imageUrl = _chapterContent!.imageUrls[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.fitWidth,
        placeholder: (context, url) => Container(
          height: 200,
          color: AppColors.surfaceColor,
          child: const Center(
            child: LoadingWidget(
              message: null, // No message for individual pages
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          color: AppColors.surfaceColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                size: 50,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                'Failed to load page ${index + 1}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() {}); // Retry loading
                },
                child: const Text(
                  'Retry',
                  style: TextStyle(color: AppColors.accentOrange),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReaderSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Reader Settings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(
                Icons.brightness_6,
                color: AppColors.accentOrange,
              ),
              title: const Text(
                'Reading Mode',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: const Text(
                'Vertical scrolling',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              onTap: () {
                // Future: Add reading mode options
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.zoom_in,
                color: AppColors.accentOrange,
              ),
              title: const Text(
                'Zoom Options',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: const Text(
                'Fit to width',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              onTap: () {
                // Future: Add zoom options
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
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
              'Failed to load chapter',
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
              onPressed: _loadChapterContent,
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