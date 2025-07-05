import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/enhanced_document_models.dart';

class AdvancedSearchService {
  static final AdvancedSearchService _instance = AdvancedSearchService._internal();
  factory AdvancedSearchService() => _instance;
  AdvancedSearchService._internal();

  // Cached data for fast search
  List<DocumentPage>? _allPages;
  List<EnhancedAnnotation>? _allAnnotations;
  Map<String, Character>? _characters;
  Map<String, List<String>>? _searchIndex;
  
  // Search statistics
  Map<String, int> _searchStats = {};
  List<String> _recentSearches = [];

  // Initialize search service with all data
  Future<void> initialize() async {
    try {
      await Future.wait([
        _loadPages(),
        _loadAnnotations(),
        _loadCharacters(),
      ]);
      
      await _buildSearchIndex();
    } catch (e) {
      print('Error initializing search service: $e');
    }
  }

  Future<void> _loadPages() async {
    try {
      final String frontMatterData = await rootBundle.loadString('assets/data/front_matter.json');
      final String chaptersData = await rootBundle.loadString('assets/data/enhanced_complete_book.json');
      final String backMatterData = await rootBundle.loadString('assets/data/back_matter.json');

      final frontMatter = json.decode(frontMatterData);
      final chapters = json.decode(chaptersData);
      final backMatter = json.decode(backMatterData);

      _allPages = <DocumentPage>[];

      // Add front matter pages
      if (frontMatter['pages'] != null) {
        for (final pageData in frontMatter['pages']) {
          _allPages!.add(DocumentPage.fromJson(pageData));
        }
      }

      // Add chapter pages
      if (chapters['pages'] != null) {
        for (final pageData in chapters['pages']) {
          _allPages!.add(DocumentPage.fromJson(pageData));
        }
      }

      // Add back matter pages
      if (backMatter['pages'] != null) {
        for (final pageData in backMatter['pages']) {
          _allPages!.add(DocumentPage.fromJson(pageData));
        }
      }
    } catch (e) {
      print('Error loading pages: $e');
      _allPages = [];
    }
  }

  Future<void> _loadAnnotations() async {
    try {
      final String annotationsData = await rootBundle.loadString('assets/data/enhanced_annotations.json');
      final annotations = json.decode(annotationsData);

      _allAnnotations = <EnhancedAnnotation>[];
      if (annotations['annotations'] != null) {
        for (final annotationData in annotations['annotations']) {
          _allAnnotations!.add(EnhancedAnnotation.fromJson(annotationData));
        }
      }
    } catch (e) {
      print('Error loading annotations: $e');
      _allAnnotations = [];
    }
  }

  Future<void> _loadCharacters() async {
    try {
      final String charactersData = await rootBundle.loadString('assets/data/enhanced_characters.json');
      final charactersJson = json.decode(charactersData);

      _characters = <String, Character>{};
      if (charactersJson['characters'] != null) {
        for (final characterData in charactersJson['characters']) {
          final character = Character.fromJson(characterData);
          _characters![character.name] = character;
        }
      }
    } catch (e) {
      print('Error loading characters: $e');
      _characters = {};
    }
  }

  Future<void> _buildSearchIndex() async {
    _searchIndex = <String, List<String>>{};

    // Index page content
    if (_allPages != null) {
      for (final page in _allPages!) {
        final words = _extractWords(page.content);
        for (final word in words) {
          final key = word.toLowerCase();
          _searchIndex![key] = _searchIndex![key] ?? [];
          _searchIndex![key]!.add('page_${page.pageNumber}');
        }
      }
    }

    // Index annotations
    if (_allAnnotations != null) {
      for (final annotation in _allAnnotations!) {
        final words = _extractWords(annotation.text);
        for (final word in words) {
          final key = word.toLowerCase();
          _searchIndex![key] = _searchIndex![key] ?? [];
          _searchIndex![key]!.add('annotation_${annotation.id}');
        }
      }
    }

    // Index characters
    if (_characters != null) {
      for (final character in _characters!.values) {
        final words = _extractWords('${character.fullName} ${character.description}');
        for (final word in words) {
          final key = word.toLowerCase();
          _searchIndex![key] = _searchIndex![key] ?? [];
          _searchIndex![key]!.add('character_${character.name}');
        }
      }
    }
  }

  List<String> _extractWords(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2)
        .toList();
  }

  // Comprehensive search across all content
  Future<SearchResults> search(SearchQuery query) async {
    if (_allPages == null || _allAnnotations == null || _characters == null) {
      await initialize();
    }

    final results = SearchResults(
      query: query,
      pageResults: [],
      annotationResults: [],
      characterResults: [],
      totalResults: 0,
      searchTime: DateTime.now(),
    );

    final stopwatch = Stopwatch()..start();

    try {
      // Search pages
      if (query.includePages) {
        results.pageResults = await _searchPages(query);
      }

      // Search annotations
      if (query.includeAnnotations) {
        results.annotationResults = await _searchAnnotations(query);
      }

      // Search characters
      if (query.includeCharacters) {
        results.characterResults = await _searchCharacters(query);
      }

      results.totalResults = results.pageResults.length + 
                           results.annotationResults.length + 
                           results.characterResults.length;

      // Sort results by relevance
      _sortResultsByRelevance(results, query);

      // Update search statistics
      _updateSearchStats(query.searchText);

    } catch (e) {
      print('Error performing search: $e');
    }

    stopwatch.stop();
    results.searchDuration = stopwatch.elapsed;

    return results;
  }

  Future<List<PageSearchResult>> _searchPages(SearchQuery query) async {
    final results = <PageSearchResult>[];

    for (final page in _allPages!) {
      final matches = _findMatches(page.content, query.searchText);
      if (matches.isNotEmpty) {
        // Apply filters
        if (_passesFilters(page, query)) {
          final result = PageSearchResult(
            page: page,
            matches: matches,
            relevanceScore: _calculateRelevanceScore(matches, query.searchText),
            snippet: _generateSnippet(page.content, matches.first),
          );
          results.add(result);
        }
      }
    }

    return results;
  }

  Future<List<AnnotationSearchResult>> _searchAnnotations(SearchQuery query) async {
    final results = <AnnotationSearchResult>[];

    for (final annotation in _allAnnotations!) {
      final matches = _findMatches(annotation.text, query.searchText);
      if (matches.isNotEmpty) {
        // Apply filters
        if (_passesAnnotationFilters(annotation, query)) {
          final result = AnnotationSearchResult(
            annotation: annotation,
            matches: matches,
            relevanceScore: _calculateRelevanceScore(matches, query.searchText),
            snippet: _generateSnippet(annotation.text, matches.first),
          );
          results.add(result);
        }
      }
    }

    return results;
  }

  Future<List<CharacterSearchResult>> _searchCharacters(SearchQuery query) async {
    final results = <CharacterSearchResult>[];

    for (final character in _characters!.values) {
      final searchText = '${character.fullName} ${character.description}';
      final matches = _findMatches(searchText, query.searchText);
      
      if (matches.isNotEmpty) {
        final result = CharacterSearchResult(
          character: character,
          matches: matches,
          relevanceScore: _calculateRelevanceScore(matches, query.searchText),
          matchedField: _determineMatchedField(character, query.searchText),
        );
        results.add(result);
      }
    }

    return results;
  }

  List<TextMatch> _findMatches(String text, String searchText) {
    final matches = <TextMatch>[];
    final searchLower = searchText.toLowerCase();
    final textLower = text.toLowerCase();
    
    int startIndex = 0;
    while (true) {
      final index = textLower.indexOf(searchLower, startIndex);
      if (index == -1) break;
      
      matches.add(TextMatch(
        startIndex: index,
        endIndex: index + searchText.length,
        matchedText: text.substring(index, index + searchText.length),
        context: _getMatchContext(text, index, searchText.length),
      ));
      
      startIndex = index + 1;
    }
    
    return matches;
  }

  String _getMatchContext(String text, int matchIndex, int matchLength) {
    const contextLength = 50;
    final start = (matchIndex - contextLength).clamp(0, text.length);
    final end = (matchIndex + matchLength + contextLength).clamp(0, text.length);
    
    return text.substring(start, end);
  }

  String _generateSnippet(String text, TextMatch match) {
    const snippetLength = 150;
    final start = (match.startIndex - snippetLength ~/ 2).clamp(0, text.length);
    final end = (start + snippetLength).clamp(0, text.length);
    
    String snippet = text.substring(start, end);
    if (start > 0) snippet = '...$snippet';
    if (end < text.length) snippet = '$snippet...';
    
    return snippet;
  }

  double _calculateRelevanceScore(List<TextMatch> matches, String searchText) {
    double score = 0.0;
    
    // Base score from number of matches
    score += matches.length * 10;
    
    // Bonus for exact matches
    for (final match in matches) {
      if (match.matchedText.toLowerCase() == searchText.toLowerCase()) {
        score += 50;
      }
    }
    
    // Bonus for multiple word matches
    if (searchText.split(' ').length > 1) {
      score += 25;
    }
    
    return score;
  }

  bool _passesFilters(DocumentPage page, SearchQuery query) {
    // Date range filter
    if (query.dateRange != null) {
      // Implementation depends on page metadata
    }
    
    // Page type filter
    if (query.pageTypes.isNotEmpty) {
      // Implementation depends on page type classification
    }
    
    return true;
  }

  bool _passesAnnotationFilters(EnhancedAnnotation annotation, SearchQuery query) {
    // Character filter
    if (query.characters.isNotEmpty && 
        !query.characters.contains(annotation.character)) {
      return false;
    }
    
    // Revelation level filter
    if (query.minRevelationLevel != null && 
        annotation.revealLevel.index < query.minRevelationLevel!.index) {
      return false;
    }
    
    return true;
  }

  String _determineMatchedField(Character character, String searchText) {
    if (character.fullName.toLowerCase().contains(searchText.toLowerCase())) {
      return 'name';
    } else if (character.description.toLowerCase().contains(searchText.toLowerCase())) {
      return 'description';
    }
    return 'other';
  }

  void _sortResultsByRelevance(SearchResults results, SearchQuery query) {
    results.pageResults.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    results.annotationResults.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    results.characterResults.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
  }

  void _updateSearchStats(String searchText) {
    _searchStats[searchText] = (_searchStats[searchText] ?? 0) + 1;
    
    _recentSearches.insert(0, searchText);
    if (_recentSearches.length > 10) {
      _recentSearches.removeLast();
    }
  }

  // Advanced search features
  Future<List<String>> getSuggestions(String partialQuery) async {
    if (_searchIndex == null) await initialize();
    
    final suggestions = <String>[];
    final queryLower = partialQuery.toLowerCase();
    
    for (final word in _searchIndex!.keys) {
      if (word.startsWith(queryLower) && word != queryLower) {
        suggestions.add(word);
      }
    }
    
    // Add recent searches that match
    for (final recent in _recentSearches) {
      if (recent.toLowerCase().startsWith(queryLower) && 
          !suggestions.contains(recent)) {
        suggestions.insert(0, recent);
      }
    }
    
    return suggestions.take(5).toList();
  }

  List<String> getRecentSearches() => List.from(_recentSearches);
  
  Map<String, int> getSearchStats() => Map.from(_searchStats);

  // Bookmark functionality
  final List<PageBookmark> _bookmarks = [];

  void addBookmark(PageBookmark bookmark) {
    _bookmarks.removeWhere((b) => b.pageNumber == bookmark.pageNumber);
    _bookmarks.add(bookmark);
    _bookmarks.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
  }

  void removeBookmark(int pageNumber) {
    _bookmarks.removeWhere((b) => b.pageNumber == pageNumber);
  }

  List<PageBookmark> getBookmarks() => List.from(_bookmarks);

  bool isBookmarked(int pageNumber) {
    return _bookmarks.any((b) => b.pageNumber == pageNumber);
  }

  // Reading progress tracking
  final Set<int> _readPages = <int>{};
  Map<int, Duration> _pageReadingTime = {};

  void markPageAsRead(int pageNumber, Duration readingTime) {
    _readPages.add(pageNumber);
    _pageReadingTime[pageNumber] = readingTime;
  }

  bool isPageRead(int pageNumber) => _readPages.contains(pageNumber);
  
  double getReadingProgress() {
    if (_allPages == null || _allPages!.isEmpty) return 0.0;
    return _readPages.length / _allPages!.length;
  }

  Duration getTotalReadingTime() {
    return _pageReadingTime.values.fold(
      Duration.zero, 
      (total, time) => total + time,
    );
  }

  Map<int, Duration> getPageReadingTimes() => Map.from(_pageReadingTime);

  // Clear cache and reset
  void clearCache() {
    _allPages = null;
    _allAnnotations = null;
    _characters = null;
    _searchIndex = null;
    _searchStats.clear();
    _recentSearches.clear();
  }
}

// Data models for search functionality
class SearchQuery {
  final String searchText;
  final bool includePages;
  final bool includeAnnotations;
  final bool includeCharacters;
  final List<String> characters;
  final List<String> pageTypes;
  final DateTimeRange? dateRange;
  final RevealLevel? minRevelationLevel;
  final bool caseSensitive;
  final bool wholeWords;

  SearchQuery({
    required this.searchText,
    this.includePages = true,
    this.includeAnnotations = true,
    this.includeCharacters = true,
    this.characters = const [],
    this.pageTypes = const [],
    this.dateRange,
    this.minRevelationLevel,
    this.caseSensitive = false,
    this.wholeWords = false,
  });
}

class SearchResults {
  final SearchQuery query;
  List<PageSearchResult> pageResults;
  List<AnnotationSearchResult> annotationResults;
  List<CharacterSearchResult> characterResults;
  int totalResults;
  final DateTime searchTime;
  Duration searchDuration = Duration.zero;

  SearchResults({
    required this.query,
    required this.pageResults,
    required this.annotationResults,
    required this.characterResults,
    required this.totalResults,
    required this.searchTime,
  });
}

class PageSearchResult {
  final DocumentPage page;
  final List<TextMatch> matches;
  final double relevanceScore;
  final String snippet;

  PageSearchResult({
    required this.page,
    required this.matches,
    required this.relevanceScore,
    required this.snippet,
  });
}

class AnnotationSearchResult {
  final EnhancedAnnotation annotation;
  final List<TextMatch> matches;
  final double relevanceScore;
  final String snippet;

  AnnotationSearchResult({
    required this.annotation,
    required this.matches,
    required this.relevanceScore,
    required this.snippet,
  });
}

class CharacterSearchResult {
  final Character character;
  final List<TextMatch> matches;
  final double relevanceScore;
  final String matchedField;

  CharacterSearchResult({
    required this.character,
    required this.matches,
    required this.relevanceScore,
    required this.matchedField,
  });
}

class TextMatch {
  final int startIndex;
  final int endIndex;
  final String matchedText;
  final String context;

  TextMatch({
    required this.startIndex,
    required this.endIndex,
    required this.matchedText,
    required this.context,
  });
}

class PageBookmark {
  final int pageNumber;
  final String title;
  final String note;
  final DateTime createdAt;
  final String? thumbnailPath;

  PageBookmark({
    required this.pageNumber,
    required this.title,
    this.note = '',
    required this.createdAt,
    this.thumbnailPath,
  });

  Map<String, dynamic> toJson() => {
    'pageNumber': pageNumber,
    'title': title,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
    'thumbnailPath': thumbnailPath,
  };

  factory PageBookmark.fromJson(Map<String, dynamic> json) => PageBookmark(
    pageNumber: json['pageNumber'],
    title: json['title'],
    note: json['note'] ?? '',
    createdAt: DateTime.parse(json['createdAt']),
    thumbnailPath: json['thumbnailPath'],
  );
}

// Date range helper
class DateTimeRange {
  final DateTime start;
  final DateTime end;

  DateTimeRange({required this.start, required this.end});
}