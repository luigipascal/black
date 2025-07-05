import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'document_models.g.dart';

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

@JsonSerializable()
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

  factory AnnotationPosition.fromJson(Map<String, dynamic> json) =>
      _$AnnotationPositionFromJson(json);

  Map<String, dynamic> toJson() => _$AnnotationPositionToJson(this);

  @override
  List<Object?> get props => [zone, x, y, rotation];
}

@JsonSerializable()
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

  factory Annotation.fromJson(Map<String, dynamic> json) =>
      _$AnnotationFromJson(json);

  Map<String, dynamic> toJson() => _$AnnotationToJson(this);

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

@JsonSerializable()
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

  factory DocumentPage.fromJson(Map<String, dynamic> json) =>
      _$DocumentPageFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentPageToJson(this);

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

@JsonSerializable()
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

  factory Chapter.fromJson(Map<String, dynamic> json) =>
      _$ChapterFromJson(json);

  Map<String, dynamic> toJson() => _$ChapterToJson(this);

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

@JsonSerializable()
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

  factory AnnotationStyle.fromJson(Map<String, dynamic> json) =>
      _$AnnotationStyleFromJson(json);

  Map<String, dynamic> toJson() => _$AnnotationStyleToJson(this);

  @override
  List<Object?> get props => [fontFamily, fontSize, color, fontStyle, description];
}

@JsonSerializable()
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

  factory Character.fromJson(Map<String, dynamic> json) =>
      _$CharacterFromJson(json);

  Map<String, dynamic> toJson() => _$CharacterToJson(this);

  @override
  List<Object?> get props => [name, fullName, years, description, role, annotationStyle];
}

@JsonSerializable()
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

  factory BookData.fromJson(Map<String, dynamic> json) =>
      _$BookDataFromJson(json);

  Map<String, dynamic> toJson() => _$BookDataToJson(this);

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