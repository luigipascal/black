import 'package:equatable/equatable.dart';

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

enum ReadingMode {
  singlePage,
  bookSpread,
}

class AnnotationPosition extends Equatable {
  final AnnotationZone zone;
  final double x;
  final double y;
  final double rotation;

  const AnnotationPosition({
    required this.zone,
    required this.x,
    required this.y,
    required this.rotation,
  });

  factory AnnotationPosition.fromJson(Map<String, dynamic> json) {
    return AnnotationPosition(
      zone: AnnotationZone.values.firstWhere(
        (e) => e.name == json['zone'],
        orElse: () => AnnotationZone.leftMargin,
      ),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'zone': zone.name,
    'x': x,
    'y': y,
    'rotation': rotation,
  };

  @override
  List<Object?> get props => [zone, x, y, rotation];
}

class Annotation extends Equatable {
  final String id;
  final String character;
  final String text;
  final AnnotationType type;
  final int? year;
  final AnnotationPosition position;
  final String chapterName;
  final int pageNumber;

  const Annotation({
    required this.id,
    required this.character,
    required this.text,
    required this.type,
    required this.year,
    required this.position,
    required this.chapterName,
    required this.pageNumber,
  });

  factory Annotation.fromJson(Map<String, dynamic> json) {
    return Annotation(
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
  };

  bool get isPre2000 => year == null || year! < 2000;
  bool get isPost2000 => year != null && year! >= 2000;

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
      ];
}

class DocumentPage extends Equatable {
  final int pageNumber;
  final String chapterName;
  final String content;
  final int wordCount;
  final int annotationCount;
  final List<Annotation> annotations;

  const DocumentPage({
    required this.pageNumber,
    required this.chapterName,
    required this.content,
    required this.wordCount,
    required this.annotationCount,
    required this.annotations,
  });

  factory DocumentPage.fromJson(Map<String, dynamic> json) {
    return DocumentPage(
      pageNumber: json['pageNumber'] as int,
      chapterName: json['chapterName'] as String,
      content: json['content'] as String,
      wordCount: json['wordCount'] as int,
      annotationCount: json['annotationCount'] as int? ?? 0,
      annotations: (json['annotations'] as List<dynamic>?)
          ?.map((e) => Annotation.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'pageNumber': pageNumber,
    'chapterName': chapterName,
    'content': content,
    'wordCount': wordCount,
    'annotationCount': annotationCount,
    'annotations': annotations.map((e) => e.toJson()).toList(),
  };

  List<Annotation> get fixedAnnotations =>
      annotations.where((a) => a.isPre2000).toList();

  List<Annotation> get draggableAnnotations =>
      annotations.where((a) => a.isPost2000).toList();

  @override
  List<Object?> get props => [
        pageNumber,
        chapterName,
        content,
        wordCount,
        annotationCount,
        annotations,
      ];
}

class Chapter extends Equatable {
  final int chapterNumber;
  final String chapterName;
  final String filename;
  final int wordCount;
  final int pageCount;
  final List<DocumentPage> pages;

  const Chapter({
    required this.chapterNumber,
    required this.chapterName,
    required this.filename,
    required this.wordCount,
    required this.pageCount,
    required this.pages,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      chapterNumber: json['chapterNumber'] as int,
      chapterName: json['chapterName'] as String,
      filename: json['filename'] as String,
      wordCount: json['wordCount'] as int,
      pageCount: json['pageCount'] as int,
      pages: (json['pages'] as List<dynamic>)
          .map((e) => DocumentPage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'chapterNumber': chapterNumber,
    'chapterName': chapterName,
    'filename': filename,
    'wordCount': wordCount,
    'pageCount': pageCount,
    'pages': pages.map((e) => e.toJson()).toList(),
  };

  @override
  List<Object?> get props => [
        chapterNumber,
        chapterName,
        filename,
        wordCount,
        pageCount,
        pages,
      ];
}

class AnnotationStyle extends Equatable {
  final String fontFamily;
  final int fontSize;
  final String color;
  final String fontStyle;
  final String description;

  const AnnotationStyle({
    required this.fontFamily,
    required this.fontSize,
    required this.color,
    required this.fontStyle,
    required this.description,
  });

  factory AnnotationStyle.fromJson(Map<String, dynamic> json) {
    return AnnotationStyle(
      fontFamily: json['fontFamily'] as String,
      fontSize: json['fontSize'] as int,
      color: json['color'] as String,
      fontStyle: json['fontStyle'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'fontFamily': fontFamily,
    'fontSize': fontSize,
    'color': color,
    'fontStyle': fontStyle,
    'description': description,
  };

  @override
  List<Object?> get props => [fontFamily, fontSize, color, fontStyle, description];
}

class Character extends Equatable {
  final String name;
  final String fullName;
  final String years;
  final String description;
  final String role;
  final AnnotationStyle annotationStyle;

  const Character({
    required this.name,
    required this.fullName,
    required this.years,
    required this.description,
    required this.role,
    required this.annotationStyle,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      name: json['name'] as String,
      fullName: json['fullName'] as String,
      years: json['years'] as String,
      description: json['description'] as String,
      role: json['role'] as String,
      annotationStyle: AnnotationStyle.fromJson(
        json['annotationStyle'] as Map<String, dynamic>
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'fullName': fullName,
    'years': years,
    'description': description,
    'role': role,
    'annotationStyle': annotationStyle.toJson(),
  };

  @override
  List<Object?> get props => [name, fullName, years, description, role, annotationStyle];
}

class BookData extends Equatable {
  final String title;
  final String author;
  final int totalChapters;
  final int totalPages;
  final int totalAnnotations;
  final List<Chapter> chapters;

  const BookData({
    required this.title,
    required this.author,
    required this.totalChapters,
    required this.totalPages,
    required this.totalAnnotations,
    required this.chapters,
  });

  factory BookData.fromJson(Map<String, dynamic> json) {
    return BookData(
      title: json['title'] as String,
      author: json['author'] as String,
      totalChapters: json['totalChapters'] as int,
      totalPages: json['totalPages'] as int,
      totalAnnotations: json['totalAnnotations'] as int,
      chapters: (json['chapters'] as List<dynamic>)
          .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'author': author,
    'totalChapters': totalChapters,
    'totalPages': totalPages,
    'totalAnnotations': totalAnnotations,
    'chapters': chapters.map((e) => e.toJson()).toList(),
  };

  @override
  List<Object?> get props => [
        title,
        author,
        totalChapters,
        totalPages,
        totalAnnotations,
        chapters,
      ];
}