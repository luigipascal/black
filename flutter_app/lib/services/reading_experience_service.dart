import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/enhanced_document_models.dart';

class ReadingExperienceService {
  static final ReadingExperienceService _instance = ReadingExperienceService._internal();
  factory ReadingExperienceService() => _instance;
  ReadingExperienceService._internal();

  // Reading preferences
  ReadingPreferences _preferences = ReadingPreferences();
  
  // Reading session tracking
  Map<int, ReadingSession> _readingSessions = {};
  ReadingSession? _currentSession;
  
  // Reading goals and achievements
  List<ReadingGoal> _goals = [];
  List<ReadingAchievement> _achievements = [];
  Set<String> _unlockedAchievements = {};
  
  // Reading statistics
  ReadingStatistics _statistics = ReadingStatistics();
  
  // Page type classifications
  final Map<PageRange, PageType> _pageTypes = {
    PageRange(1, 26): PageType.frontMatter,
    PageRange(27, 101): PageType.mainContent,
    PageRange(102, 247): PageType.appendices,
  };

  // Typography configurations for different page types
  final Map<PageType, TypographyConfig> _typographyConfigs = {
    PageType.frontMatter: TypographyConfig(
      baseFontSize: 16.0,
      lineHeight: 1.6,
      letterSpacing: 0.5,
      paragraphSpacing: 16.0,
      fontWeight: FontWeight.w400,
      fontFamily: 'Georgia',
      color: Colors.black87,
    ),
    PageType.mainContent: TypographyConfig(
      baseFontSize: 18.0,
      lineHeight: 1.8,
      letterSpacing: 0.3,
      paragraphSpacing: 20.0,
      fontWeight: FontWeight.w400,
      fontFamily: 'Charter',
      color: Colors.black,
    ),
    PageType.appendices: TypographyConfig(
      baseFontSize: 14.0,
      lineHeight: 1.5,
      letterSpacing: 0.2,
      paragraphSpacing: 12.0,
      fontWeight: FontWeight.w400,
      fontFamily: 'SF Pro Text',
      color: Colors.black87,
    ),
  };

  // Reading mode configurations
  final Map<ReadingMode, ReadingModeConfig> _readingModeConfigs = {
    ReadingMode.standard: ReadingModeConfig(
      backgroundColor: Colors.white,
      textColor: Colors.black,
      marginMultiplier: 1.0,
      contrastBoost: 0.0,
      brightness: 1.0,
    ),
    ReadingMode.comfortable: ReadingModeConfig(
      backgroundColor: const Color(0xFFFFFDF7),
      textColor: const Color(0xFF2C2C2C),
      marginMultiplier: 1.2,
      contrastBoost: 0.1,
      brightness: 0.95,
    ),
    ReadingMode.focused: ReadingModeConfig(
      backgroundColor: const Color(0xFFF8F8F6),
      textColor: const Color(0xFF1A1A1A),
      marginMultiplier: 1.5,
      contrastBoost: 0.2,
      brightness: 0.9,
    ),
    ReadingMode.night: ReadingModeConfig(
      backgroundColor: const Color(0xFF1A1A1A),
      textColor: const Color(0xFFE0E0E0),
      marginMultiplier: 1.3,
      contrastBoost: 0.3,
      brightness: 0.8,
    ),
    ReadingMode.sepia: ReadingModeConfig(
      backgroundColor: const Color(0xFFF4F1E8),
      textColor: const Color(0xFF5C4B37),
      marginMultiplier: 1.1,
      contrastBoost: 0.15,
      brightness: 0.92,
    ),
  };

  // Initialize the service
  Future<void> initialize() async {
    await _loadPreferences();
    await _loadReadingData();
    _initializeGoals();
    _initializeAchievements();
  }

  // Get typography configuration for a page
  TypographyConfig getTypographyForPage(int pageNumber) {
    final pageType = _getPageType(pageNumber);
    final baseConfig = _typographyConfigs[pageType]!;
    
    return TypographyConfig(
      baseFontSize: baseConfig.baseFontSize * _preferences.fontSizeMultiplier,
      lineHeight: baseConfig.lineHeight * _preferences.lineHeightMultiplier,
      letterSpacing: baseConfig.letterSpacing,
      paragraphSpacing: baseConfig.paragraphSpacing * _preferences.spacingMultiplier,
      fontWeight: baseConfig.fontWeight,
      fontFamily: baseConfig.fontFamily,
      color: baseConfig.color,
    );
  }

  // Get reading mode configuration
  ReadingModeConfig getReadingModeConfig() {
    return _readingModeConfigs[_preferences.readingMode]!;
  }

  // Start a reading session
  void startReadingSession(int pageNumber) {
    _currentSession = ReadingSession(
      pageNumber: pageNumber,
      startTime: DateTime.now(),
      pageType: _getPageType(pageNumber),
    );
  }

  // End a reading session
  void endReadingSession(int pageNumber, {int? wordsRead}) {
    if (_currentSession == null || _currentSession!.pageNumber != pageNumber) {
      return;
    }

    final session = _currentSession!;
    session.endTime = DateTime.now();
    session.wordsRead = wordsRead ?? _estimateWordsOnPage(pageNumber);
    session.duration = session.endTime!.difference(session.startTime);

    _readingSessions[pageNumber] = session;
    _updateStatistics(session);
    _checkAchievements(session);
    _currentSession = null;

    _saveReadingData();
  }

  // Estimate reading time for a page
  Duration estimateReadingTime(int pageNumber, String content) {
    final wordCount = _countWords(content);
    final pageType = _getPageType(pageNumber);
    
    // Adjust reading speed based on page type and user's reading velocity
    double wordsPerMinute = _getReadingSpeedForPageType(pageType);
    
    // Personal reading speed adjustment
    if (_statistics.averageReadingSpeed > 0) {
      wordsPerMinute = (_statistics.averageReadingSpeed + wordsPerMinute) / 2;
    }

    final minutes = wordCount / wordsPerMinute;
    return Duration(milliseconds: (minutes * 60 * 1000).round());
  }

  // Get reading progress for a page
  ReadingProgress getReadingProgress(int pageNumber) {
    final session = _readingSessions[pageNumber];
    final isRead = session != null;
    final estimatedTime = estimateReadingTime(pageNumber, ''); // Would need actual content
    final actualTime = session?.duration ?? Duration.zero;
    
    return ReadingProgress(
      pageNumber: pageNumber,
      isRead: isRead,
      estimatedTime: estimatedTime,
      actualTime: actualTime,
      efficiency: isRead ? (estimatedTime.inSeconds / actualTime.inSeconds) : 0.0,
      comprehensionScore: _calculateComprehensionScore(pageNumber),
    );
  }

  // Update reading preferences
  void updatePreferences(ReadingPreferences preferences) {
    _preferences = preferences;
    _savePreferences();
  }

  // Get current reading statistics
  ReadingStatistics getStatistics() => _statistics;

  // Get reading goals
  List<ReadingGoal> getGoals() => List.from(_goals);

  // Get achievements
  List<ReadingAchievement> getAchievements() => List.from(_achievements);

  // Get unlocked achievements
  Set<String> getUnlockedAchievements() => Set.from(_unlockedAchievements);

  // Add a custom reading goal
  void addGoal(ReadingGoal goal) {
    _goals.add(goal);
    _saveReadingData();
  }

  // Complete a reading goal
  void completeGoal(String goalId) {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    goal.isCompleted = true;
    goal.completedAt = DateTime.now();
    _saveReadingData();
  }

  // Get reading recommendations
  List<ReadingRecommendation> getRecommendations() {
    final recommendations = <ReadingRecommendation>[];

    // Optimal reading time recommendations
    if (_statistics.averageSessionDuration < const Duration(minutes: 10)) {
      recommendations.add(ReadingRecommendation(
        type: RecommendationType.sessionLength,
        title: 'Extend Reading Sessions',
        description: 'Try reading for 15-20 minutes at a time for better comprehension.',
        priority: RecommendationPriority.medium,
      ));
    }

    // Reading speed recommendations
    if (_statistics.averageReadingSpeed < 200) {
      recommendations.add(ReadingRecommendation(
        type: RecommendationType.readingSpeed,
        title: 'Practice Speed Reading',
        description: 'Your reading speed could be improved with practice exercises.',
        priority: RecommendationPriority.low,
      ));
    }

    // Reading mode recommendations
    final hour = DateTime.now().hour;
    if (hour >= 20 && _preferences.readingMode != ReadingMode.night) {
      recommendations.add(ReadingRecommendation(
        type: RecommendationType.readingMode,
        title: 'Try Night Mode',
        description: 'Night mode reduces eye strain during evening reading.',
        priority: RecommendationPriority.high,
      ));
    }

    // Content recommendations based on reading patterns
    if (_statistics.mostReadPageType == PageType.mainContent) {
      recommendations.add(ReadingRecommendation(
        type: RecommendationType.content,
        title: 'Explore Appendices',
        description: 'The appendices contain valuable supplementary information.',
        priority: RecommendationPriority.medium,
      ));
    }

    return recommendations;
  }

  // Private helper methods

  PageType _getPageType(int pageNumber) {
    for (final entry in _pageTypes.entries) {
      if (pageNumber >= entry.key.start && pageNumber <= entry.key.end) {
        return entry.value;
      }
    }
    return PageType.mainContent;
  }

  double _getReadingSpeedForPageType(PageType pageType) {
    switch (pageType) {
      case PageType.frontMatter:
        return 180.0; // Slower for introductory material
      case PageType.mainContent:
        return 220.0; // Standard narrative reading speed
      case PageType.appendices:
        return 150.0; // Slower for reference material
    }
  }

  int _countWords(String text) {
    return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }

  int _estimateWordsOnPage(int pageNumber) {
    final pageType = _getPageType(pageNumber);
    switch (pageType) {
      case PageType.frontMatter:
        return 150;
      case PageType.mainContent:
        return 300;
      case PageType.appendices:
        return 200;
    }
  }

  double _calculateComprehensionScore(int pageNumber) {
    // Simplified comprehension score based on reading patterns
    final session = _readingSessions[pageNumber];
    if (session == null) return 0.0;

    final estimatedTime = estimateReadingTime(pageNumber, '');
    final actualTime = session.duration;
    
    if (actualTime < estimatedTime * 0.5) {
      return 0.3; // Too fast, likely skimmed
    } else if (actualTime > estimatedTime * 2.0) {
      return 0.7; // Slow, but thorough
    } else {
      return 1.0; // Optimal reading pace
    }
  }

  void _updateStatistics(ReadingSession session) {
    _statistics.totalReadingTime += session.duration;
    _statistics.totalPagesRead++;
    _statistics.totalWordsRead += session.wordsRead;
    
    // Update averages
    _statistics.averageSessionDuration = Duration(
      milliseconds: _statistics.totalReadingTime.inMilliseconds ~/ 
                    math.max(1, _readingSessions.length),
    );
    
    if (session.duration.inMinutes > 0) {
      _statistics.averageReadingSpeed = 
          session.wordsRead / session.duration.inMinutes;
    }

    // Update reading streak
    _updateReadingStreak();
    
    // Update page type statistics
    _statistics.pageTypeStats[session.pageType] = 
        (_statistics.pageTypeStats[session.pageType] ?? 0) + 1;
    
    _statistics.mostReadPageType = _statistics.pageTypeStats.entries
        .reduce((a, b) => a.value > b.value ? a : b).key;
  }

  void _updateReadingStreak() {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    
    bool readToday = _readingSessions.values.any((session) =>
        session.startTime.year == today.year &&
        session.startTime.month == today.month &&
        session.startTime.day == today.day);
    
    bool readYesterday = _readingSessions.values.any((session) =>
        session.startTime.year == yesterday.year &&
        session.startTime.month == yesterday.month &&
        session.startTime.day == yesterday.day);

    if (readToday) {
      if (!readYesterday && _statistics.currentStreak > 0) {
        _statistics.currentStreak = 1;
      } else if (readYesterday) {
        _statistics.currentStreak++;
      } else {
        _statistics.currentStreak = 1;
      }
      
      _statistics.longestStreak = math.max(
        _statistics.longestStreak, 
        _statistics.currentStreak,
      );
    }
  }

  void _checkAchievements(ReadingSession session) {
    // Check various achievement conditions
    for (final achievement in _achievements) {
      if (!_unlockedAchievements.contains(achievement.id)) {
        bool unlocked = false;

        switch (achievement.condition.type) {
          case AchievementType.pagesRead:
            unlocked = _statistics.totalPagesRead >= achievement.condition.target;
            break;
          case AchievementType.readingTime:
            unlocked = _statistics.totalReadingTime.inMinutes >= achievement.condition.target;
            break;
          case AchievementType.readingStreak:
            unlocked = _statistics.currentStreak >= achievement.condition.target;
            break;
          case AchievementType.readingSpeed:
            unlocked = _statistics.averageReadingSpeed >= achievement.condition.target;
            break;
          case AchievementType.completion:
            unlocked = (_statistics.totalPagesRead / 247.0) >= (achievement.condition.target / 100.0);
            break;
        }

        if (unlocked) {
          _unlockedAchievements.add(achievement.id);
          achievement.unlockedAt = DateTime.now();
          _triggerAchievementNotification(achievement);
        }
      }
    }
  }

  void _triggerAchievementNotification(ReadingAchievement achievement) {
    // In a real app, this would trigger a notification or celebration animation
    HapticFeedback.lightImpact();
    print('Achievement Unlocked: ${achievement.title}');
  }

  void _initializeGoals() {
    _goals = [
      ReadingGoal(
        id: 'daily_15min',
        title: 'Daily Reader',
        description: 'Read for 15 minutes today',
        target: 15,
        period: GoalPeriod.daily,
        type: GoalType.readingTime,
      ),
      ReadingGoal(
        id: 'weekly_5pages',
        title: 'Weekly Explorer',
        description: 'Read 5 pages this week',
        target: 5,
        period: GoalPeriod.weekly,
        type: GoalType.pagesRead,
      ),
      ReadingGoal(
        id: 'monthly_progress',
        title: 'Monthly Investigator',
        description: 'Complete 25% of the book this month',
        target: 25,
        period: GoalPeriod.monthly,
        type: GoalType.completion,
      ),
    ];
  }

  void _initializeAchievements() {
    _achievements = [
      ReadingAchievement(
        id: 'first_page',
        title: 'Investigation Begins',
        description: 'Read your first page',
        condition: AchievementCondition(AchievementType.pagesRead, 1),
        rarity: AchievementRarity.common,
      ),
      ReadingAchievement(
        id: 'speed_reader',
        title: 'Speed Reader',
        description: 'Achieve 300 words per minute reading speed',
        condition: AchievementCondition(AchievementType.readingSpeed, 300),
        rarity: AchievementRarity.rare,
      ),
      ReadingAchievement(
        id: 'dedicated_reader',
        title: 'Dedicated Investigator',
        description: 'Read for 7 days in a row',
        condition: AchievementCondition(AchievementType.readingStreak, 7),
        rarity: AchievementRarity.epic,
      ),
      ReadingAchievement(
        id: 'marathon_reader',
        title: 'Marathon Reader',
        description: 'Read for 2 hours total',
        condition: AchievementCondition(AchievementType.readingTime, 120),
        rarity: AchievementRarity.rare,
      ),
      ReadingAchievement(
        id: 'mystery_solver',
        title: 'Mystery Solver',
        description: 'Complete 50% of the investigation',
        condition: AchievementCondition(AchievementType.completion, 50),
        rarity: AchievementRarity.legendary,
      ),
      ReadingAchievement(
        id: 'truth_seeker',
        title: 'Truth Seeker',
        description: 'Complete the entire investigation',
        condition: AchievementCondition(AchievementType.completion, 100),
        rarity: AchievementRarity.legendary,
      ),
    ];
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsJson = prefs.getString('reading_preferences');
    
    if (prefsJson != null) {
      _preferences = ReadingPreferences.fromJson(json.decode(prefsJson));
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reading_preferences', json.encode(_preferences.toJson()));
  }

  Future<void> _loadReadingData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load reading sessions
    final sessionsJson = prefs.getString('reading_sessions');
    if (sessionsJson != null) {
      final sessionsData = json.decode(sessionsJson) as Map<String, dynamic>;
      _readingSessions = sessionsData.map((key, value) =>
          MapEntry(int.parse(key), ReadingSession.fromJson(value)));
    }

    // Load statistics
    final statsJson = prefs.getString('reading_statistics');
    if (statsJson != null) {
      _statistics = ReadingStatistics.fromJson(json.decode(statsJson));
    }

    // Load goals
    final goalsJson = prefs.getString('reading_goals');
    if (goalsJson != null) {
      final goalsList = json.decode(goalsJson) as List;
      _goals = goalsList.map((goal) => ReadingGoal.fromJson(goal)).toList();
    }

    // Load unlocked achievements
    final achievementsJson = prefs.getString('unlocked_achievements');
    if (achievementsJson != null) {
      final achievementsList = json.decode(achievementsJson) as List;
      _unlockedAchievements = Set.from(achievementsList);
    }
  }

  Future<void> _saveReadingData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save reading sessions
    final sessionsData = _readingSessions.map((key, value) =>
        MapEntry(key.toString(), value.toJson()));
    await prefs.setString('reading_sessions', json.encode(sessionsData));

    // Save statistics
    await prefs.setString('reading_statistics', json.encode(_statistics.toJson()));

    // Save goals
    final goalsList = _goals.map((goal) => goal.toJson()).toList();
    await prefs.setString('reading_goals', json.encode(goalsList));

    // Save unlocked achievements
    await prefs.setString('unlocked_achievements', json.encode(_unlockedAchievements.toList()));
  }
}

// Data models for reading experience
class ReadingPreferences {
  double fontSizeMultiplier;
  double lineHeightMultiplier;
  double spacingMultiplier;
  ReadingMode readingMode;
  bool adaptiveTypography;
  bool readingGoalsEnabled;
  bool achievementsEnabled;

  ReadingPreferences({
    this.fontSizeMultiplier = 1.0,
    this.lineHeightMultiplier = 1.0,
    this.spacingMultiplier = 1.0,
    this.readingMode = ReadingMode.standard,
    this.adaptiveTypography = true,
    this.readingGoalsEnabled = true,
    this.achievementsEnabled = true,
  });

  Map<String, dynamic> toJson() => {
    'fontSizeMultiplier': fontSizeMultiplier,
    'lineHeightMultiplier': lineHeightMultiplier,
    'spacingMultiplier': spacingMultiplier,
    'readingMode': readingMode.index,
    'adaptiveTypography': adaptiveTypography,
    'readingGoalsEnabled': readingGoalsEnabled,
    'achievementsEnabled': achievementsEnabled,
  };

  factory ReadingPreferences.fromJson(Map<String, dynamic> json) => ReadingPreferences(
    fontSizeMultiplier: json['fontSizeMultiplier']?.toDouble() ?? 1.0,
    lineHeightMultiplier: json['lineHeightMultiplier']?.toDouble() ?? 1.0,
    spacingMultiplier: json['spacingMultiplier']?.toDouble() ?? 1.0,
    readingMode: ReadingMode.values[json['readingMode'] ?? 0],
    adaptiveTypography: json['adaptiveTypography'] ?? true,
    readingGoalsEnabled: json['readingGoalsEnabled'] ?? true,
    achievementsEnabled: json['achievementsEnabled'] ?? true,
  );
}

class ReadingSession {
  final int pageNumber;
  final DateTime startTime;
  final PageType pageType;
  DateTime? endTime;
  Duration duration = Duration.zero;
  int wordsRead = 0;

  ReadingSession({
    required this.pageNumber,
    required this.startTime,
    required this.pageType,
    this.endTime,
  });

  Map<String, dynamic> toJson() => {
    'pageNumber': pageNumber,
    'startTime': startTime.toIso8601String(),
    'pageType': pageType.index,
    'endTime': endTime?.toIso8601String(),
    'duration': duration.inMilliseconds,
    'wordsRead': wordsRead,
  };

  factory ReadingSession.fromJson(Map<String, dynamic> json) => ReadingSession(
    pageNumber: json['pageNumber'],
    startTime: DateTime.parse(json['startTime']),
    pageType: PageType.values[json['pageType']],
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
  )..duration = Duration(milliseconds: json['duration'] ?? 0)
   ..wordsRead = json['wordsRead'] ?? 0;
}

class ReadingStatistics {
  Duration totalReadingTime = Duration.zero;
  int totalPagesRead = 0;
  int totalWordsRead = 0;
  Duration averageSessionDuration = Duration.zero;
  double averageReadingSpeed = 0.0;
  int currentStreak = 0;
  int longestStreak = 0;
  Map<PageType, int> pageTypeStats = {};
  PageType mostReadPageType = PageType.mainContent;

  Map<String, dynamic> toJson() => {
    'totalReadingTime': totalReadingTime.inMilliseconds,
    'totalPagesRead': totalPagesRead,
    'totalWordsRead': totalWordsRead,
    'averageSessionDuration': averageSessionDuration.inMilliseconds,
    'averageReadingSpeed': averageReadingSpeed,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'pageTypeStats': pageTypeStats.map((key, value) => MapEntry(key.index, value)),
    'mostReadPageType': mostReadPageType.index,
  };

  factory ReadingStatistics.fromJson(Map<String, dynamic> json) => ReadingStatistics()
    ..totalReadingTime = Duration(milliseconds: json['totalReadingTime'] ?? 0)
    ..totalPagesRead = json['totalPagesRead'] ?? 0
    ..totalWordsRead = json['totalWordsRead'] ?? 0
    ..averageSessionDuration = Duration(milliseconds: json['averageSessionDuration'] ?? 0)
    ..averageReadingSpeed = json['averageReadingSpeed']?.toDouble() ?? 0.0
    ..currentStreak = json['currentStreak'] ?? 0
    ..longestStreak = json['longestStreak'] ?? 0
    ..pageTypeStats = (json['pageTypeStats'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(PageType.values[int.parse(key)], value)) ?? {}
    ..mostReadPageType = PageType.values[json['mostReadPageType'] ?? 1];
}

// Enums and supporting classes
enum PageType { frontMatter, mainContent, appendices }
enum ReadingMode { standard, comfortable, focused, night, sepia }
enum GoalPeriod { daily, weekly, monthly }
enum GoalType { readingTime, pagesRead, completion }
enum AchievementType { pagesRead, readingTime, readingStreak, readingSpeed, completion }
enum AchievementRarity { common, rare, epic, legendary }
enum RecommendationType { sessionLength, readingSpeed, readingMode, content }
enum RecommendationPriority { low, medium, high }

class PageRange {
  final int start;
  final int end;

  PageRange(this.start, this.end);
}

class TypographyConfig {
  final double baseFontSize;
  final double lineHeight;
  final double letterSpacing;
  final double paragraphSpacing;
  final FontWeight fontWeight;
  final String fontFamily;
  final Color color;

  TypographyConfig({
    required this.baseFontSize,
    required this.lineHeight,
    required this.letterSpacing,
    required this.paragraphSpacing,
    required this.fontWeight,
    required this.fontFamily,
    required this.color,
  });
}

class ReadingModeConfig {
  final Color backgroundColor;
  final Color textColor;
  final double marginMultiplier;
  final double contrastBoost;
  final double brightness;

  ReadingModeConfig({
    required this.backgroundColor,
    required this.textColor,
    required this.marginMultiplier,
    required this.contrastBoost,
    required this.brightness,
  });
}

class ReadingProgress {
  final int pageNumber;
  final bool isRead;
  final Duration estimatedTime;
  final Duration actualTime;
  final double efficiency;
  final double comprehensionScore;

  ReadingProgress({
    required this.pageNumber,
    required this.isRead,
    required this.estimatedTime,
    required this.actualTime,
    required this.efficiency,
    required this.comprehensionScore,
  });
}

class ReadingGoal {
  final String id;
  final String title;
  final String description;
  final int target;
  final GoalPeriod period;
  final GoalType type;
  bool isCompleted = false;
  DateTime? completedAt;
  final DateTime createdAt;

  ReadingGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.period,
    required this.type,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'target': target,
    'period': period.index,
    'type': type.index,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory ReadingGoal.fromJson(Map<String, dynamic> json) => ReadingGoal(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    target: json['target'],
    period: GoalPeriod.values[json['period']],
    type: GoalType.values[json['type']],
    createdAt: DateTime.parse(json['createdAt']),
  )..isCompleted = json['isCompleted'] ?? false
   ..completedAt = json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null;
}

class ReadingAchievement {
  final String id;
  final String title;
  final String description;
  final AchievementCondition condition;
  final AchievementRarity rarity;
  DateTime? unlockedAt;

  ReadingAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.condition,
    required this.rarity,
    this.unlockedAt,
  });
}

class AchievementCondition {
  final AchievementType type;
  final int target;

  AchievementCondition(this.type, this.target);
}

class ReadingRecommendation {
  final RecommendationType type;
  final String title;
  final String description;
  final RecommendationPriority priority;

  ReadingRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
  });
}