import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/document_models.dart';

class ContentLoader {
  static BookData? _cachedBookData;
  static Map<String, Character>? _cachedCharacters;
  
  /// Load the complete book data from JSON
  static Future<BookData> loadBookData() async {
    if (_cachedBookData != null) {
      return _cachedBookData!;
    }
    
    try {
      final jsonString = await rootBundle.loadString('assets/data/complete_book.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      _cachedBookData = BookData.fromJson(jsonData);
      return _cachedBookData!;
    } catch (e) {
      throw Exception('Failed to load book data: $e');
    }
  }
  
  /// Load character information from JSON
  static Future<Map<String, Character>> loadCharacters() async {
    if (_cachedCharacters != null) {
      return _cachedCharacters!;
    }
    
    try {
      final jsonString = await rootBundle.loadString('assets/data/characters.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final charactersData = jsonData['characters'] as Map<String, dynamic>;
      _cachedCharacters = charactersData.map(
        (key, value) => MapEntry(key, Character.fromJson(value as Map<String, dynamic>)),
      );
      
      return _cachedCharacters!;
    } catch (e) {
      throw Exception('Failed to load character data: $e');
    }
  }
  
  /// Load a specific chapter by name
  static Future<Chapter> loadChapter(String chapterName) async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/$chapterName.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      return Chapter.fromJson(jsonData);
    } catch (e) {
      throw Exception('Failed to load chapter $chapterName: $e');
    }
  }
  
  /// Get a specific page from the cached book data
  static DocumentPage? getPage(int pageIndex) {
    if (_cachedBookData == null) {
      return null;
    }
    
    int currentIndex = 0;
    for (final chapter in _cachedBookData!.chapters) {
      if (pageIndex < currentIndex + chapter.pages.length) {
        final pageInChapter = pageIndex - currentIndex;
        return chapter.pages[pageInChapter];
      }
      currentIndex += chapter.pages.length;
    }
    
    return null;
  }
  
  /// Get total number of pages
  static int getTotalPages() {
    return _cachedBookData?.totalPages ?? 0;
  }
  
  /// Get character information by character code
  static Character? getCharacter(String characterCode) {
    return _cachedCharacters?[characterCode];
  }
  
  /// Get all available character codes
  static List<String> getCharacterCodes() {
    return _cachedCharacters?.keys.toList() ?? [];
  }
  
  /// Clear cache (useful for testing or memory management)
  static void clearCache() {
    _cachedBookData = null;
    _cachedCharacters = null;
  }
  
  /// Preload essential data for better performance
  static Future<void> preloadEssentialData() async {
    await Future.wait([
      loadBookData(),
      loadCharacters(),
    ]);
  }
  
  /// Get chapter containing specific page
  static Chapter? getChapterForPage(int pageIndex) {
    if (_cachedBookData == null) {
      return null;
    }
    
    int currentIndex = 0;
    for (final chapter in _cachedBookData!.chapters) {
      if (pageIndex < currentIndex + chapter.pages.length) {
        return chapter;
      }
      currentIndex += chapter.pages.length;
    }
    
    return null;
  }
  
  /// Get pages for a specific reading mode
  static List<DocumentPage> getPagesForMode(ReadingMode mode, int currentPage) {
    if (_cachedBookData == null) {
      return [];
    }
    
    switch (mode) {
      case ReadingMode.singlePage:
        final page = getPage(currentPage);
        return page != null ? [page] : [];
        
      case ReadingMode.bookSpread:
        final pages = <DocumentPage>[];
        
        // Left page (even page numbers)
        if (currentPage > 0 && currentPage % 2 == 1) {
          final leftPage = getPage(currentPage - 1);
          if (leftPage != null) pages.add(leftPage);
        }
        
        // Right page (odd page numbers)
        final rightPage = getPage(currentPage);
        if (rightPage != null) pages.add(rightPage);
        
        return pages;
    }
  }
}