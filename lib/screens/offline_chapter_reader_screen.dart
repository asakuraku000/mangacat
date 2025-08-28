
import 'package:flutter/material.dart';
import 'dart:io';
import '../models/manga_model.dart';
import '../utils/app_theme.dart';

class OfflineChapterReaderScreen extends StatefulWidget {
  final OfflineManga manga;
  final OfflineChapter chapter;

  const OfflineChapterReaderScreen({
    super.key,
    required this.manga,
    required this.chapter,
  });

  @override
  State<OfflineChapterReaderScreen> createState() => _OfflineChapterReaderScreenState();
}

class _OfflineChapterReaderScreenState extends State<OfflineChapterReaderScreen> {
  final ScrollController _scrollController = ScrollController();

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
              widget.manga.title,
              style: const TextStyle(
                color: AppColors.creamWhite,
                fontSize: 16,
              ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.cloud_off,
                  color: AppColors.accentOrange,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Chapter ${widget.chapter.chapterId} (Offline)',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: AppColors.creamWhite),
      ),
      body: widget.chapter.localImagePaths.isEmpty
          ? _buildErrorWidget()
          : ListView.builder(
              controller: _scrollController,
              itemCount: widget.chapter.localImagePaths.length,
              itemBuilder: (context, index) {
                return _buildPageImage(index);
              },
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

  Widget _buildPageImage(int index) {
    final imagePath = widget.chapter.localImagePaths[index];
    final file = File(imagePath);

    if (!file.existsSync()) {
      return Container(
        height: 200,
        margin: const EdgeInsets.only(bottom: 4),
        color: AppColors.cardBackground,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                color: AppColors.errorColor,
                size: 50,
              ),
              const SizedBox(height: 8),
              Text(
                'Page ${index + 1} not found',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Image.file(
        file,
        fit: BoxFit.fitWidth,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: AppColors.cardBackground,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.broken_image,
                    color: AppColors.errorColor,
                    size: 50,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load page ${index + 1}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
              'Chapter Not Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This chapter has no pages or the files are missing.',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
