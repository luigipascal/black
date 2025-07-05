# Blackthorn Manor - Interactive Document Experience

An interactive Flutter application that simulates a classified government document about a mysterious Victorian manor, revealing supernatural horror through temporal annotations and progressive content unlocking.

## 📖 Project Overview

Blackthorn Manor presents itself as an academic architectural study by Professor Harold Finch, but progressively reveals a supernatural horror story through marginalia annotations spanning decades (1960s-2026). Readers discover the truth about interdimensional entities, ancient containment systems, and government cover-ups through authentic-looking annotations and supplementary documents.

## 🏗️ Repository Structure

```
blackthorn-manor/
├── README.md                          # This file
├── content/                           # Book content and data
│   ├── chapters/                      # Individual chapter files
│   │   ├── CHAPTER_I_INTRODUCTION_AND_HISTORICAL_CONTEXT.md
│   │   ├── CHAPTER_II_ARCHITECTURAL_OVERVIEW.md
│   │   ├── ... (Chapters III-XI)
│   │   └── CHAPTER_XI_Preservation_Efforts_and_Modern_Status_Ongoing_Addendum_1979_2025_Compilation_.md
│   └── data/                         # Structured data files
│       └── annotations.json          # All annotations with metadata
├── flutter_app/                      # Flutter application
│   ├── DraggableMarginalia.dart      # Sample widget implementations
│   ├── PageWidget.dart
│   └── RedactableText.dart
├── docs/                             # Documentation
│   ├── cursor_implementation_guide.md # Original detailed specification
│   └── simplified_technical_specification.md # Simplified architecture
└── assets/                           # Static assets (textures, fonts, etc.)
```

## 🎭 Story Concept

### Dual Narrative Structure
- **Surface Layer**: Academic study of Victorian Gothic architecture
- **Hidden Layer**: Supernatural horror about interdimensional containment
- **Discovery Method**: Truth revealed through temporal annotations

### Key Characters
- **Margaret Blackthorn (MB)**: Last family member (1930-1999), elegant blue script
- **James Reed (JR)**: Independent researcher (1984-1990), messy black ballpoint
- **Eliza Winston (EW)**: Structural engineer (1995-1999), precise red pen
- **Simon Wells (SW)**: Current investigator (2024+), hurried pencil notes
- **Detective Sharma**: Police investigator (2024), green ink
- **Dr. Chambers**: Government analyst, official stamps

### Temporal Annotation System
- **Pre-2000**: Fixed marginalia (locked in page margins)
- **Post-2000**: Draggable post-its (can be moved anywhere)
- **Progressive revelation**: Content unlocks through user exploration

## 🎯 Core Features

### Interactive Elements
- **Dual reading modes**: Single page (mobile) vs. book spread (desktop)
- **Temporal annotation system**: Different behaviors based on date
- **Progressive content unlocking**: Redacted text reveals with exploration
- **Authentic document simulation**: Realistic aging, paper textures, government stamps
- **Character-specific styling**: Each annotator has unique handwriting and colors

### Technical Implementation
- **Responsive design**: Adapts to different screen sizes
- **Performance optimized**: Limited annotations per page, efficient rendering
- **Cross-platform**: iOS, Android, Web, Desktop support
- **Persistent state**: User positions and unlocks saved between sessions

## 📊 Data Structure

### Annotations Format
```json
{
  "id": "unique-identifier",
  "character": ["MB", "JR", "EW", "SW", "Detective Sharma", "Dr. Chambers"],
  "text": "Annotation content",
  "type": "marginalia" | "sticker" | "redaction",
  "year": 1987,
  "source": "inline",
  "chapter": "CHAPTER_I_INTRODUCTION_AND_HISTORICAL_CONTEXT"
}
```

### Chapter Structure
- **Markdown files**: Easy to edit and version control
- **Structured content**: Academic text with embedded annotation points
- **Progressive complexity**: Simple early chapters, complex later revelations

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- IDE (VS Code, Android Studio, or IntelliJ)

### Setup Instructions
1. **Clone the repository**
   ```bash
   git clone https://github.com/luigipascal/blackthorn-manor.git
   cd blackthorn-manor
   ```

2. **Process the content data**
   ```bash
   # This will be implemented in Step 2
   dart run tools/process_content.dart
   ```

3. **Set up the Flutter app**
   ```bash
   cd flutter_app
   flutter pub get
   flutter run
   ```

## 🎯 Current Status

**Phase 1-3 Complete!** 🎉 The interactive document experience is now fully functional:
- ✅ Complete content processing pipeline (99 pages, 361 annotations)
- ✅ Full Flutter architecture with data models and state management  
- ✅ Complete UI implementation with document reader
- ✅ Interactive annotation system (fixed marginalia + draggable post-its)
- ✅ Character system with authentic styling (6 unique annotators)
- ✅ Reading modes (single page & book spread)
- ✅ Character guide and annotation detail dialogs
- ✅ Persistent user progress and annotation positioning

📊 **[View Detailed Progress Summary](PROGRESS_SUMMARY.md)**  
🎯 **[View Phase 3 Completion Details](PHASE_3_COMPLETION_SUMMARY.md)**

Ready for Phase 4: Advanced Features & Polish!

## 🛠️ Development Roadmap

### Phase 1: Content Processing ✅ (COMPLETE)
- [x] Organize repository structure
- [x] Create content processing tools
- [x] Generate page-by-page data structure  
- [x] Set up annotation positioning system

### Phase 2: Flutter App Foundation ✅ (COMPLETE)
- [x] Create Flutter project structure
- [x] Implement basic page layout system
- [x] Add responsive design components
- [x] Set up state management (Provider)

### Phase 3: UI Implementation ✅ (COMPLETE)
- [x] Implement fixed marginalia widgets
- [x] Add draggable post-it functionality  
- [x] Create character-specific styling
- [x] Add position persistence
- [x] Build complete document reader interface
- [x] Add reading mode toggle (single page/book spread)
- [x] Create character guide and annotation dialogs

### Phase 4: Interactive Features (Week 5-6)
- [ ] Implement redaction/reveal system
- [ ] Add progressive content unlocking
- [ ] Create reading mode toggle
- [ ] Add zoom/pan functionality

### Phase 5: Polish & Deployment (Week 7-8)
- [ ] Add authentic visual effects
- [ ] Performance optimization
- [ ] Cross-platform testing
- [ ] App store deployment

## 🎨 Design Principles

### Authenticity
- **Realistic document appearance**: Aged paper, authentic typography
- **Period-appropriate styling**: Victorian Gothic architecture focus
- **Government document aesthetics**: Official stamps, classifications, redactions

### User Experience
- **Intuitive navigation**: Natural page turning, easy annotation access
- **Progressive discovery**: Gradual revelation maintains engagement
- **Responsive interactions**: Smooth dragging, satisfying unlocks

### Technical Excellence
- **Performance first**: 60fps target, efficient memory usage
- **Flutter-native**: Work with the framework, not against it
- **Maintainable code**: Clear architecture, comprehensive documentation

## 📝 Content Guidelines

### Writing Style
- **Academic tone**: Formal, scholarly language for main text
- **Character voices**: Each annotator has distinct personality
- **Progressive revelation**: Increasing supernatural elements

### Annotation Guidelines
- **Historical accuracy**: Dates and references must be consistent
- **Character consistency**: Each person's voice and knowledge level
- **Temporal logic**: Pre/post-2000 rules strictly enforced

## 🤝 Contributing

### Content Contributions
- **Story expansion**: Additional chapters, character development
- **Historical research**: Architectural accuracy, period details
- **Character development**: Backstories, motivations, relationships

### Technical Contributions
- **Flutter development**: UI components, performance optimization
- **Content processing**: Data parsing, annotation positioning
- **Asset creation**: Textures, fonts, visual effects

### Getting Involved
1. **Read the documentation**: Start with the simplified technical specification
2. **Explore the content**: Understand the story structure and characters
3. **Join discussions**: Issues and pull requests welcome
4. **Test the experience**: User feedback is invaluable

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **Victorian Gothic Architecture**: Historical accuracy research
- **Interactive Fiction Community**: Inspiration for narrative techniques
- **Flutter Community**: Technical implementation guidance
- **Horror Literature**: Atmospheric and narrative influences

---

*"The door opens in both directions." - The Watchers*