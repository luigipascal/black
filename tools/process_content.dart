import 'dart:io';
import 'dart:convert';
import 'dart:math';

void main() async {
  print('🏰 Processing Blackthorn Manor Content...');
  
  final processor = ContentProcessor();
  await processor.processAllContent();
  
  print('✅ Content processing completed successfully!');
}

class ContentProcessor {
  final String chaptersDir = 'content/chapters';
  final String dataDir = 'content/data';
  final String outputDir = 'flutter_app/assets/data';
  
  List<dynamic> annotations = [];
  List<ChapterData> chapters = [];
  
  Future<void> processAllContent() async {
    print('📂 Loading annotations...');
    await loadAnnotations();
    
    print('📖 Processing chapters...');
    await processChapters();
    
    print('🔗 Matching annotations to content...');
    await matchAnnotationsToContent();
    
    print('💾 Saving processed data...');
    await saveProcessedData();
    
    print('📊 Generating statistics...');
    generateStatistics();
  }
  
  Future<void> loadAnnotations() async {
    final annotationsFile = File('$dataDir/annotations.json');
    if (!await annotationsFile.exists()) {
      throw Exception('Annotations file not found: $dataDir/annotations.json');
    }
    
    final content = await annotationsFile.readAsString();
    annotations = jsonDecode(content) as List<dynamic>;
    print('   📝 Loaded ${annotations.length} annotations');
  }
  
  Future<void> processChapters() async {
    final chaptersDirectory = Directory(chaptersDir);
    if (!await chaptersDirectory.exists()) {
      throw Exception('Chapters directory not found: $chaptersDir');
    }
    
    final chapterFiles = await chaptersDirectory
        .list()
        .where((entity) => entity.path.endsWith('.md'))
        .map((entity) => entity as File)
        .toList();
    
    // Sort by chapter number
    chapterFiles.sort((a, b) => _extractChapterNumber(a.path).compareTo(_extractChapterNumber(b.path)));
    
    for (final file in chapterFiles) {
      final chapterData = await processChapterFile(file);
      chapters.add(chapterData);
    }
    
    print('   📚 Processed ${chapters.length} chapters');
  }
  
  int _extractChapterNumber(String filename) {
    final match = RegExp(r'CHAPTER_([IVX]+)').firstMatch(filename);
    if (match != null) {
      return _romanToInt(match.group(1)!);
    }
    return 999; // Put unmatched files at the end
  }
  
  int _romanToInt(String roman) {
    const romanNumerals = {
      'I': 1, 'V': 5, 'X': 10, 'L': 50, 'C': 100, 'D': 500, 'M': 1000
    };
    
    int total = 0;
    for (int i = 0; i < roman.length; i++) {
      int current = romanNumerals[roman[i]] ?? 0;
      int next = i + 1 < roman.length ? romanNumerals[roman[i + 1]] ?? 0 : 0;
      
      if (current < next) {
        total -= current;
      } else {
        total += current;
      }
    }
    return total;
  }
  
  Future<ChapterData> processChapterFile(File file) async {
    final content = await file.readAsString();
    final filename = file.path.split('/').last;
    final chapterName = filename.replaceAll('.md', '');
    
    // Split content into logical paragraphs/sections
    final paragraphs = content.split('\n\n')
        .where((p) => p.trim().isNotEmpty)
        .map((p) => p.trim())
        .toList();
    
    // Create pages from paragraphs (roughly 2-3 paragraphs per page)
    final pages = <PageData>[];
    for (int i = 0; i < paragraphs.length; i += 3) {
      final pageContent = paragraphs.skip(i).take(3).join('\n\n');
      pages.add(PageData(
        pageNumber: pages.length + 1,
        chapterName: chapterName,
        content: pageContent,
        wordCount: pageContent.split(' ').length,
        annotations: [], // Will be populated later
      ));
    }
    
    return ChapterData(
      chapterNumber: _extractChapterNumber(filename),
      chapterName: chapterName,
      filename: filename,
      fullContent: content,
      pages: pages,
      wordCount: content.split(' ').length,
    );
  }
  
  Future<void> matchAnnotationsToContent() async {
    // Group annotations by chapter
    final annotationsByChapter = <String, List<dynamic>>{};
    
    for (final annotation in annotations) {
      final chapterName = annotation['chapter'] as String?;
      if (chapterName != null) {
        annotationsByChapter.putIfAbsent(chapterName, () => []).add(annotation);
      }
    }
    
    // Distribute annotations across pages within each chapter
    for (final chapter in chapters) {
      final chapterAnnotations = annotationsByChapter[chapter.chapterName] ?? [];
      
      // Distribute annotations across pages in the chapter
      for (int i = 0; i < chapterAnnotations.length; i++) {
        final pageIndex = i % chapter.pages.length;
        final annotation = chapterAnnotations[i];
        
        // Convert annotation to our format
        final processedAnnotation = AnnotationData(
          id: annotation['id'] as String,
          character: _parseCharacter(annotation['character']),
          text: annotation['text'] as String,
          type: _parseAnnotationType(annotation['type']),
          year: annotation['year'] as int?,
          position: _generatePosition(annotation, pageIndex),
          chapterName: chapter.chapterName,
          pageNumber: pageIndex + 1,
        );
        
        chapter.pages[pageIndex].annotations.add(processedAnnotation);
      }
    }
    
    print('   🔗 Matched ${annotations.length} annotations to content');
  }
  
  String _parseCharacter(dynamic character) {
    if (character is List) {
      return character.first as String;
    }
    return character as String;
  }
  
  AnnotationType _parseAnnotationType(String type) {
    switch (type.toLowerCase()) {
      case 'marginalia':
        return AnnotationType.marginalia;
      case 'sticker':
        return AnnotationType.postIt;
      case 'redaction':
        return AnnotationType.redaction;
      default:
        return AnnotationType.marginalia;
    }
  }
  
  AnnotationPosition _generatePosition(dynamic annotation, int pageIndex) {
    final random = Random(annotation['id'].hashCode);
    final character = _parseCharacter(annotation['character']);
    final year = annotation['year'] as int?;
    
    // Determine annotation zone based on character and year
    AnnotationZone zone;
    if (year != null && year >= 2000) {
      // Post-2000 annotations can be anywhere
      zone = AnnotationZone.values[random.nextInt(AnnotationZone.values.length)];
    } else {
      // Pre-2000 annotations only in margins
      final marginZones = [
        AnnotationZone.leftMargin,
        AnnotationZone.rightMargin,
        AnnotationZone.topMargin,
        AnnotationZone.bottomMargin
      ];
      zone = marginZones[random.nextInt(marginZones.length)];
    }
    
    // Generate position within the zone
    double x, y;
    switch (zone) {
      case AnnotationZone.leftMargin:
        x = 0.02 + random.nextDouble() * 0.08; // 2-10% from left
        y = 0.1 + random.nextDouble() * 0.8; // 10-90% from top
        break;
      case AnnotationZone.rightMargin:
        x = 0.9 + random.nextDouble() * 0.08; // 90-98% from left
        y = 0.1 + random.nextDouble() * 0.8; // 10-90% from top
        break;
      case AnnotationZone.topMargin:
        x = 0.15 + random.nextDouble() * 0.7; // 15-85% from left
        y = 0.02 + random.nextDouble() * 0.08; // 2-10% from top
        break;
      case AnnotationZone.bottomMargin:
        x = 0.15 + random.nextDouble() * 0.7; // 15-85% from left
        y = 0.9 + random.nextDouble() * 0.08; // 90-98% from top
        break;
      case AnnotationZone.content:
        x = 0.2 + random.nextDouble() * 0.6; // 20-80% from left
        y = 0.15 + random.nextDouble() * 0.7; // 15-85% from top
        break;
    }
    
    return AnnotationPosition(
      zone: zone,
      x: x,
      y: y,
      rotation: (random.nextDouble() - 0.5) * 0.1, // Small rotation
    );
  }
  
  Future<void> saveProcessedData() async {
    // Create output directory
    final outputDirectory = Directory(outputDir);
    if (!await outputDirectory.exists()) {
      await outputDirectory.create(recursive: true);
    }
    
    // Save individual chapter data
    for (final chapter in chapters) {
      final chapterFile = File('$outputDir/${chapter.chapterName}.json');
      await chapterFile.writeAsString(jsonEncode(chapter.toJson()));
    }
    
    // Save complete book data
    final bookData = {
      'title': 'Blackthorn Manor: An Architectural Study',
      'author': 'Professor Harold Finch',
      'totalChapters': chapters.length,
      'totalPages': chapters.fold(0, (sum, chapter) => sum + chapter.pages.length),
      'totalAnnotations': annotations.length,
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
    };
    
    final bookFile = File('$outputDir/complete_book.json');
    await bookFile.writeAsString(jsonEncode(bookData));
    
    // Save character data
    final characterData = _generateCharacterData();
    final characterFile = File('$outputDir/characters.json');
    await characterFile.writeAsString(jsonEncode(characterData));
    
    print('   💾 Saved processed data to $outputDir');
  }
  
  Map<String, dynamic> _generateCharacterData() {
    final characters = <String, Map<String, dynamic>>{};
    
    // Define character information
    final characterInfo = {
      'MB': {
        'name': 'Margaret Blackthorn',
        'fullName': 'Margaret Blackthorn',
        'years': '1930-1999',
        'description': 'Last surviving member of the Blackthorn family. Maintained the estate and its secrets until her death.',
        'role': 'Family Guardian',
        'annotationStyle': {
          'fontFamily': 'Dancing Script',
          'fontSize': 10,
          'color': '#2653a3',
          'fontStyle': 'italic',
          'description': 'Elegant blue script'
        }
      },
      'JR': {
        'name': 'James Reed',
        'fullName': 'James Reed',
        'years': '1984-1990',
        'description': 'Independent researcher who investigated the manor\'s architectural anomalies. Disappeared in 1989.',
        'role': 'Researcher',
        'annotationStyle': {
          'fontFamily': 'Kalam',
          'fontSize': 9,
          'color': '#1a1a1a',
          'fontStyle': 'normal',
          'description': 'Messy black ballpoint'
        }
      },
      'EW': {
        'name': 'Eliza Winston',
        'fullName': 'Eliza Winston',
        'years': '1995-1999',
        'description': 'Structural engineer commissioned to assess the building\'s safety. Her reports raised serious concerns.',
        'role': 'Engineer',
        'annotationStyle': {
          'fontFamily': 'Architects Daughter',
          'fontSize': 10,
          'color': '#c41e3a',
          'fontStyle': 'normal',
          'description': 'Precise red pen'
        }
      },
      'SW': {
        'name': 'Simon Wells',
        'fullName': 'Simon Wells',
        'years': '2024+',
        'description': 'Current investigator exploring the manor\'s mysteries. His sister Claire also disappeared.',
        'role': 'Current Investigator',
        'annotationStyle': {
          'fontFamily': 'Kalam',
          'fontSize': 9,
          'color': '#2c2c2c',
          'fontStyle': 'normal',
          'description': 'Hurried pencil'
        }
      },
      'Detective Sharma': {
        'name': 'Detective Sharma',
        'fullName': 'Detective Moira Sharma',
        'years': '2024+',
        'description': 'County Police detective investigating the disappearances at Blackthorn Manor.',
        'role': 'Police Investigator',
        'annotationStyle': {
          'fontFamily': 'Courier Prime',
          'fontSize': 8,
          'color': '#006400',
          'fontStyle': 'normal',
          'description': 'Official green ink'
        }
      },
      'Dr. Chambers': {
        'name': 'Dr. Chambers',
        'fullName': 'Dr. E. Chambers',
        'years': '2024+',
        'description': 'Government analyst with Department 8, specializing in anomalous phenomena.',
        'role': 'Government Analyst',
        'annotationStyle': {
          'fontFamily': 'Courier Prime',
          'fontSize': 8,
          'color': '#000000',
          'fontStyle': 'normal',
          'description': 'Official black ink'
        }
      }
    };
    
    return {
      'characters': characterInfo,
      'temporalRules': {
        'pre2000': {
          'allowedTypes': ['marginalia'],
          'allowedZones': ['leftMargin', 'rightMargin', 'topMargin', 'bottomMargin'],
          'description': 'Pre-2000 annotations are fixed in margins only'
        },
        'post2000': {
          'allowedTypes': ['postIt', 'sticker'],
          'allowedZones': ['leftMargin', 'rightMargin', 'topMargin', 'bottomMargin', 'content'],
          'description': 'Post-2000 annotations can be placed anywhere and are draggable'
        }
      }
    };
  }
  
  void generateStatistics() {
    final totalPages = chapters.fold(0, (sum, chapter) => sum + chapter.pages.length);
    final totalWords = chapters.fold(0, (sum, chapter) => sum + chapter.wordCount);
    final totalAnnotations = annotations.length;
    
    // Character statistics
    final characterStats = <String, int>{};
    for (final annotation in annotations) {
      final character = _parseCharacter(annotation['character']);
      characterStats[character] = (characterStats[character] ?? 0) + 1;
    }
    
    // Year statistics
    final yearStats = <String, int>{};
    for (final annotation in annotations) {
      final year = annotation['year'];
      if (year != null) {
        final decade = '${(year ~/ 10) * 10}s';
        yearStats[decade] = (yearStats[decade] ?? 0) + 1;
      }
    }
    
    print('\n📊 CONTENT STATISTICS');
    print('   📚 Total Chapters: ${chapters.length}');
    print('   📄 Total Pages: $totalPages');
    print('   🔤 Total Words: ${totalWords.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}');
    print('   📝 Total Annotations: $totalAnnotations');
    print('   📖 Average Words per Page: ${(totalWords / totalPages).round()}');
    print('   📎 Average Annotations per Page: ${(totalAnnotations / totalPages).toStringAsFixed(1)}');
    
    print('\n👥 CHARACTER BREAKDOWN:');
    characterStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..forEach((entry) {
        print('   ${entry.key}: ${entry.value} annotations');
      });
    
    print('\n📅 TEMPORAL DISTRIBUTION:');
    yearStats.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))
      ..forEach((entry) {
        print('   ${entry.key}: ${entry.value} annotations');
      });
  }
}

// Data Classes
class ChapterData {
  final int chapterNumber;
  final String chapterName;
  final String filename;
  final String fullContent;
  final List<PageData> pages;
  final int wordCount;
  
  ChapterData({
    required this.chapterNumber,
    required this.chapterName,
    required this.filename,
    required this.fullContent,
    required this.pages,
    required this.wordCount,
  });
  
  Map<String, dynamic> toJson() => {
    'chapterNumber': chapterNumber,
    'chapterName': chapterName,
    'filename': filename,
    'wordCount': wordCount,
    'pageCount': pages.length,
    'pages': pages.map((p) => p.toJson()).toList(),
  };
}

class PageData {
  final int pageNumber;
  final String chapterName;
  final String content;
  final int wordCount;
  final List<AnnotationData> annotations;
  
  PageData({
    required this.pageNumber,
    required this.chapterName,
    required this.content,
    required this.wordCount,
    required this.annotations,
  });
  
  Map<String, dynamic> toJson() => {
    'pageNumber': pageNumber,
    'chapterName': chapterName,
    'content': content,
    'wordCount': wordCount,
    'annotationCount': annotations.length,
    'annotations': annotations.map((a) => a.toJson()).toList(),
  };
}

class AnnotationData {
  final String id;
  final String character;
  final String text;
  final AnnotationType type;
  final int? year;
  final AnnotationPosition position;
  final String chapterName;
  final int pageNumber;
  
  AnnotationData({
    required this.id,
    required this.character,
    required this.text,
    required this.type,
    required this.year,
    required this.position,
    required this.chapterName,
    required this.pageNumber,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'character': character,
    'text': text,
    'type': type.name,
    'year': year,
    'position': position.toJson(),
    'chapterName': chapterName,
    'pageNumber': pageNumber,
  };
}

class AnnotationPosition {
  final AnnotationZone zone;
  final double x;
  final double y;
  final double rotation;
  
  AnnotationPosition({
    required this.zone,
    required this.x,
    required this.y,
    required this.rotation,
  });
  
  Map<String, dynamic> toJson() => {
    'zone': zone.name,
    'x': x,
    'y': y,
    'rotation': rotation,
  };
}

enum AnnotationType {
  marginalia,
  postIt,
  redaction,
  stamp,
}

enum AnnotationZone {
  leftMargin,
  rightMargin,
  topMargin,
  bottomMargin,
  content,
}