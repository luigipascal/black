import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/enhanced_document_models.dart';
import '../services/content_loader.dart';

class EnhancedRevelationProvider extends ChangeNotifier {
  // Core state
  UserProgress _userProgress = UserProgress(lastReadTime: DateTime.now());
  EnhancedBookData? _bookData;
  Map<String, EnhancedCharacter> _characters = {};
  
  // Loading and error states
  bool _isLoading = false;
  String? _errorMessage;
  
  // Discovery notifications
  final List<String> _recentDiscoveries = [];

  // Getters
  UserProgress get userProgress => _userProgress;
  EnhancedBookData? get bookData => _bookData;
  Map<String, EnhancedCharacter> get characters => _characters;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<String> get recentDiscoveries => List.unmodifiable(_recentDiscoveries);

  // Current page and revelation state
  int get currentPage => _userProgress.currentPage;
  RevealLevel get currentRevelationLevel => _userProgress.currentRevelationLevel;
  Set<String> get discoveredCharacters => _userProgress.discoveredCharacters;
  double get discoveryProgress => _userProgress.discoveryProgress;

  // Enhanced getters
  bool get canAdvanceRevelationLevel => _userProgress.canAdvanceRevelationLevel();
  RevealLevel? get nextRevelationLevel => _userProgress.getNextRevelationLevel();
  
  String get revelationLevelDescription {
    return "${currentRevelationLevel.level}/5 - ${currentRevelationLevel.name}";
  }

  List<String> get unlockedCharacters {
    return discoveredCharacters.where((char) {
      final character = _characters[char];
      return character != null && character.revealLevel.level <= currentRevelationLevel.level;
    }).toList();
  }

  List<String> get availableCharacters {
    return _characters.entries
        .where((entry) => entry.value.revealLevel.level <= currentRevelationLevel.level)
        .map((entry) => entry.key)
        .toList();
  }

  // Initialize the provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadUserProgress();
      await _loadBookData();
      await _loadCharacters();
      _clearError();
    } catch (e) {
      _setError('Failed to initialize: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load book data from ContentLoader
  Future<void> _loadBookData() async {
    try {
      _bookData = await ContentLoader.loadEnhancedBookData();
    } catch (e) {
      debugPrint('Error loading book data: $e');
      throw Exception('Failed to load book data: $e');
    }
  }

  // Load characters from ContentLoader
  Future<void> _loadCharacters() async {
    try {
      _characters = await ContentLoader.loadEnhancedCharacters();
    } catch (e) {
      debugPrint('Error loading characters: $e');
      throw Exception('Failed to load characters: $e');
    }
  }

  // User progress management
  Future<void> _loadUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('user_progress');
      
      if (progressJson != null) {
        final progressMap = json.decode(progressJson) as Map<String, dynamic>;
        _userProgress = UserProgress.fromJson(progressMap);
      }
    } catch (e) {
      debugPrint('Error loading user progress: $e');
      // Keep default progress if loading fails
    }
  }

  Future<void> _saveUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = json.encode(_userProgress.toJson());
      await prefs.setString('user_progress', progressJson);
    } catch (e) {
      debugPrint('Error saving user progress: $e');
    }
  }

  // Page navigation
  Future<void> setCurrentPage(int page) async {
    if (page != _userProgress.currentPage) {
      _userProgress = _userProgress.copyWith(
        currentPage: page,
        lastReadTime: DateTime.now(),
      );
      await _saveUserProgress();
      notifyListeners();
    }
  }

  // Character discovery
  Future<void> discoverCharacter(String characterCode) async {
    if (!_userProgress.discoveredCharacters.contains(characterCode)) {
      final newDiscovered = Set<String>.from(_userProgress.discoveredCharacters)
        ..add(characterCode);
      
      _userProgress = _userProgress.copyWith(
        discoveredCharacters: newDiscovered,
        lastReadTime: DateTime.now(),
      );

      // Add to recent discoveries for notifications
      final character = _characters[characterCode];
      if (character != null) {
        _recentDiscoveries.add('📝 Character Discovered: ${character.fullName}!');
        _trimRecentDiscoveries();
      }

      // Check for revelation level advancement
      await _checkRevelationAdvancement();
      
      await _saveUserProgress();
      notifyListeners();
    }
  }

  // Annotation unlocking
  Future<void> unlockAnnotation(String annotationId) async {
    if (!_userProgress.unlockedAnnotations.contains(annotationId)) {
      final newUnlocked = Set<String>.from(_userProgress.unlockedAnnotations)
        ..add(annotationId);
      
      _userProgress = _userProgress.copyWith(
        unlockedAnnotations: newUnlocked,
        lastReadTime: DateTime.now(),
      );

      await _saveUserProgress();
      notifyListeners();
    }
  }

  // Redaction revealing
  Future<void> revealRedaction(String redactionId) async {
    if (currentRevelationLevel == RevealLevel.completeTruth && 
        !_userProgress.revealedRedactions.contains(redactionId)) {
      final newRevealed = Set<String>.from(_userProgress.revealedRedactions)
        ..add(redactionId);
      
      _userProgress = _userProgress.copyWith(
        revealedRedactions: newRevealed,
        lastReadTime: DateTime.now(),
      );

      _recentDiscoveries.add('🔓 Classified information revealed!');
      _trimRecentDiscoveries();

      await _saveUserProgress();
      notifyListeners();
    }
  }

  // Revelation level management
  Future<void> _checkRevelationAdvancement() async {
    if (_userProgress.canAdvanceRevelationLevel()) {
      final nextLevel = _userProgress.getNextRevelationLevel();
      if (nextLevel != null) {
        await advanceRevelationLevel(nextLevel);
      }
    }
  }

  Future<void> advanceRevelationLevel(RevealLevel newLevel) async {
    if (newLevel.level > _userProgress.currentRevelationLevel.level) {
      _userProgress = _userProgress.copyWith(
        currentRevelationLevel: newLevel,
        lastReadTime: DateTime.now(),
      );

      _recentDiscoveries.add('🔓 Revelation Level ${newLevel.level} Unlocked: ${newLevel.name}!');
      _trimRecentDiscoveries();

      await _saveUserProgress();
      notifyListeners();
    }
  }

  Future<void> setRevelationLevel(RevealLevel level) async {
    // Allow setting to any unlocked level (for review purposes)
    if (level.level <= _userProgress.currentRevelationLevel.level) {
      _userProgress = _userProgress.copyWith(
        currentRevelationLevel: level,
        lastReadTime: DateTime.now(),
      );

      if (level.level < _userProgress.currentRevelationLevel.level) {
        _recentDiscoveries.add('📖 Viewing Level ${level.level}: ${level.name}');
        _trimRecentDiscoveries();
      }

      await _saveUserProgress();
      notifyListeners();
    }
  }

  // Annotation positioning (for draggable annotations)
  Future<void> updateAnnotationPosition(String annotationId, AnnotationPosition newPosition) async {
    final newPositions = Map<String, AnnotationPosition>.from(_userProgress.customAnnotationPositions);
    newPositions[annotationId] = newPosition;
    
    _userProgress = _userProgress.copyWith(
      customAnnotationPositions: newPositions,
      lastReadTime: DateTime.now(),
    );

    await _saveUserProgress();
    notifyListeners();
  }

  // Get visible annotations for current page and revelation level
  List<EnhancedAnnotation> getVisibleAnnotationsForPage(int pageNumber) {
    final enhancedPage = ContentLoader.getEnhancedPage(pageNumber);
    if (enhancedPage == null) return [];
    
    return enhancedPage.getVisibleAnnotations(currentRevelationLevel);
  }

  // Get enhanced page with processed content
  EnhancedDocumentPage? getEnhancedPage(int pageNumber) {
    final page = ContentLoader.getEnhancedPage(pageNumber);
    if (page == null) return null;
    
    // Return page with processed content for current revelation level
    return EnhancedDocumentPage(
      pageNumber: page.pageNumber,
      chapterName: page.chapterName,
      content: page.getProcessedContent(currentRevelationLevel),
      wordCount: page.wordCount,
      annotationCount: page.annotationCount,
      annotations: page.getVisibleAnnotations(currentRevelationLevel),
      redactedSections: page.getRevealedContent(currentRevelationLevel),
      revealLevels: page.revealLevels,
      hasEmbeddedContent: page.hasEmbeddedContent,
    );
  }

  // Get front matter page
  Map<String, dynamic>? getFrontMatterPage(int pageIndex) {
    return ContentLoader.getFrontMatterPage(pageIndex);
  }

  // Get back matter page
  Map<String, dynamic>? getBackMatterPage(int pageIndex) {
    return ContentLoader.getBackMatterPage(pageIndex);
  }

  // Get page section
  String getPageSection(int pageIndex) {
    return ContentLoader.getPageSection(pageIndex);
  }

  // Get character timeline data
  CharacterTimeline? getCharacterTimeline(String characterCode) {
    return ContentLoader.getCharacterTimelines()[characterCode];
  }

  // Get revelation system
  RevelationSystem? getRevelationSystem() {
    return ContentLoader.getRevelationSystem();
  }

  // Discovery statistics
  Map<String, dynamic> getDiscoveryStatistics() {
    final totalCharacters = _characters.length;
    final discoveredCount = discoveredCharacters.length;
    final totalAnnotations = _bookData?.totalAnnotations ?? 0;
    final unlockedCount = _userProgress.unlockedAnnotations.length;
    final revealedRedactions = _userProgress.revealedRedactions.length;

    return {
      'characterProgress': '$discoveredCount/$totalCharacters',
      'characterPercentage': totalCharacters > 0 ? (discoveredCount / totalCharacters * 100).round() : 0,
      'annotationProgress': '$unlockedCount/$totalAnnotations',
      'annotationPercentage': totalAnnotations > 0 ? (unlockedCount / totalAnnotations * 100).round() : 0,
      'revealedRedactions': revealedRedactions,
      'currentLevel': currentRevelationLevel.level,
      'maxLevel': RevealLevel.values.length,
      'nextUnlock': nextRevelationLevel?.name ?? 'All content unlocked!',
    };
  }

  // Enhanced content checking
  bool isAnnotationVisible(EnhancedAnnotation annotation) {
    return annotation.revealLevel.level <= currentRevelationLevel.level;
  }

  bool isRedactionRevealed(RedactedContent redaction) {
    return redaction.revealLevel.level <= currentRevelationLevel.level;
  }

  bool isCharacterUnlocked(String characterCode) {
    final character = _characters[characterCode];
    return character != null && character.revealLevel.level <= currentRevelationLevel.level;
  }

  // Missing persons mystery helpers
  List<String> getMissingPersonsClues() {
    final clues = <String>[];
    
    for (final timeline in ContentLoader.getCharacterTimelines().values) {
      if (timeline.disappearanceClues.isNotEmpty) {
        clues.addAll(timeline.disappearanceClues);
      }
    }
    
    return clues;
  }

  Map<String, String> getDisappearanceDates() {
    final dates = <String, String>{};
    
    for (final entry in ContentLoader.getCharacterTimelines().entries) {
      if (entry.value.disappearanceDate.isNotEmpty) {
        dates[entry.key] = entry.value.disappearanceDate;
      }
    }
    
    return dates;
  }

  // Reset progress (for testing/debugging)
  Future<void> resetProgress() async {
    _userProgress = UserProgress(lastReadTime: DateTime.now());
    _recentDiscoveries.clear();
    await _saveUserProgress();
    notifyListeners();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _trimRecentDiscoveries() {
    while (_recentDiscoveries.length > 5) {
      _recentDiscoveries.removeAt(0);
    }
  }

  void clearRecentDiscoveries() {
    _recentDiscoveries.clear();
    notifyListeners();
  }
}