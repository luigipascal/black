# BLACKTHORN MANOR – SIMPLIFIED TECHNICAL SPECIFICATION

## PROJECT OVERVIEW

### Core Concept
An interactive digital book that simulates a classified government document. Readers explore progressively revealed supernatural content hidden within an academic architectural study through authentic-looking annotations spanning decades.

### Key Simplifications
- **Responsive layouts** instead of fixed dimensions
- **Zone-based positioning** instead of pixel-perfect placement
- **Limited annotations per page** for better performance
- **Simplified state management** with clear data flow
- **Progressive complexity** with MVP first approach

---

## TECHNICAL ARCHITECTURE

### Core Principles
1. **Flutter-native approach** - Work with the framework, not against it
2. **Performance first** - Smooth 60fps interactions
3. **Responsive design** - Scales gracefully across devices
4. **Maintainable code** - Clear separation of concerns
5. **Incremental complexity** - Build and test in phases

### Layout System
```dart
// Responsive page layout with proportional margins
class PageLayout {
  static const double marginRatio = 0.12; // 12% margins
  static const double aspectRatio = 11.0 / 8.5; // Letter paper
  static const int maxAnnotationsPerPage = 8; // Performance limit
  
  static Size calculatePageSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxWidth = screenSize.width * 0.9;
    final maxHeight = screenSize.height * 0.85;
    
    // Calculate size maintaining aspect ratio
    final widthConstrainedHeight = maxWidth * aspectRatio;
    if (widthConstrainedHeight <= maxHeight) {
      return Size(maxWidth, widthConstrainedHeight);
    } else {
      return Size(maxHeight / aspectRatio, maxHeight);
    }
  }
}
```

### Annotation System
```dart
// Zone-based positioning for reliability
enum AnnotationZone {
  leftMargin,
  rightMargin,
  topMargin,
  bottomMargin,
  content, // Post-2000 annotations only
}

enum AnnotationType {
  marginalia, // Pre-2000, fixed in margins
  postIt,     // Post-2000, draggable anywhere
  redaction,  // Academic documents only
  stamp,      // Government markings
}
```

---

## CORE WIDGETS

### 1. Document Page Widget
```dart
class DocumentPageWidget extends StatefulWidget {
  final DocumentPageData pageData;
  final ReadingMode readingMode;
  
  @override
  _DocumentPageWidgetState createState() => _DocumentPageWidgetState();
}

class _DocumentPageWidgetState extends State<DocumentPageWidget> {
  @override
  Widget build(BuildContext context) {
    final pageSize = PageLayout.calculatePageSize(context);
    
    return Container(
      width: pageSize.width,
      height: pageSize.height,
      child: Stack(
        children: [
          // Layer 1: Document background
          DocumentBackground(type: widget.pageData.documentType),
          
          // Layer 2: Main content
          Positioned.fill(
            child: Padding(
              padding: PageLayout.getMargins(pageSize),
              child: MainContentWidget(content: widget.pageData.content),
            ),
          ),
          
          // Layer 3: Annotations (limited to maxAnnotationsPerPage)
          ...widget.pageData.annotations
              .take(PageLayout.maxAnnotationsPerPage)
              .map((annotation) => AnnotationWidget(
                    annotation: annotation,
                    pageSize: pageSize,
                  )),
        ],
      ),
    );
  }
}
```

### 2. Annotation Widget
```dart
class AnnotationWidget extends StatefulWidget {
  final Annotation annotation;
  final Size pageSize;
  
  @override
  _AnnotationWidgetState createState() => _AnnotationWidgetState();
}

class _AnnotationWidgetState extends State<AnnotationWidget> {
  @override
  Widget build(BuildContext context) {
    switch (widget.annotation.type) {
      case AnnotationType.marginalia:
        return FixedMarginaliaWidget(
          annotation: widget.annotation,
          pageSize: widget.pageSize,
        );
      case AnnotationType.postIt:
        return DraggablePostItWidget(
          annotation: widget.annotation,
          pageSize: widget.pageSize,
        );
      case AnnotationType.redaction:
        return RedactionWidget(
          annotation: widget.annotation,
        );
      default:
        return Container();
    }
  }
}
```

### 3. Draggable Post-It (Simplified)
```dart
class DraggablePostItWidget extends StatefulWidget {
  final Annotation annotation;
  final Size pageSize;
  
  @override
  _DraggablePostItWidgetState createState() => _DraggablePostItWidgetState();
}

class _DraggablePostItWidgetState extends State<DraggablePostItWidget> {
  Offset _position = Offset.zero;
  
  @override
  void initState() {
    super.initState();
    _position = _getInitialPosition();
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Draggable<Annotation>(
        data: widget.annotation,
        feedback: Material(
          color: Colors.transparent,
          child: _buildPostItContent(isDragging: true),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildPostItContent(),
        ),
        onDragEnd: (details) {
          setState(() {
            _position = _constrainPosition(details.offset);
          });
          _savePosition();
        },
        child: GestureDetector(
          onTap: () => _showContent(),
          child: _buildPostItContent(),
        ),
      ),
    );
  }
  
  Widget _buildPostItContent({bool isDragging = false}) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: widget.pageSize.width * 0.3, // 30% of page width
        minWidth: 80,
      ),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getPostItColor(),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isDragging ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(2, 2),
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Text(
        widget.annotation.text,
        style: _getTextStyle(),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
  
  Offset _constrainPosition(Offset position) {
    // Keep within page bounds
    final maxX = widget.pageSize.width - 120; // Account for post-it width
    final maxY = widget.pageSize.height - 60; // Account for post-it height
    
    return Offset(
      position.dx.clamp(0.0, maxX),
      position.dy.clamp(0.0, maxY),
    );
  }
  
  // Simplified position persistence
  void _savePosition() {
    context.read<DocumentState>().updateAnnotationPosition(
      widget.annotation.id,
      _position,
    );
  }
}
```

---

## SIMPLIFIED DATA MODELS

### Document Page Data
```dart
class DocumentPageData {
  final int pageNumber;
  final DocumentType documentType;
  final String content; // HTML or markdown for rich text
  final List<Annotation> annotations;
  
  DocumentPageData({
    required this.pageNumber,
    required this.documentType,
    required this.content,
    this.annotations = const [],
  });
  
  // Limit annotations for performance
  List<Annotation> get limitedAnnotations => 
      annotations.take(PageLayout.maxAnnotationsPerPage).toList();
}
```

### Annotation Model
```dart
class Annotation {
  final String id;
  final AnnotationType type;
  final String author;
  final DateTime date;
  final String text;
  final AnnotationZone zone;
  final Offset? customPosition; // For post-its only
  final Map<String, dynamic> metadata;
  
  Annotation({
    required this.id,
    required this.type,
    required this.author,
    required this.date,
    required this.text,
    required this.zone,
    this.customPosition,
    this.metadata = const {},
  });
  
  // Validation rules
  bool get isValid {
    switch (type) {
      case AnnotationType.marginalia:
        return date.year <= 1999 && zone != AnnotationZone.content;
      case AnnotationType.postIt:
        return date.year >= 2000;
      default:
        return true;
    }
  }
}
```

---

## STATE MANAGEMENT (SIMPLIFIED)

### Document State Provider
```dart
class DocumentState extends ChangeNotifier {
  int _currentPage = 0;
  ReadingMode _readingMode = ReadingMode.singlePage;
  Map<String, Offset> _annotationPositions = {};
  Set<String> _unlockedContent = {};
  
  // Getters
  int get currentPage => _currentPage;
  ReadingMode get readingMode => _readingMode;
  Map<String, Offset> get annotationPositions => Map.unmodifiable(_annotationPositions);
  
  // Page navigation
  void setCurrentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }
  
  // Annotation position management
  void updateAnnotationPosition(String id, Offset position) {
    _annotationPositions[id] = position;
    _saveToStorage();
    notifyListeners();
  }
  
  // Content unlocking
  void unlockContent(String contentId) {
    _unlockedContent.add(contentId);
    _saveToStorage();
    notifyListeners();
  }
  
  bool isContentUnlocked(String contentId) {
    return _unlockedContent.contains(contentId);
  }
  
  // Simplified persistence
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('annotation_positions', jsonEncode(
      _annotationPositions.map((k, v) => MapEntry(k, {'x': v.dx, 'y': v.dy}))
    ));
    await prefs.setStringList('unlocked_content', _unlockedContent.toList());
  }
  
  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load positions
    final positionsJson = prefs.getString('annotation_positions');
    if (positionsJson != null) {
      final positions = jsonDecode(positionsJson) as Map<String, dynamic>;
      _annotationPositions = positions.map((k, v) => 
        MapEntry(k, Offset(v['x'], v['y']))
      );
    }
    
    // Load unlocked content
    final unlocked = prefs.getStringList('unlocked_content');
    if (unlocked != null) {
      _unlockedContent = unlocked.toSet();
    }
    
    notifyListeners();
  }
}
```

---

## READING MODES

### Single Page Mode (Mobile-First)
```dart
class SinglePageReader extends StatelessWidget {
  final List<DocumentPageData> pages;
  final int currentPage;
  final Function(int) onPageChanged;
  
  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: PageController(initialPage: currentPage),
      onPageChanged: onPageChanged,
      itemCount: pages.length,
      itemBuilder: (context, index) {
        return InteractiveViewer(
          minScale: 0.8,
          maxScale: 3.0,
          child: DocumentPageWidget(
            pageData: pages[index],
            readingMode: ReadingMode.singlePage,
          ),
        );
      },
    );
  }
}
```

### Book Spread Mode (Desktop/Tablet)
```dart
class BookSpreadReader extends StatelessWidget {
  final List<DocumentPageData> pages;
  final int currentPage;
  final Function(int) onPageChanged;
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left page
        if (currentPage > 0)
          Expanded(
            child: DocumentPageWidget(
              pageData: pages[currentPage - 1],
              readingMode: ReadingMode.bookSpread,
            ),
          ),
        
        // Spine
        Container(
          width: 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black26, Colors.transparent, Colors.black26],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        
        // Right page
        if (currentPage < pages.length)
          Expanded(
            child: DocumentPageWidget(
              pageData: pages[currentPage],
              readingMode: ReadingMode.bookSpread,
            ),
          ),
      ],
    );
  }
}
```

---

## PERFORMANCE OPTIMIZATIONS

### 1. Annotation Limiting
```dart
class AnnotationManager {
  static const int maxAnnotationsPerPage = 8;
  static const int maxDraggableAnnotations = 3;
  
  static List<Annotation> optimizeAnnotations(List<Annotation> annotations) {
    // Prioritize by importance/date
    final sorted = annotations.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    
    final marginalia = sorted.where((a) => a.type == AnnotationType.marginalia).take(5);
    final postIts = sorted.where((a) => a.type == AnnotationType.postIt).take(3);
    
    return [...marginalia, ...postIts];
  }
}
```

### 2. Lazy Loading
```dart
class DocumentLoader {
  static Future<List<DocumentPageData>> loadPages({
    required int startPage,
    required int pageCount,
  }) async {
    // Load pages in chunks for better performance
    final pages = <DocumentPageData>[];
    
    for (int i = startPage; i < startPage + pageCount; i++) {
      final pageData = await _loadSinglePage(i);
      pages.add(pageData);
    }
    
    return pages;
  }
  
  static Future<DocumentPageData> _loadSinglePage(int pageNumber) async {
    // Simulate loading with delay
    await Future.delayed(Duration(milliseconds: 100));
    
    return DocumentPageData(
      pageNumber: pageNumber,
      documentType: DocumentType.academic,
      content: _generateContent(pageNumber),
      annotations: _generateAnnotations(pageNumber),
    );
  }
}
```

---

## IMPLEMENTATION ROADMAP

### Phase 1: MVP (2 weeks)
**Goal**: Basic reading experience with static content

- [ ] Basic page layout with responsive margins
- [ ] Simple content display (text only)
- [ ] Page navigation (swipe/buttons)
- [ ] Reading mode toggle
- [ ] Basic state management

**Success Criteria**:
- App loads and displays content
- Page navigation works smoothly
- Layout adapts to different screen sizes

### Phase 2: Static Annotations (2 weeks)
**Goal**: Add non-interactive annotations

- [ ] Fixed marginalia display (pre-2000)
- [ ] Author-specific styling
- [ ] Tap-to-expand for annotations
- [ ] Basic annotation positioning

**Success Criteria**:
- Annotations display correctly
- Different authors have distinct styles
- Annotations don't overlap with main content

### Phase 3: Interactive Elements (2 weeks)
**Goal**: Add draggable post-its and basic interactivity

- [ ] Draggable post-it notes (post-2000)
- [ ] Position persistence
- [ ] Basic gesture handling
- [ ] Simple animation effects

**Success Criteria**:
- Post-its can be dragged smoothly
- Positions save between sessions
- No performance issues with interactions

### Phase 4: Content Unlocking (2 weeks)
**Goal**: Add redaction system and content progression

- [ ] Redacted text display
- [ ] Unlock mechanism (without payment)
- [ ] Content reveal animations
- [ ] Progress tracking

**Success Criteria**:
- Redacted content shows appropriately
- Unlock system works reliably
- Animations are smooth and satisfying

### Phase 5: Polish & Optimization (1 week)
**Goal**: Performance optimization and bug fixes

- [ ] Performance profiling and optimization
- [ ] Bug fixes and edge case handling
- [ ] Visual polish and effects
- [ ] Cross-platform testing

**Success Criteria**:
- App maintains 60fps during all interactions
- No crashes or major bugs
- Consistent experience across platforms

---

## TECHNICAL REQUIREMENTS

### Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5
  shared_preferences: ^2.2.0
  flutter_widget_from_html: ^0.10.5
  cached_network_image: ^3.2.3
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
```

### Platform Targets
- **Primary**: Android, iOS
- **Secondary**: Web, Desktop (with responsive adjustments)

### Performance Targets
- **Frame rate**: 60fps during all interactions
- **Memory usage**: <200MB for typical document
- **Load time**: <3 seconds for page transitions

---

## CONCLUSION

This simplified specification maintains the core concept of Blackthorn Manor while being technically achievable in Flutter. The key changes are:

1. **Responsive layouts** instead of fixed dimensions
2. **Limited annotations** for better performance
3. **Zone-based positioning** for reliability
4. **Simplified state management** for maintainability
5. **Progressive implementation** to validate concepts early

The result should be a compelling interactive document experience that can be built, maintained, and scaled effectively while preserving the essential storytelling elements that make the concept unique.