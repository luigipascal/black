import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/enhanced_document_models.dart';

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

  // Load book data
  Future<void> _loadBookData() async {
    // For now, create sample enhanced book data
    // In a real app, this would load from assets or API
    _bookData = _createSampleBookData();
  }

  // Load characters
  Future<void> _loadCharacters() async {
    // Sample character data - would normally load from assets
    _characters = _createSampleCharacters();
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
    if (_bookData == null) return [];
    
    // Find page in chapters
    for (final chapter in _bookData!.chapters) {
      for (final page in chapter.pages) {
        if (page.pageNumber == pageNumber) {
          // Convert regular annotations to enhanced annotations with reveal levels
          return page.annotations
              .map((ann) => _convertToEnhancedAnnotation(ann))
              .where((ann) => ann.revealLevel.level <= currentRevelationLevel.level)
              .toList();
        }
      }
    }
    return [];
  }

  // Get character timeline data
  CharacterTimeline? getCharacterTimeline(String characterCode) {
    return _bookData?.characterTimelines[characterCode];
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

  // Convert regular annotation to enhanced annotation with revelation logic
  EnhancedAnnotation _convertToEnhancedAnnotation(Annotation annotation) {
    // Determine reveal level based on character and year
    RevealLevel revealLevel = RevealLevel.academic;
    
    if (annotation.character == 'MB') {
      revealLevel = RevealLevel.familySecrets;
    } else if (annotation.character == 'JR' || annotation.character == 'EW') {
      revealLevel = RevealLevel.investigation;
    } else if (annotation.character == 'SW' || annotation.character == 'Detective Sharma') {
      revealLevel = RevealLevel.modernMystery;
    } else if (annotation.character == 'Dr. Chambers') {
      revealLevel = RevealLevel.completeTruth;
    }

    return EnhancedAnnotation(
      id: annotation.id,
      character: annotation.character,
      text: annotation.text,
      type: annotation.type,
      year: annotation.year,
      position: annotation.position,
      chapterName: annotation.chapterName,
      pageNumber: annotation.pageNumber,
      revealLevel: revealLevel,
      unlockConditions: _generateUnlockConditions(annotation.character, annotation.year),
      isEmbedded: _isEmbeddedAnnotation(annotation.text),
      characterArcStage: _getCharacterArcStage(annotation.character, annotation.year),
      relatedAnnotations: [],
    );
  }

  List<String> _generateUnlockConditions(String character, int? year) {
    List<String> conditions = [];
    if (character == 'MB') {
      conditions.add('family_secrets_unlocked');
    } else if (character == 'JR' || character == 'EW') {
      conditions.add('research_phase_unlocked');
    } else if (character == 'SW' || character == 'Detective Sharma') {
      conditions.add('modern_mystery_unlocked');
    }
    if (year != null && year >= 2020) {
      conditions.add('current_investigation_active');
    }
    return conditions;
  }

  bool _isEmbeddedAnnotation(String text) {
    return text.contains('[Elegant blue script]') ||
           text.contains('[Messy black ballpoint]') ||
           text.contains('[Precise red pen]') ||
           text.contains('[Hurried pencil]');
  }

  String _getCharacterArcStage(String character, int? year) {
    if (year == null) return 'unknown';
    
    switch (character) {
      case 'MB':
        if (year < 1980) return 'family_guardian';
        if (year < 1990) return 'secret_keeper';
        return 'final_warnings';
      case 'JR':
        if (year < 1987) return 'initial_research';
        if (year < 1989) return 'growing_concern';
        return 'disappearance';
      case 'EW':
        if (year < 1997) return 'structural_analysis';
        if (year < 1999) return 'anomaly_discovery';
        return 'safety_concerns';
      case 'SW':
        return 'sister_investigation';
      default:
        return 'current';
    }
  }

  // Sample data creation methods (would be replaced with real data loading)
  EnhancedBookData _createSampleBookData() {
    return EnhancedBookData(
      title: 'Blackthorn Manor: An Architectural Study',
      subtitle: 'Enhanced Interactive Edition',
      author: 'Professor Harold Finch',
      version: '2.0.0-enhanced',
      totalChapters: 12,
      totalPages: 99,
      totalAnnotations: 361,
      chapters: [], // Would load actual chapters
      characterTimelines: {}, // Would load actual timelines
      revelationSystem: RevelationSystem(
        revealLevels: {
          1: {'name': 'Academic Study', 'description': 'Original academic text'},
          2: {'name': 'Family Secrets', 'description': 'Margaret Blackthorn annotations'},
          3: {'name': 'Research Investigation', 'description': 'James Reed and Eliza Winston'},
          4: {'name': 'Modern Mystery', 'description': 'Current investigation'},
          5: {'name': 'Complete Truth', 'description': 'Full supernatural revelation'},
        },
        unlockConditions: {
          'family_secrets': 'Discover Margaret Blackthorn',
          'research_phase': 'Find James Reed annotations',
          'modern_mystery': 'Unlock Simon Wells investigation',
          'complete_truth': 'Access government classification',
        },
        characterProgression: {
          'discoveryOrder': ['MB', 'JR', 'EW', 'SW', 'Detective Sharma', 'Dr. Chambers'],
        },
      ),
      redactedContent: [],
      metadata: {
        'processingDate': DateTime.now().toIso8601String(),
        'enhancedFeatures': [
          'progressive_revelation',
          'character_timelines',
          'redacted_content',
          'embedded_annotations',
          'missing_persons_mystery'
        ],
      },
    );
  }

  Map<String, EnhancedCharacter> _createSampleCharacters() {
    return {
      'MB': EnhancedCharacter(
        name: 'Margaret Blackthorn',
        fullName: 'Margaret Blackthorn',
        years: '1930-1999',
        description: 'Last surviving member of the Blackthorn family. Her elegant blue script reveals family secrets passed down through generations.',
        role: 'Family Guardian',
        annotationStyle: const AnnotationStyle(
          fontFamily: 'Dancing Script',
          fontSize: 10,
          color: '#2653a3',
          fontStyle: 'italic',
          description: 'Elegant blue script with careful, deliberate strokes'
        ),
        mysteryRole: 'Keeper of family secrets and ancient protective rituals',
        revealLevel: RevealLevel.familySecrets,
        disappearanceDate: '1999 (natural death)',
        keyThemes: ['family secrets', 'protective rituals', 'dimensional containment'],
      ),
      'JR': EnhancedCharacter(
        name: 'James Reed',
        fullName: 'James Reed',
        years: '1984-1990',
        description: 'Independent researcher whose messy black ballpoint notes document his growing unease before his mysterious disappearance.',
        role: 'Independent Researcher',
        annotationStyle: const AnnotationStyle(
          fontFamily: 'Courier New',
          fontSize: 9,
          color: '#1a1a1a',
          fontStyle: 'normal',
          description: 'Messy black ballpoint, increasingly hurried'
        ),
        mysteryRole: 'Academic investigator who uncovered too much truth',
        revealLevel: RevealLevel.investigation,
        disappearanceDate: 'March 1989',
        keyThemes: ['architectural anomalies', 'research methodology', 'growing danger'],
      ),
      'EW': EnhancedCharacter(
        name: 'Eliza Winston',
        fullName: 'Eliza Winston',
        years: '1995-1999',
        description: 'Structural engineer whose precise red pen annotations revealed impossible architectural anomalies.',
        role: 'Structural Engineer',
        annotationStyle: const AnnotationStyle(
          fontFamily: 'Arial',
          fontSize: 10,
          color: '#c41e3a',
          fontStyle: 'normal',
          description: 'Precise red pen with engineering accuracy'
        ),
        mysteryRole: 'Technical expert who documented structural impossibilities',
        revealLevel: RevealLevel.investigation,
        disappearanceDate: '1999 (project abandonment)',
        keyThemes: ['structural analysis', 'engineering impossibilities', 'safety concerns'],
      ),
      'SW': EnhancedCharacter(
        name: 'Simon Wells',
        fullName: 'Simon Wells',
        years: '2024+',
        description: 'Current investigator whose hurried pencil notes document his desperate search for his missing sister Claire.',
        role: 'Current Investigator',
        annotationStyle: const AnnotationStyle(
          fontFamily: 'Courier New',
          fontSize: 9,
          color: '#2c2c2c',
          fontStyle: 'normal',
          description: 'Hurried pencil, emotionally charged'
        ),
        mysteryRole: 'Modern investigator seeking missing sister',
        revealLevel: RevealLevel.modernMystery,
        disappearanceDate: 'Active investigation',
        keyThemes: ['sister disappearance', 'modern investigation', 'connecting timelines'],
      ),
      'Detective Sharma': EnhancedCharacter(
        name: 'Detective Sharma',
        fullName: 'Detective Moira Sharma',
        years: '2024+',
        description: 'County Police detective investigating multiple disappearances at Blackthorn Manor.',
        role: 'Police Investigator',
        annotationStyle: const AnnotationStyle(
          fontFamily: 'Courier Prime',
          fontSize: 8,
          color: '#006400',
          fontStyle: 'normal',
          description: 'Official green ink, professional documentation'
        ),
        mysteryRole: 'Law enforcement connecting missing persons cases',
        revealLevel: RevealLevel.modernMystery,
        disappearanceDate: 'Active investigation',
        keyThemes: ['missing persons', 'police investigation', 'pattern recognition'],
      ),
      'Dr. Chambers': EnhancedCharacter(
        name: 'Dr. Chambers',
        fullName: 'Dr. E. Chambers',
        years: '2024+',
        description: 'Government analyst with Department 8, specializing in anomalous phenomena.',
        role: 'Government Analyst',
        annotationStyle: const AnnotationStyle(
          fontFamily: 'Courier Prime',
          fontSize: 8,
          color: '#000000',
          fontStyle: 'normal',
          description: 'Official black ink with government classifications'
        ),
        mysteryRole: 'Government oversight of anomalous phenomena',
        revealLevel: RevealLevel.completeTruth,
        disappearanceDate: 'Classified status',
        keyThemes: ['government classification', 'anomalous phenomena', 'dimensional monitoring'],
      ),
    };
  }
}