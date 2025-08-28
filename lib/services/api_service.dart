import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/manga_model.dart';
import '../utils/connectivity_service.dart';

class ApiService {
  static const String baseUrl = 'https://gomanga-api.vercel.app/api';
  static const Duration timeout = Duration(seconds: 30);

  // Helper method for making HTTP requests with error handling
  static Future<Map<String, dynamic>> _makeRequest(String endpoint) async {
    try {
      // Check connectivity
      final connectivityService = ConnectivityService();
      if (!connectivityService.isConnected) {
        throw const NetworkException('No internet connection');
      }

      final uri = Uri.parse('$baseUrl$endpoint');
      print('Making request to: $uri'); // Debug log
      
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(timeout);

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body length: ${response.body.length}'); // Debug log

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic>) {
            return data;
          } else {
            throw Exception('Invalid JSON format: Expected Map<String, dynamic>');
          }
        } catch (e) {
          print('JSON decode error: $e'); // Debug log
          throw Exception('Failed to parse JSON response: $e');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Content not found (404)');
      } else if (response.statusCode >= 500) {
        throw Exception('Server error (${response.statusCode})');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } on SocketException catch (e) {
      print('Socket exception: $e'); // Debug log
      throw const NetworkException('Network connection failed');
    } on HttpException catch (e) {
      print('HTTP exception: $e'); // Debug log
      throw NetworkException('HTTP error: ${e.message}');
    } on FormatException catch (e) {
      print('Format exception: $e'); // Debug log
      throw Exception('Invalid response format');
    } catch (e) {
      print('General exception: $e'); // Debug log
      if (e is NetworkException) rethrow;
      throw Exception('Request failed: $e');
    }
  }

  static Future<List<Manga>> getMangaList(int page) async {
    try {
      final data = await _makeRequest('/manga-list/$page');
      
      final mangaData = data['data'];
      if (mangaData is List) {
        return mangaData
            .where((item) => item != null && item is Map<String, dynamic>)
            .map((json) => Manga.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Invalid manga list format');
      }
    } catch (e) {
      print('getMangaList error: $e'); // Debug log
      rethrow;
    }
  }

  static Future<MangaDetail> getMangaDetail(String mangaId) async {
    try {
      if (mangaId.isEmpty) {
        throw Exception('Manga ID cannot be empty');
      }
      
      final data = await _makeRequest('/manga/$mangaId');
      return MangaDetail.fromJson(data);
    } catch (e) {
      print('getMangaDetail error: $e'); // Debug log
      rethrow;
    }
  }

  static Future<ChapterContent> getChapterContent(String mangaId, String chapter) async {
    try {
      if (mangaId.isEmpty || chapter.isEmpty) {
        throw Exception('Manga ID and chapter cannot be empty');
      }
      
      final data = await _makeRequest('/manga/$mangaId/$chapter');
      return ChapterContent.fromJson(data);
    } catch (e) {
      print('getChapterContent error: $e'); // Debug log
      rethrow;
    }
  }

  static Future<SearchResult> searchManga(String query) async {
    try {
      if (query.trim().isEmpty) {
        throw Exception('Search query cannot be empty');
      }
      
      final encodedQuery = Uri.encodeComponent(query.trim());
      final data = await _makeRequest('/search/$encodedQuery');
      return SearchResult.fromJson(data);
    } catch (e) {
      print('searchManga error: $e'); // Debug log
      rethrow;
    }
  }

  static Future<List<String>> getGenres() async {
    try {
      final data = await _makeRequest('/genre');
      
      // Handle the response format from your API
      final genresData = data['genre'];
      if (genresData is List) {
        return genresData
            .where((item) => item != null)
            .map((item) => item.toString().trim())
            .where((genre) => genre.isNotEmpty)
            .toList();
      } else {
        throw Exception('Invalid genres format: Expected List but got ${genresData.runtimeType}');
      }
    } catch (e) {
      print('getGenres error: $e'); // Debug log
      rethrow;
    }
  }

  static Future<GenreResponse> getMangaByGenre(String genre, int page) async {
    try {
      if (genre.isEmpty) {
        throw Exception('Genre cannot be empty');
      }
      
      // Use the genre as-is since the API expects exact matches
      final data = await _makeRequest('/genre/$genre/$page');
      
      // Create a proper GenreResponse object
      return GenreResponse(
        genre: genre,
        page: page,
        pagination: [], // API doesn't seem to return pagination info
        manga: (data['manga'] as List? ?? [])
            .where((item) => item != null && item is Map<String, dynamic>)
            .map((json) => Manga.fromJson(json as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      print('getMangaByGenre error: $e'); // Debug log
      rethrow;
    }
  }

  // Helper method to test API connectivity
  static Future<bool> testConnection() async {
    try {
      await _makeRequest('/genre');
      return true;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}

// Custom exception for network errors
class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}