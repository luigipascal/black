import 'package:equatable/equatable.dart';

// Include all existing models from document_models.dart
export 'document_models.dart';

enum RevealLevel {
  academic(1, "Academic Study", "Original Professor Finch architectural study"),
  familySecrets(2, "Family Secrets", "Margaret Blackthorn's family knowledge revealed"),
  investigation(3, "Research Investigation", "James Reed and Eliza Winston's findings"),
  modernMystery(4, "Modern Mystery", "Current investigation and disappearances"),
  completeTruth(5, "Complete Truth", "Full supernatural revelation");

  const RevealLevel(this.level, this.name, this.description);
  
  final int level;
  final String name;
  final String description;
}

class RedactedContent extends Equatable {
  final int position;
  final String hiddenText;
  final String revealedText;
  final RevealLevel revealLevel;
  final String classification;

  const RedactedContent({
    required this.position,
    required this.hiddenText,
    required this.revealedText,
    required this.revealLevel,
    this.classification = "CLASSIFIED",
  });

  factory RedactedContent.fromJson(Map<String, dynamic> json) {
    return RedactedContent(
      position: json['position'] as int,
      hiddenText: json['hiddenText'] as String,
      revealedText: json['revealedText'] as String,
      revealLevel: RevealLevel.values.firstWhere(
        (e) => e.level == json['revealLevel'],
        orElse: () => RevealLevel.completeTruth,
      ),
      classification: json['classification'] as String? ?? "CLASSIFIED",
    );
  }

  Map<String, dynamic> toJson() => {
    'position': position,
    'hiddenText': hiddenText,
    'revealedText': revealedText,
    'revealLevel': revealLevel.level,
    'classification': classification,
  };

  @override
  List<Object?> get props => [position, hiddenText, revealedText, revealLevel, classification];
}

class EnhancedAnnotation extends Equatable {
  final String id;
  final String character;
  final String text;
  final AnnotationType type;
  final int? year;
  final AnnotationPosition position;
  final String chapterName;
  final int pageNumber;
  final RevealLevel revealLevel;
  final List<String> unlockConditions;
  final bool isEmbedded;
  final String characterArcStage;
  final List<String> relatedAnnotations;

  const EnhancedAnnotation({
    required this.id,
    required this.character,
    required this.text,
    required this.type,
    required this.year,
    required this.position,
    required this.chapterName,
    required this.pageNumber,
    required this.revealLevel,
    this.unlockConditions = const [],
    this.isEmbedded = false,
    this.characterArcStage = '',
    this.relatedAnnotations = const [],
  });

  factory EnhancedAnnotation.fromJson(Map<String, dynamic> json) {
    return EnhancedAnnotation(
      id: json['id'] as String,
      character: json['character'] as String,
      text: json['text'] as String,
      type: AnnotationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AnnotationType.marginalia,
      ),
      year: json['year'] as int?,
      position: AnnotationPosition.fromJson(json['position'] as Map<String, dynamic>),
      chapterName: json['chapterName'] as String,
      pageNumber: json['pageNumber'] as int,
      revealLevel: RevealLevel.values.firstWhere(
        (e) => e.level == json['revealLevel'],
        orElse: () => RevealLevel.academic,
      ),
      unlockConditions: (json['unlockConditions'] as List?)?.cast<String>() ?? [],
      isEmbedded: json['isEmbedded'] as bool? ?? false,
      characterArcStage: json['characterArcStage'] as String? ?? '',
      relatedAnnotations: (json['relatedAnnotations'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'character': character,
    'text': text,
    'type': type.name,
    'year': year,
    'position': position.toJson(),
    'chapterName': chapterName,
    'pageNumber': pageNumber,
    'revealLevel': revealLevel.level,
    'unlockConditions': unlockConditions,
    'isEmbedded': isEmbedded,
    'characterArcStage': characterArcStage,
    'relatedAnnotations': relatedAnnotations,
  };

  bool get isPre2000 => year == null || year! < 2000;
  bool get isPost2000 => year != null && year! >= 2000;
  bool get isDraggable => isPost2000 || type == AnnotationType.postIt;

  @override
  List<Object?> get props => [
        id,
        character,
        text,
        type,
        year,
        position,
        chapterName,
        pageNumber,
        revealLevel,
        unlockConditions,
        isEmbedded,
        characterArcStage,
        relatedAnnotations,
      ];
}

class CharacterTimeline extends Equatable {
  final String character;
  final String fullName;
  final String role;
  final List<EnhancedAnnotation> timeline;
  final Map<String, dynamic> storyArc;
  final Map<String, dynamic> mysteryInvolvement;
  final List<String> disappearanceClues;
  final String disappearanceDate;
  final List<String> keyThemes;

  const CharacterTimeline({
    required this.character,
    required this.fullName,
    required this.role,
    required this.timeline,
    required this.storyArc,
    required this.mysteryInvolvement,
    required this.disappearanceClues,
    required this.disappearanceDate,
    required this.keyThemes,
  });

  factory CharacterTimeline.fromJson(Map<String, dynamic> json) {
    return CharacterTimeline(
      character: json['character'] as String,
      fullName: json['fullName'] as String,
      role: json['role'] as String,
      timeline: (json['timeline'] as List<dynamic>)
          .map((e) => EnhancedAnnotation.fromJson(e as Map<String, dynamic>))
          .toList(),
      storyArc: json['storyArc'] as Map<String, dynamic>,
      mysteryInvolvement: json['mysteryInvolvement'] as Map<String, dynamic>,
      disappearanceClues: (json['disappearanceClues'] as List?)?.cast<String>() ?? [],
      disappearanceDate: json['disappearanceDate'] as String? ?? '',
      keyThemes: (json['keyThemes'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'character': character,
    'fullName': fullName,
    'role': role,
    'timeline': timeline.map((e) => e.toJson()).toList(),
    'storyArc': storyArc,
    'mysteryInvolvement': mysteryInvolvement,
    'disappearanceClues': disappearanceClues,
    'disappearanceDate': disappearanceDate,
    'keyThemes': keyThemes,
  };

  @override
  List<Object?> get props => [
        character,
        fullName,
        role,
        timeline,
        storyArc,
        mysteryInvolvement,
        disappearanceClues,
        disappearanceDate,
        keyThemes,
      ];
}

class RevelationSystem extends Equatable {
  final Map<int, Map<String, dynamic>> revealLevels;
  final Map<String, String> unlockConditions;
  final Map<String, dynamic> characterProgression;

  const RevelationSystem({
    required this.revealLevels,
    required this.unlockConditions,
    required this.characterProgression,
  });

  factory RevelationSystem.fromJson(Map<String, dynamic> json) {
    return RevelationSystem(
      revealLevels: Map<int, Map<String, dynamic>>.from(
        json['revealLevels'].map((k, v) => MapEntry(int.parse(k), Map<String, dynamic>.from(v)))
      ),
      unlockConditions: Map<String, String>.from(json['unlockConditions']),
      characterProgression: json['characterProgression'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() => {
    'revealLevels': revealLevels.map((k, v) => MapEntry(k.toString(), v)),
    'unlockConditions': unlockConditions,
    'characterProgression': characterProgression,
  };

  @override
  List<Object?> get props => [revealLevels, unlockConditions, characterProgression];
}

class EnhancedDocumentPage extends Equatable {
  final int pageNumber;
  final String chapterName;
  final String content;
  final int wordCount;
  final int annotationCount;
  final List<EnhancedAnnotation> annotations;
  final List<RedactedContent> redactedSections;
  final List<int> revealLevels;
  final bool hasEmbeddedContent;

  const EnhancedDocumentPage({
    required this.pageNumber,
    required this.chapterName,
    required this.content,
    required this.wordCount,
    required this.annotationCount,
    required this.annotations,
    this.redactedSections = const [],
    this.revealLevels = const [1],
    this.hasEmbeddedContent = false,
  });

  factory EnhancedDocumentPage.fromJson(Map<String, dynamic> json) {
    return EnhancedDocumentPage(
      pageNumber: json['pageNumber'] as int,
      chapterName: json['chapterName'] as String,
      content: json['content'] as String,
      wordCount: json['wordCount'] as int,
      annotationCount: json['annotationCount'] as int? ?? 0,
      annotations: (json['annotations'] as List<dynamic>?)
          ?.map((e) => EnhancedAnnotation.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      redactedSections: (json['redactedSections'] as List<dynamic>?)
          ?.map((e) => RedactedContent.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      revealLevels: (json['revealLevels'] as List?)?.cast<int>() ?? [1],
      hasEmbeddedContent: json['hasEmbeddedContent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'pageNumber': pageNumber,
    'chapterName': chapterName,
    'content': content,
    'wordCount': wordCount,
    'annotationCount': annotationCount,
    'annotations': annotations.map((e) => e.toJson()).toList(),
    'redactedSections': redactedSections.map((e) => e.toJson()).toList(),
    'revealLevels': revealLevels,
    'hasEmbeddedContent': hasEmbeddedContent,
  };

  List<EnhancedAnnotation> getVisibleAnnotations(RevealLevel currentLevel) {
    return annotations.where((a) => a.revealLevel.level <= currentLevel.level).toList();
  }

  List<RedactedContent> getRevealedContent(RevealLevel currentLevel) {
    return redactedSections.where((r) => r.revealLevel.level <= currentLevel.level).toList();
  }

  String getProcessedContent(RevealLevel currentLevel) {
    String processedContent = content;
    
    // Replace redacted content if revelation level is high enough
    for (final redacted in getRevealedContent(currentLevel)) {
      processedContent = processedContent.replaceAll(
        redacted.hiddenText,
        redacted.revealedText,
      );
    }
    
    return processedContent;
  }

  @override
  List<Object?> get props => [
        pageNumber,
        chapterName,
        content,
        wordCount,
        annotationCount,
        annotations,
        redactedSections,
        revealLevels,
        hasEmbeddedContent,
      ];
}

class EnhancedCharacter extends Equatable {
  final String name;
  final String fullName;
  final String years;
  final String description;
  final String role;
  final AnnotationStyle annotationStyle;
  final String mysteryRole;
  final RevealLevel revealLevel;
  final String disappearanceDate;
  final List<String> keyThemes;

  const EnhancedCharacter({
    required this.name,
    required this.fullName,
    required this.years,
    required this.description,
    required this.role,
    required this.annotationStyle,
    required this.mysteryRole,
    required this.revealLevel,
    required this.disappearanceDate,
    required this.keyThemes,
  });

  factory EnhancedCharacter.fromJson(Map<String, dynamic> json) {
    return EnhancedCharacter(
      name: json['name'] as String,
      fullName: json['fullName'] as String,
      years: json['years'] as String,
      description: json['description'] as String,
      role: json['role'] as String,
      annotationStyle: AnnotationStyle.fromJson(
        json['annotationStyle'] as Map<String, dynamic>
      ),
      mysteryRole: json['mysteryRole'] as String? ?? '',
      revealLevel: RevealLevel.values.firstWhere(
        (e) => e.level == json['revealLevel'],
        orElse: () => RevealLevel.academic,
      ),
      disappearanceDate: json['disappearanceDate'] as String? ?? '',
      keyThemes: (json['keyThemes'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'fullName': fullName,
    'years': years,
    'description': description,
    'role': role,
    'annotationStyle': annotationStyle.toJson(),
    'mysteryRole': mysteryRole,
    'revealLevel': revealLevel.level,
    'disappearanceDate': disappearanceDate,
    'keyThemes': keyThemes,
  };

  @override
  List<Object?> get props => [
        name,
        fullName,
        years,
        description,
        role,
        annotationStyle,
        mysteryRole,
        revealLevel,
        disappearanceDate,
        keyThemes,
      ];
}

class EnhancedBookData extends Equatable {
  final String title;
  final String subtitle;
  final String author;
  final String version;
  final int totalChapters;
  final int totalPages;
  final int totalAnnotations;
  final List<Chapter> chapters;
  final Map<String, CharacterTimeline> characterTimelines;
  final RevelationSystem revelationSystem;
  final List<RedactedContent> redactedContent;
  final Map<String, dynamic> metadata;

  const EnhancedBookData({
    required this.title,
    required this.subtitle,
    required this.author,
    required this.version,
    required this.totalChapters,
    required this.totalPages,
    required this.totalAnnotations,
    required this.chapters,
    required this.characterTimelines,
    required this.revelationSystem,
    required this.redactedContent,
    required this.metadata,
  });

  factory EnhancedBookData.fromJson(Map<String, dynamic> json) {
    return EnhancedBookData(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      author: json['author'] as String,
      version: json['version'] as String? ?? '1.0.0',
      totalChapters: json['totalChapters'] as int,
      totalPages: json['totalPages'] as int,
      totalAnnotations: json['totalAnnotations'] as int,
      chapters: (json['chapters'] as List<dynamic>)
          .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
          .toList(),
      characterTimelines: Map<String, CharacterTimeline>.from(
        (json['characterTimelines'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, CharacterTimeline.fromJson(v as Map<String, dynamic>))
        )
      ),
      revelationSystem: RevelationSystem.fromJson(
        json['revelationSystem'] as Map<String, dynamic>
      ),
      redactedContent: (json['redactedContent'] as List<dynamic>?)
          ?.map((e) => RedactedContent.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
    'author': author,
    'version': version,
    'totalChapters': totalChapters,
    'totalPages': totalPages,
    'totalAnnotations': totalAnnotations,
    'chapters': chapters.map((e) => e.toJson()).toList(),
    'characterTimelines': characterTimelines.map((k, v) => MapEntry(k, v.toJson())),
    'revelationSystem': revelationSystem.toJson(),
    'redactedContent': redactedContent.map((e) => e.toJson()).toList(),
    'metadata': metadata,
  };

  @override
  List<Object?> get props => [
        title,
        subtitle,
        author,
        version,
        totalChapters,
        totalPages,
        totalAnnotations,
        chapters,
        characterTimelines,
        revelationSystem,
        redactedContent,
        metadata,
      ];
}

class UserProgress extends Equatable {
  final int currentPage;
  final RevealLevel currentRevelationLevel;
  final Set<String> discoveredCharacters;
  final Set<String> unlockedAnnotations;
  final Set<String> revealedRedactions;
  final Map<String, AnnotationPosition> customAnnotationPositions;
  final DateTime lastReadTime;

  const UserProgress({
    this.currentPage = 0,
    this.currentRevelationLevel = RevealLevel.academic,
    this.discoveredCharacters = const {},
    this.unlockedAnnotations = const {},
    this.revealedRedactions = const {},
    this.customAnnotationPositions = const {},
    required this.lastReadTime,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      currentPage: json['currentPage'] as int? ?? 0,
      currentRevelationLevel: RevealLevel.values.firstWhere(
        (e) => e.level == json['currentRevelationLevel'],
        orElse: () => RevealLevel.academic,
      ),
      discoveredCharacters: Set<String>.from(json['discoveredCharacters'] ?? []),
      unlockedAnnotations: Set<String>.from(json['unlockedAnnotations'] ?? []),
      revealedRedactions: Set<String>.from(json['revealedRedactions'] ?? []),
      customAnnotationPositions: Map<String, AnnotationPosition>.from(
        (json['customAnnotationPositions'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, AnnotationPosition.fromJson(v as Map<String, dynamic>))
        )
      ),
      lastReadTime: DateTime.parse(json['lastReadTime'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
    'currentPage': currentPage,
    'currentRevelationLevel': currentRevelationLevel.level,
    'discoveredCharacters': discoveredCharacters.toList(),
    'unlockedAnnotations': unlockedAnnotations.toList(),
    'revealedRedactions': revealedRedactions.toList(),
    'customAnnotationPositions': customAnnotationPositions.map((k, v) => MapEntry(k, v.toJson())),
    'lastReadTime': lastReadTime.toIso8601String(),
  };

  UserProgress copyWith({
    int? currentPage,
    RevealLevel? currentRevelationLevel,
    Set<String>? discoveredCharacters,
    Set<String>? unlockedAnnotations,
    Set<String>? revealedRedactions,
    Map<String, AnnotationPosition>? customAnnotationPositions,
    DateTime? lastReadTime,
  }) {
    return UserProgress(
      currentPage: currentPage ?? this.currentPage,
      currentRevelationLevel: currentRevelationLevel ?? this.currentRevelationLevel,
      discoveredCharacters: discoveredCharacters ?? this.discoveredCharacters,
      unlockedAnnotations: unlockedAnnotations ?? this.unlockedAnnotations,
      revealedRedactions: revealedRedactions ?? this.revealedRedactions,
      customAnnotationPositions: customAnnotationPositions ?? this.customAnnotationPositions,
      lastReadTime: lastReadTime ?? this.lastReadTime,
    );
  }

  double get discoveryProgress {
    // Calculate overall discovery progress
    final totalDiscoverable = 6; // 6 characters
    return discoveredCharacters.length / totalDiscoverable;
  }

  bool canAdvanceRevelationLevel() {
    switch (currentRevelationLevel) {
      case RevealLevel.academic:
        return discoveredCharacters.contains('MB');
      case RevealLevel.familySecrets:
        return discoveredCharacters.contains('JR');
      case RevealLevel.investigation:
        return discoveredCharacters.contains('SW');
      case RevealLevel.modernMystery:
        return discoveredCharacters.contains('Dr. Chambers');
      case RevealLevel.completeTruth:
        return false; // Already at max level
    }
  }

  RevealLevel? getNextRevelationLevel() {
    if (!canAdvanceRevelationLevel()) return null;
    
    switch (currentRevelationLevel) {
      case RevealLevel.academic:
        return RevealLevel.familySecrets;
      case RevealLevel.familySecrets:
        return RevealLevel.investigation;
      case RevealLevel.investigation:
        return RevealLevel.modernMystery;
      case RevealLevel.modernMystery:
        return RevealLevel.completeTruth;
      case RevealLevel.completeTruth:
        return null;
    }
  }

  @override
  List<Object?> get props => [
        currentPage,
        currentRevelationLevel,
        discoveredCharacters,
        unlockedAnnotations,
        revealedRedactions,
        customAnnotationPositions,
        lastReadTime,
      ];
}