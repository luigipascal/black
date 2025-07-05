import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/enhanced_document_models.dart';

class ContentLoader {
  static EnhancedBookData? _cachedBookData;
  static Map<String, EnhancedCharacter>? _cachedCharacters;
  static Map<String, dynamic>? _cachedFrontMatter;
  static Map<String, dynamic>? _cachedBackMatter;
  
  /// Load the complete enhanced book data from JSON
  static Future<EnhancedBookData> loadEnhancedBookData() async {
    if (_cachedBookData != null) {
      return _cachedBookData!;
    }
    
    try {
      final jsonString = await rootBundle.loadString('assets/data/enhanced_complete_book.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      _cachedBookData = EnhancedBookData.fromJson(jsonData);
      return _cachedBookData!;
    } catch (e) {
      throw Exception('Failed to load enhanced book data: $e');
    }
  }
  
  /// Load enhanced character information from JSON
  static Future<Map<String, EnhancedCharacter>> loadEnhancedCharacters() async {
    if (_cachedCharacters != null) {
      return _cachedCharacters!;
    }
    
    try {
      final jsonString = await rootBundle.loadString('assets/data/enhanced_characters.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final charactersData = jsonData['characters'] as Map<String, dynamic>;
      _cachedCharacters = charactersData.map(
        (key, value) => MapEntry(key, EnhancedCharacter.fromJson(value as Map<String, dynamic>)),
      );
      
      return _cachedCharacters!;
    } catch (e) {
      throw Exception('Failed to load enhanced character data: $e');
    }
  }
  
  /// Load front matter data
  static Future<Map<String, dynamic>> loadFrontMatter() async {
    if (_cachedFrontMatter != null) {
      return _cachedFrontMatter!;
    }
    
    try {
      final jsonString = await rootBundle.loadString('assets/data/front_matter.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      _cachedFrontMatter = jsonData;
      return _cachedFrontMatter!;
    } catch (e) {
      throw Exception('Failed to load front matter data: $e');
    }
  }
  
  /// Load back matter data
  static Future<Map<String, dynamic>> loadBackMatter() async {
    if (_cachedBackMatter != null) {
      return _cachedBackMatter!;
    }
    
    try {
      final jsonString = await rootBundle.loadString('assets/data/back_matter.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      _cachedBackMatter = jsonData;
      return _cachedBackMatter!;
    } catch (e) {
      throw Exception('Failed to load back matter data: $e');
    }
  }

  /// Load the complete book data from JSON (backward compatibility)
  static Future<BookData> loadBookData() async {
    // Load enhanced data and return as basic BookData for backward compatibility
    final enhancedData = await loadEnhancedBookData();
    return BookData(
      title: enhancedData.title,
      author: enhancedData.author,
      totalPages: enhancedData.totalPages,
      chapters: enhancedData.chapters,
    );
  }
  
  /// Load character information from JSON (backward compatibility)
  static Future<Map<String, Character>> loadCharacters() async {
    // Load enhanced characters and return as basic Character for backward compatibility
    final enhancedCharacters = await loadEnhancedCharacters();
    return enhancedCharacters.map(
      (key, value) => MapEntry(key, Character(
        name: value.name,
        fullName: value.fullName,
        years: value.years,
        description: value.description,
        role: value.role,
        annotationStyle: value.annotationStyle,
      )),
    );
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
  
  /// Get a specific enhanced page from the cached book data
  static EnhancedDocumentPage? getEnhancedPage(int pageIndex) {
    if (_cachedBookData == null) {
      return null;
    }
    
    int currentIndex = 0;
    for (final chapter in _cachedBookData!.chapters) {
      if (pageIndex < currentIndex + chapter.pages.length) {
        final pageInChapter = pageIndex - currentIndex;
        final basicPage = chapter.pages[pageInChapter];
        
        // Convert to EnhancedDocumentPage
        return EnhancedDocumentPage(
          pageNumber: basicPage.pageNumber,
          chapterName: chapter.chapterName,
          content: basicPage.content,
          wordCount: basicPage.wordCount,
          annotationCount: basicPage.annotations.length,
          annotations: basicPage.annotations.map((a) => EnhancedAnnotation(
            id: a.id,
            character: a.character,
            text: a.text,
            type: a.type,
            year: a.year,
            position: a.position,
            chapterName: chapter.chapterName,
            pageNumber: basicPage.pageNumber,
            revealLevel: RevealLevel.academic, // Default reveal level
          )).toList(),
        );
      }
      currentIndex += chapter.pages.length;
    }
    
    return null;
  }
  
  /// Get total number of pages including front and back matter
  static int getTotalPages() {
    int totalPages = _cachedBookData?.totalPages ?? 0;
    
    // Add front matter pages
    if (_cachedFrontMatter != null) {
      final frontPages = _cachedFrontMatter!['pages'] as List?;
      totalPages += frontPages?.length ?? 0;
    }
    
    // Add back matter pages
    if (_cachedBackMatter != null) {
      final backPages = _cachedBackMatter!['pages'] as List?;
      totalPages += backPages?.length ?? 0;
    }
    
    return totalPages;
  }
  
  /// Get character information by character code
  static Character? getCharacter(String characterCode) {
    return _cachedCharacters?.values.firstWhere(
      (char) => char.name == characterCode,
      orElse: () => throw StateError('Character not found'),
    );
  }
  
  /// Get enhanced character information by character code
  static EnhancedCharacter? getEnhancedCharacter(String characterCode) {
    return _cachedCharacters?[characterCode];
  }
  
  /// Get all available character codes
  static List<String> getCharacterCodes() {
    return _cachedCharacters?.keys.toList() ?? [];
  }
  
  /// Get page section (front_matter, chapter, back_matter)
  static String getPageSection(int pageIndex) {
    final frontMatterPages = _cachedFrontMatter?['pages'] as List? ?? [];
    final backMatterPages = _cachedBackMatter?['pages'] as List? ?? [];
    final chapterPages = _cachedBookData?.totalPages ?? 0;
    
    if (pageIndex < frontMatterPages.length) {
      return 'front_matter';
    } else if (pageIndex < frontMatterPages.length + chapterPages) {
      return 'chapter';
    } else {
      return 'back_matter';
    }
  }
  
  /// Get front matter page
  static Map<String, dynamic>? getFrontMatterPage(int pageIndex) {
    final frontPages = _cachedFrontMatter?['pages'] as List?;
    if (frontPages != null && pageIndex < frontPages.length) {
      return frontPages[pageIndex] as Map<String, dynamic>;
    }
    return null;
  }
  
  /// Get back matter page
  static Map<String, dynamic>? getBackMatterPage(int pageIndex) {
    final backPages = _cachedBackMatter?['pages'] as List?;
    if (backPages != null && pageIndex < backPages.length) {
      return backPages[pageIndex] as Map<String, dynamic>;
    }
    return null;
  }
  
  /// Clear cache (useful for testing or memory management)
  static void clearCache() {
    _cachedBookData = null;
    _cachedCharacters = null;
    _cachedFrontMatter = null;
    _cachedBackMatter = null;
  }
  
  /// Preload essential data for better performance
  static Future<void> preloadEssentialData() async {
    await Future.wait([
      loadEnhancedBookData(),
      loadEnhancedCharacters(),
      loadFrontMatter(),
      loadBackMatter(),
    ]);
  }
  
  /// Get chapter containing specific page
  static Chapter? getChapterForPage(int pageIndex) {
    if (_cachedBookData == null) {
      return null;
    }
    
    final frontMatterPages = _cachedFrontMatter?['pages'] as List? ?? [];
    final adjustedIndex = pageIndex - frontMatterPages.length;
    
    if (adjustedIndex < 0) {
      return null; // This is a front matter page
    }
    
    int currentIndex = 0;
    for (final chapter in _cachedBookData!.chapters) {
      if (adjustedIndex < currentIndex + chapter.pages.length) {
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
  
  /// Get revelation system data
  static RevelationSystem? getRevelationSystem() {
    return _cachedBookData?.revelationSystem;
  }
  
  /// Get character timelines
  static Map<String, CharacterTimeline> getCharacterTimelines() {
    return _cachedBookData?.characterTimelines ?? {};
  }
  
  /// Get redacted content
  static List<RedactedContent> getRedactedContent() {
    return _cachedBookData?.redactedContent ?? [];
  }
  
  /// Get temporal rules from enhanced characters
  static Map<String, dynamic> getTemporalRules() {
    try {
      final jsonString = rootBundle.loadString('assets/data/enhanced_characters.json');
      final jsonData = jsonDecode(jsonString.toString()) as Map<String, dynamic>;
      return jsonData['temporalRules'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      return {};
    }
  }
}