class Manga {
  final String id;
  final String title;
  final String imgUrl;
  final String? latestChapter;
  final String? description;
  final List<String>? authors;
  final String? updated;
  final String? views;
  final List<LatestChapter>? latestChapters;

  Manga({
    required this.id,
    required this.title,
    required this.imgUrl,
    this.latestChapter,
    this.description,
    this.authors,
    this.updated,
    this.views,
    this.latestChapters,
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    return Manga(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      imgUrl: json['imgUrl'] ?? json['image'] ?? '',
      latestChapter: json['latestChapter'],
      description: json['description'],
      authors: json['authors'] != null 
        ? json['authors'].toString().split(',').map((e) => e.trim()).toList()
        : null,
      updated: json['updated'],
      views: json['views'],
      latestChapters: json['latestChapters'] != null 
        ? (json['latestChapters'] as List).map((e) => LatestChapter.fromJson(e)).toList()
        : null,
    );
  }
}

class LatestChapter {
  final String name;
  final String chapter;

  LatestChapter({required this.name, required this.chapter});

  factory LatestChapter.fromJson(Map<String, dynamic> json) {
    return LatestChapter(
      name: json['name'] ?? '',
      chapter: json['chapter'] ?? '',
    );
  }
}

class MangaDetail {
  final String id;
  final String title;
  final String imageUrl;
  final String author;
  final String status;
  final String lastUpdated;
  final String views;
  final List<String> genres;
  final String rating;
  final List<Chapter> chapters;

  MangaDetail({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.author,
    required this.status,
    required this.lastUpdated,
    required this.views,
    required this.genres,
    required this.rating,
    required this.chapters,
  });

  factory MangaDetail.fromJson(Map<String, dynamic> json) {
    return MangaDetail(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      author: json['author'] ?? 'Unknown',
      status: json['status'] ?? 'Unknown',
      lastUpdated: json['lastUpdated'] ?? '',
      views: json['views'] ?? '0',
      genres: List<String>.from(json['genres'] ?? []),
      rating: json['rating'] ?? 'N/A',
      chapters: (json['chapters'] as List? ?? []).map((e) => Chapter.fromJson(e)).toList(),
    );
  }
}

class Chapter {
  final String chapterId;
  final String views;
  final String uploaded;
  final String timestamp;

  Chapter({
    required this.chapterId,
    required this.views,
    required this.uploaded,
    required this.timestamp,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      chapterId: json['chapterId'] ?? '',
      views: json['views'] ?? '0',
      uploaded: json['uploaded'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class ChapterContent {
  final String title;
  final String chapter;
  final List<String> imageUrls;

  ChapterContent({
    required this.title,
    required this.chapter,
    required this.imageUrls,
  });

  factory ChapterContent.fromJson(Map<String, dynamic> json) {
    return ChapterContent(
      title: json['title'] ?? '',
      chapter: json['chapter'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
    );
  }
}

class SearchResult {
  final String keyword;
  final int count;
  final List<Manga> manga;

  SearchResult({
    required this.keyword,
    required this.count,
    required this.manga,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      keyword: json['keyword'] ?? '',
      count: json['count'] ?? 0,
      manga: (json['manga'] as List? ?? []).map((e) => Manga.fromJson(e)).toList(),
    );
  }
}

class GenreResponse {
  final String genre;
  final int page;
  final List<int> pagination;
  final List<Manga> manga;

  GenreResponse({
    required this.genre,
    required this.page,
    required this.pagination,
    required this.manga,
  });

  factory GenreResponse.fromJson(Map<String, dynamic> json) {
    return GenreResponse(
      genre: json['genre'] ?? '',
      page: json['page'] ?? 1,
      pagination: List<int>.from(json['pagination'] ?? []),
      manga: (json['manga'] as List? ?? []).map((e) => Manga.fromJson(e)).toList(),
    );
  }
}

class FavoriteManga {
  final String id;
  final String title;
  final String imgUrl;
  final String author;
  final DateTime dateAdded;

  FavoriteManga({
    required this.id,
    required this.title,
    required this.imgUrl,
    required this.author,
    required this.dateAdded,
  });

  factory FavoriteManga.fromJson(Map<String, dynamic> json) {
    return FavoriteManga(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      imgUrl: json['imgUrl'] ?? '',
      author: json['author'] ?? 'Unknown',
      dateAdded: DateTime.parse(json['dateAdded'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imgUrl': imgUrl,
      'author': author,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }
}

class OfflineManga {
  final String id;
  final String title;
  final String imgUrl;
  final String author;
  final List<OfflineChapter> chapters;
  final DateTime downloadedAt;

  OfflineManga({
    required this.id,
    required this.title,
    required this.imgUrl,
    required this.author,
    required this.chapters,
    required this.downloadedAt,
  });

  factory OfflineManga.fromJson(Map<String, dynamic> json) {
    return OfflineManga(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      imgUrl: json['imgUrl'] ?? '',
      author: json['author'] ?? 'Unknown',
      chapters: (json['chapters'] as List? ?? [])
          .map((e) => OfflineChapter.fromJson(e))
          .toList(),
      downloadedAt: DateTime.parse(json['downloadedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imgUrl': imgUrl,
      'author': author,
      'chapters': chapters.map((e) => e.toJson()).toList(),
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }
}

class OfflineChapter {
  final String chapterId;
  final String title;
  final List<String> localImagePaths;
  final DateTime downloadedAt;

  OfflineChapter({
    required this.chapterId,
    required this.title,
    required this.localImagePaths,
    required this.downloadedAt,
  });

  factory OfflineChapter.fromJson(Map<String, dynamic> json) {
    return OfflineChapter(
      chapterId: json['chapterId'] ?? '',
      title: json['title'] ?? '',
      localImagePaths: List<String>.from(json['localImagePaths'] ?? []),
      downloadedAt: DateTime.parse(json['downloadedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapterId': chapterId,
      'title': title,
      'localImagePaths': localImagePaths,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }
}

// Reading Progress Model - ADD THIS CLASS
class ReadingProgress {
  final String mangaId;
  final String mangaTitle;
  final String mangaImageUrl;
  final String lastReadChapter;
  final DateTime lastReadDate;
  final int totalPages;
  final int currentPage;

  ReadingProgress({
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaImageUrl,
    required this.lastReadChapter,
    required this.lastReadDate,
    required this.totalPages,
    required this.currentPage,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      mangaId: json['mangaId'] ?? '',
      mangaTitle: json['mangaTitle'] ?? '',
      mangaImageUrl: json['mangaImageUrl'] ?? '',
      lastReadChapter: json['lastReadChapter'] ?? '',
      lastReadDate: DateTime.parse(json['lastReadDate'] ?? DateTime.now().toIso8601String()),
      totalPages: json['totalPages'] ?? 0,
      currentPage: json['currentPage'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mangaId': mangaId,
      'mangaTitle': mangaTitle,
      'mangaImageUrl': mangaImageUrl,
      'lastReadChapter': lastReadChapter,
      'lastReadDate': lastReadDate.toIso8601String(),
      'totalPages': totalPages,
      'currentPage': currentPage,
    };
  }

  double get progressPercentage {
    if (totalPages == 0) return 0.0;
    return (currentPage / totalPages).clamp(0.0, 1.0);
  }

  String get formattedLastReadDate {
    final now = DateTime.now();
    final difference = now.difference(lastReadDate);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}