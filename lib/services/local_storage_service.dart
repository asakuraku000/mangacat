import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/manga_model.dart';

class LocalStorageService {
  static const String _favoritesKey = 'favorites';
  static const String _offlineMangaKey = 'offline_manga';
  static const String _readingHistoryKey = 'reading_history';

  // Favorites Management
  static Future<List<FavoriteManga>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
    return favoritesJson
        .map((json) => FavoriteManga.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<void> addToFavorites(FavoriteManga manga) async {
    final favorites = await getFavorites();
    if (!favorites.any((fav) => fav.id == manga.id)) {
      favorites.add(manga);
      await _saveFavorites(favorites);
    }
  }

  static Future<void> removeFromFavorites(String mangaId) async {
    final favorites = await getFavorites();
    favorites.removeWhere((fav) => fav.id == mangaId);
    await _saveFavorites(favorites);
  }

  static Future<bool> isFavorite(String mangaId) async {
    final favorites = await getFavorites();
    return favorites.any((fav) => fav.id == mangaId);
  }

  static Future<void> _saveFavorites(List<FavoriteManga> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = favorites
        .map((manga) => jsonEncode(manga.toJson()))
        .toList();
    await prefs.setStringList(_favoritesKey, favoritesJson);
  }

  // Offline Reading Management
  static Future<List<OfflineManga>> getOfflineManga() async {
    final prefs = await SharedPreferences.getInstance();
    final offlineMangaJson = prefs.getStringList(_offlineMangaKey) ?? [];
    return offlineMangaJson
        .map((json) => OfflineManga.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<String> _getOfflineDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final offlineDir = Directory('${appDir.path}/offline_manga');
    if (!await offlineDir.exists()) {
      await offlineDir.create(recursive: true);
    }
    return offlineDir.path;
  }

  static Future<void> downloadChapterForOffline({
    required String mangaId,
    required String mangaTitle,
    required String mangaImageUrl,
    required String mangaAuthor,
    required ChapterContent chapterContent,
  }) async {
    try {
      final offlineDir = await _getOfflineDirectory();
      final mangaDir = Directory('$offlineDir/$mangaId');
      if (!await mangaDir.exists()) {
        await mangaDir.create(recursive: true);
      }

      final chapterDir = Directory('${mangaDir.path}/${chapterContent.chapter}');
      if (!await chapterDir.exists()) {
        await chapterDir.create(recursive: true);
      }

      // Download images
      List<String> localImagePaths = [];
      for (int i = 0; i < chapterContent.imageUrls.length; i++) {
        final imageUrl = chapterContent.imageUrls[i];
        final imageName = 'page_${i + 1}.jpg';
        final imagePath = '${chapterDir.path}/$imageName';

        try {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            final file = File(imagePath);
            await file.writeAsBytes(response.bodyBytes);
            localImagePaths.add(imagePath);
          }
        } catch (e) {
          print('Error downloading image $i: $e');
        }
      }

      if (localImagePaths.isNotEmpty) {
        // Create offline chapter
        final offlineChapter = OfflineChapter(
          chapterId: chapterContent.chapter,
          title: chapterContent.title,
          localImagePaths: localImagePaths,
          downloadedAt: DateTime.now(),
        );

        // Update or create offline manga
        final offlineMangaList = await getOfflineManga();
        final existingIndex = offlineMangaList.indexWhere((manga) => manga.id == mangaId);

        if (existingIndex != -1) {
          // Update existing manga
          final existingManga = offlineMangaList[existingIndex];
          final updatedChapters = List<OfflineChapter>.from(existingManga.chapters);
          
          // Remove existing chapter if it exists
          updatedChapters.removeWhere((chapter) => chapter.chapterId == chapterContent.chapter);
          updatedChapters.add(offlineChapter);

          final updatedManga = OfflineManga(
            id: existingManga.id,
            title: existingManga.title,
            imgUrl: existingManga.imgUrl,
            author: existingManga.author,
            chapters: updatedChapters,
            downloadedAt: existingManga.downloadedAt,
          );

          offlineMangaList[existingIndex] = updatedManga;
        } else {
          // Create new offline manga
          final offlineManga = OfflineManga(
            id: mangaId,
            title: mangaTitle,
            imgUrl: mangaImageUrl,
            author: mangaAuthor,
            chapters: [offlineChapter],
            downloadedAt: DateTime.now(),
          );
          offlineMangaList.add(offlineManga);
        }

        await _saveOfflineManga(offlineMangaList);
      }
    } catch (e) {
      throw Exception('Failed to download chapter: $e');
    }
  }

  static Future<void> removeOfflineChapter(String mangaId, String chapterId) async {
    final offlineMangaList = await getOfflineManga();
    final mangaIndex = offlineMangaList.indexWhere((manga) => manga.id == mangaId);
    
    if (mangaIndex != -1) {
      final manga = offlineMangaList[mangaIndex];
      final updatedChapters = manga.chapters
          .where((chapter) => chapter.chapterId != chapterId)
          .toList();

      if (updatedChapters.isEmpty) {
        // Remove entire manga if no chapters left
        offlineMangaList.removeAt(mangaIndex);
        
        // Delete manga directory
        final offlineDir = await _getOfflineDirectory();
        final mangaDir = Directory('$offlineDir/$mangaId');
        if (await mangaDir.exists()) {
          await mangaDir.delete(recursive: true);
        }
      } else {
        // Update manga with remaining chapters
        final updatedManga = OfflineManga(
          id: manga.id,
          title: manga.title,
          imgUrl: manga.imgUrl,
          author: manga.author,
          chapters: updatedChapters,
          downloadedAt: manga.downloadedAt,
        );
        offlineMangaList[mangaIndex] = updatedManga;

        // Delete chapter directory
        final offlineDir = await _getOfflineDirectory();
        final chapterDir = Directory('$offlineDir/$mangaId/$chapterId');
        if (await chapterDir.exists()) {
          await chapterDir.delete(recursive: true);
        }
      }

      await _saveOfflineManga(offlineMangaList);
    }
  }

  static Future<OfflineChapter?> getOfflineChapter(String mangaId, String chapterId) async {
    final offlineMangaList = await getOfflineManga();
    final manga = offlineMangaList.firstWhere(
      (manga) => manga.id == mangaId,
      orElse: () => throw Exception('Offline manga not found'),
    );
    
    return manga.chapters.firstWhere(
      (chapter) => chapter.chapterId == chapterId,
      orElse: () => throw Exception('Offline chapter not found'),
    );
  }

  static Future<bool> isChapterOffline(String mangaId, String chapterId) async {
    try {
      final offlineChapter = await getOfflineChapter(mangaId, chapterId);
      return offlineChapter != null;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _saveOfflineManga(List<OfflineManga> offlineManga) async {
    final prefs = await SharedPreferences.getInstance();
    final offlineMangaJson = offlineManga
        .map((manga) => jsonEncode(manga.toJson()))
        .toList();
    await prefs.setStringList(_offlineMangaKey, offlineMangaJson);
  }

  static Future<double> getOfflineStorageSize() async {
    try {
      final offlineDir = await _getOfflineDirectory();
      final dir = Directory(offlineDir);
      double totalSize = 0;

      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize / (1024 * 1024); // Return size in MB
    } catch (e) {
      return 0;
    }
  }

  static Future<void> clearAllOfflineData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineMangaKey);
    
    final offlineDir = await _getOfflineDirectory();
    final dir = Directory(offlineDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  // Reading History Management
  static Future<List<ReadingProgress>> getReadingHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_readingHistoryKey) ?? [];
      
      return historyJson
          .map((json) => ReadingProgress.fromJson(jsonDecode(json)))
          .toList()
        ..sort((a, b) => b.lastReadDate.compareTo(a.lastReadDate));
    } catch (e) {
      print('Error loading reading history: $e');
      return [];
    }
  }

  static Future<void> saveReadingProgress({
    required String mangaId,
    required String mangaTitle,
    required String mangaImageUrl,
    required String chapterId,
    required int currentPage,
    required int totalPages,
  }) async {
    try {
      final progress = ReadingProgress(
        mangaId: mangaId,
        mangaTitle: mangaTitle,
        mangaImageUrl: mangaImageUrl,
        lastReadChapter: chapterId,
        lastReadDate: DateTime.now(),
        totalPages: totalPages,
        currentPage: currentPage,
      );

      final history = await getReadingHistory();
      
      // Remove existing entry for same manga
      history.removeWhere((item) => item.mangaId == mangaId);
      
      // Add new entry at the beginning
      history.insert(0, progress);
      
      // Keep only last 20 entries
      if (history.length > 20) {
        history.removeRange(20, history.length);
      }
      
      final historyJson = history.map((item) => jsonEncode(item.toJson())).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readingHistoryKey, historyJson);
    } catch (e) {
      print('Error saving reading progress: $e');
    }
  }

  static Future<ReadingProgress?> getReadingProgress(String mangaId) async {
    try {
      final history = await getReadingHistory();
      return history.firstWhere(
        (progress) => progress.mangaId == mangaId,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<void> removeFromReadingHistory(String mangaId) async {
    try {
      final history = await getReadingHistory();
      history.removeWhere((item) => item.mangaId == mangaId);
      
      final historyJson = history.map((item) => jsonEncode(item.toJson())).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readingHistoryKey, historyJson);
    } catch (e) {
      print('Error removing from reading history: $e');
    }
  }

  static Future<void> clearReadingHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_readingHistoryKey);
    } catch (e) {
      print('Error clearing reading history: $e');
    }
  }

  // Reading Statistics (Bonus features)
  static Future<Map<String, dynamic>> getReadingStatistics() async {
    try {
      final history = await getReadingHistory();
      final favorites = await getFavorites();
      final offlineManga = await getOfflineManga();
      
      // Calculate total reading time (estimated)
      int totalPagesRead = 0;
      int totalChaptersRead = 0;
      Map<String, int> genreCount = {};
      
      for (final progress in history) {
        totalPagesRead += progress.currentPage;
        totalChaptersRead++;
      }
      
      // Estimate reading time (assuming 30 seconds per page)
      int estimatedReadingTimeMinutes = (totalPagesRead * 0.5).round();
      
      return {
        'totalMangaRead': history.length,
        'totalChaptersRead': totalChaptersRead,
        'totalPagesRead': totalPagesRead,
        'estimatedReadingTimeMinutes': estimatedReadingTimeMinutes,
        'totalFavorites': favorites.length,
        'totalOfflineManga': offlineManga.length,
        'totalOfflineChapters': offlineManga.fold<int>(0, (sum, manga) => sum + manga.chapters.length),
      };
    } catch (e) {
      print('Error calculating reading statistics: $e');
      return {
        'totalMangaRead': 0,
        'totalChaptersRead': 0,
        'totalPagesRead': 0,
        'estimatedReadingTimeMinutes': 0,
        'totalFavorites': 0,
        'totalOfflineManga': 0,
        'totalOfflineChapters': 0,
      };
    }
  }

  // Recently Added Favorites
  static Future<List<FavoriteManga>> getRecentFavorites({int limit = 5}) async {
    final favorites = await getFavorites();
    favorites.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return favorites.take(limit).toList();
  }

  // Most Read Manga (based on reading history frequency)
  static Future<List<ReadingProgress>> getMostReadManga({int limit = 5}) async {
    final history = await getReadingHistory();
    
    // Group by manga ID and count occurrences
    Map<String, ReadingProgress> mangaReadCount = {};
    Map<String, int> readCounts = {};
    
    for (final progress in history) {
      readCounts[progress.mangaId] = (readCounts[progress.mangaId] ?? 0) + 1;
      mangaReadCount[progress.mangaId] = progress; // Keep latest progress
    }
    
    // Sort by read count and return top manga
    final sortedEntries = readCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries
        .take(limit)
        .map((entry) => mangaReadCount[entry.key]!)
        .toList();
  }

  // Search Reading History
  static Future<List<ReadingProgress>> searchReadingHistory(String query) async {
    final history = await getReadingHistory();
    final lowercaseQuery = query.toLowerCase();
    
    return history
        .where((progress) => 
            progress.mangaTitle.toLowerCase().contains(lowercaseQuery) ||
            progress.lastReadChapter.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  // Export/Import functionality
  static Future<Map<String, dynamic>> exportUserData() async {
    try {
      final favorites = await getFavorites();
      final history = await getReadingHistory();
      final offlineManga = await getOfflineManga();
      
      return {
        'exportDate': DateTime.now().toIso8601String(),
        'favorites': favorites.map((f) => f.toJson()).toList(),
        'readingHistory': history.map((h) => h.toJson()).toList(),
        'offlineManga': offlineManga.map((o) => o.toJson()).toList(),
        'version': '1.0',
      };
    } catch (e) {
      throw Exception('Failed to export user data: $e');
    }
  }

  static Future<void> importUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Import favorites
      if (userData['favorites'] != null) {
        final favoritesList = (userData['favorites'] as List)
            .map((json) => FavoriteManga.fromJson(json))
            .toList();
        final favoritesJson = favoritesList.map((f) => jsonEncode(f.toJson())).toList();
        await prefs.setStringList(_favoritesKey, favoritesJson);
      }
      
      // Import reading history
      if (userData['readingHistory'] != null) {
        final historyList = (userData['readingHistory'] as List)
            .map((json) => ReadingProgress.fromJson(json))
            .toList();
        final historyJson = historyList.map((h) => jsonEncode(h.toJson())).toList();
        await prefs.setStringList(_readingHistoryKey, historyJson);
      }
      
      // Note: Offline manga import would require re-downloading files
      // This is just metadata import
      if (userData['offlineManga'] != null) {
        final offlineList = (userData['offlineManga'] as List)
            .map((json) => OfflineManga.fromJson(json))
            .toList();
        final offlineJson = offlineList.map((o) => jsonEncode(o.toJson())).toList();
        await prefs.setStringList(_offlineMangaKey, offlineJson);
      }
    } catch (e) {
      throw Exception('Failed to import user data: $e');
    }
  }
}