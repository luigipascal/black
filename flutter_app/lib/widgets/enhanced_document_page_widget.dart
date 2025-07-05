import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_document_models.dart';
import '../providers/enhanced_revelation_provider.dart';
import '../constants/app_colors.dart';
import '../constants/character_fonts.dart';
import '../constants/app_theme.dart';
import '../services/content_loader.dart';
import 'enhanced_annotation_widget.dart';
import 'document_background.dart';
import 'redacted_content_widget.dart';

class EnhancedDocumentPageWidget extends StatelessWidget {
  final int pageNumber;
  final ReadingMode readingMode;
  final bool isLeftPage;

  const EnhancedDocumentPageWidget({
    super.key,
    required this.pageNumber,
    required this.readingMode,
    this.isLeftPage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedRevelationProvider>(
      builder: (context, revelationProvider, child) {
        return _buildPageContent(context, revelationProvider);
      },
    );
  }

  Widget _buildPageContent(BuildContext context, EnhancedRevelationProvider revelationProvider) {
    final pageSection = revelationProvider.getPageSection(pageNumber);
    final pageSize = PageDimensions.calculatePageSize(context, readingMode);
    final margins = PageDimensions.getPageMargins(pageSize);

    return Container(
      width: pageSize.width,
      height: pageSize.height,
      child: Stack(
        children: [
          // Layer 1: Document background with supernatural effects
          DocumentBackground(
            pageSize: pageSize,
            supernaturalMode: revelationProvider.currentRevelationLevel == RevealLevel.completeTruth,
          ),
          
          // Layer 2: Main content based on page section
          Positioned.fill(
            child: Padding(
              padding: margins,
              child: _buildSectionContent(context, revelationProvider, pageSection),
            ),
          ),
          
          // Layer 3: Enhanced annotations
          ..._buildEnhancedAnnotations(context, revelationProvider, pageSize, margins),
          
          // Layer 4: Revelation level indicator
          _buildRevelationIndicator(context, revelationProvider),
          
          // Layer 5: Page number with section indicator
          _buildEnhancedPageNumber(context, pageSection, pageSize),
          
          // Layer 6: Book effects and supernatural overlay
          if (readingMode == ReadingMode.bookSpread)
            _buildBookEffects(pageSize),
          
          // Layer 7: Discovery notifications
          if (revelationProvider.recentDiscoveries.isNotEmpty)
            _buildDiscoveryNotifications(context, revelationProvider),
        ],
      ),
    );
  }

  Widget _buildSectionContent(BuildContext context, EnhancedRevelationProvider revelationProvider, String section) {
    switch (section) {
      case 'front_matter':
        return _buildFrontMatterContent(context, revelationProvider);
      case 'back_matter':
        return _buildBackMatterContent(context, revelationProvider);
      case 'chapter':
      default:
        return _buildChapterContent(context, revelationProvider);
    }
  }

  Widget _buildFrontMatterContent(BuildContext context, EnhancedRevelationProvider revelationProvider) {
    final frontMatterPage = revelationProvider.getFrontMatterPage(pageNumber);
    if (frontMatterPage == null) {
      return const Center(child: Text('Front matter page not found'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Front matter title
          if (frontMatterPage['title'] != null)
            _buildFrontMatterTitle(context, frontMatterPage['title'] as String),
          
          const SizedBox(height: 24),
          
          // Front matter content
          _buildProcessedContent(context, frontMatterPage['content'] as String? ?? '', revelationProvider),
        ],
      ),
    );
  }

  Widget _buildBackMatterContent(BuildContext context, EnhancedRevelationProvider revelationProvider) {
    final backMatterPage = revelationProvider.getBackMatterPage(pageNumber - _getFrontMatterPageCount() - _getChapterPageCount());
    if (backMatterPage == null) {
      return const Center(child: Text('Back matter page not found'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back matter section title
          if (backMatterPage['title'] != null)
            _buildBackMatterTitle(context, backMatterPage['title'] as String),
          
          const SizedBox(height: 16),
          
          // Back matter content with embedded annotations
          _buildProcessedContent(context, backMatterPage['content'] as String? ?? '', revelationProvider),
        ],
      ),
    );
  }

  Widget _buildChapterContent(BuildContext context, EnhancedRevelationProvider revelationProvider) {
    final enhancedPage = revelationProvider.getEnhancedPage(pageNumber);
    if (enhancedPage == null) {
      return const Center(child: Text('Page not found'));
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chapter title (if this is the first page of a chapter)
          if (_isFirstPageOfChapter(enhancedPage))
            _buildChapterTitle(context, enhancedPage.chapterName),
          
          const SizedBox(height: 16),
          
          // Main document text with processed content
          _buildProcessedContent(context, enhancedPage.content, revelationProvider),
        ],
      ),
    );
  }

  Widget _buildFrontMatterTitle(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.marginaliaBlack,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          width: 200,
          color: AppTheme.marginaliaBlack.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildBackMatterTitle(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.marginaliaBlack,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          color: AppTheme.marginaliaBlack.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildChapterTitle(BuildContext context, String chapterName) {
    final displayName = _formatChapterName(chapterName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          color: AppTheme.marginaliaBlack.withOpacity(0.3),
        ),
      ],
    );
  }

  Widget _buildProcessedContent(BuildContext context, String content, EnhancedRevelationProvider revelationProvider) {
    // Split content into segments to handle redacted sections
    final segments = _processContentSegments(content, revelationProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((segment) {
        if (segment['type'] == 'redacted') {
          return RedactedContentWidget(
            redactedContent: segment['data'] as RedactedContent,
            isRevealed: revelationProvider.isRedactionRevealed(segment['data'] as RedactedContent),
            onReveal: () {
              revelationProvider.revealRedaction((segment['data'] as RedactedContent).hiddenText);
            },
          );
        } else {
          return SelectableText(
            segment['data'] as String,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.justify,
          );
        }
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _processContentSegments(String content, EnhancedRevelationProvider revelationProvider) {
    final segments = <Map<String, dynamic>>[];
    final redactedContent = ContentLoader.getRedactedContent();
    
    // For now, return simple text segments
    // In a full implementation, this would parse redacted sections
    segments.add({
      'type': 'text',
      'data': content,
    });
    
    return segments;
  }

  List<Widget> _buildEnhancedAnnotations(
    BuildContext context,
    EnhancedRevelationProvider revelationProvider,
    Size pageSize,
    EdgeInsets margins,
  ) {
    final annotations = revelationProvider.getVisibleAnnotationsForPage(pageNumber);
    
    return annotations.map((annotation) {
      return EnhancedAnnotationWidget(
        annotation: annotation,
        pageSize: pageSize,
        margins: margins,
        onTap: () {
          // Handle annotation tap - discover character if not already discovered
          revelationProvider.discoverCharacter(annotation.character);
          revelationProvider.unlockAnnotation(annotation.id);
        },
      );
    }).toList();
  }

  Widget _buildRevelationIndicator(BuildContext context, EnhancedRevelationProvider revelationProvider) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getRevelationLevelColor(revelationProvider.currentRevelationLevel),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 1),
        ),
        child: Text(
          'Level ${revelationProvider.currentRevelationLevel.level}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getRevelationLevelColor(RevealLevel level) {
    switch (level) {
      case RevealLevel.academic:
        return Colors.grey;
      case RevealLevel.familySecrets:
        return Colors.blue;
      case RevealLevel.investigation:
        return Colors.orange;
      case RevealLevel.modernMystery:
        return Colors.red;
      case RevealLevel.completeTruth:
        return Colors.purple;
    }
  }

  Widget _buildEnhancedPageNumber(BuildContext context, String section, Size pageSize) {
    String sectionIndicator = '';
    switch (section) {
      case 'front_matter':
        sectionIndicator = 'F-';
        break;
      case 'back_matter':
        sectionIndicator = 'A-';
        break;
      case 'chapter':
      default:
        sectionIndicator = '';
        break;
    }

    return Positioned(
      bottom: 16,
      left: isLeftPage ? 16 : null,
      right: isLeftPage ? null : 16,
      child: Text(
        '$sectionIndicator${pageNumber + 1}',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }

  Widget _buildBookEffects(Size pageSize) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isLeftPage ? Alignment.centerRight : Alignment.centerLeft,
          end: isLeftPage ? Alignment.centerLeft : Alignment.centerRight,
          colors: [
            Colors.black.withOpacity(0.1), // Shadow near spine
            Colors.transparent,
          ],
          stops: const [0.0, 0.15],
        ),
      ),
    );
  }

  Widget _buildDiscoveryNotifications(BuildContext context, EnhancedRevelationProvider revelationProvider) {
    return Positioned(
      top: 50,
      right: 8,
      child: Container(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: revelationProvider.recentDiscoveries.take(3).map((discovery) {
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text(
                discovery,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatChapterName(String chapterName) {
    // Convert "CHAPTER_I_INTRODUCTION_AND_HISTORICAL_CONTEXT" to "Chapter I: Introduction and Historical Context"
    final parts = chapterName.split('_');
    if (parts.length < 3) return chapterName;

    final chapterNumber = parts[1]; // Roman numeral
    final titleParts = parts.sublist(2);
    final title = titleParts.map((part) => _capitalizeFirst(part.toLowerCase())).join(' ');

    return 'Chapter $chapterNumber: $title';
  }

  String _capitalizeFirst(String word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1);
  }

  bool _isFirstPageOfChapter(EnhancedDocumentPage page) {
    final chapter = ContentLoader.getChapterForPage(page.pageNumber - 1);
    if (chapter == null) return false;
    
    return chapter.pages.isNotEmpty && chapter.pages.first.pageNumber == page.pageNumber;
  }

  int _getFrontMatterPageCount() {
    // This would normally be loaded from ContentLoader
    return 10; // Placeholder
  }

  int _getChapterPageCount() {
    // This would normally be loaded from ContentLoader
    return 99; // Placeholder
  }
}

// Helper widget for interactive enhanced page viewing
class InteractiveEnhancedDocumentPage extends StatelessWidget {
  final int pageNumber;
  final ReadingMode readingMode;
  final bool isLeftPage;

  const InteractiveEnhancedDocumentPage({
    super.key,
    required this.pageNumber,
    required this.readingMode,
    this.isLeftPage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<EnhancedRevelationProvider>(
      builder: (context, revelationProvider, child) {
        return InteractiveViewer(
          minScale: 0.8,
          maxScale: 3.0,
          child: EnhancedDocumentPageWidget(
            pageNumber: pageNumber,
            readingMode: readingMode,
            isLeftPage: isLeftPage,
          ),
        );
      },
    );
  }
}

// Custom painter for paper texture
class PaperTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.2, 0.2),
        radius: 1.0,
        colors: [
          const Color(0xFF8B4513).withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Add second gradient for aged effect
    final paint2 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, 0.8),
        radius: 1.0,
        colors: [
          const Color(0xFF8B4513).withOpacity(0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Gesture recognizer import
import 'package:flutter/gestures.dart';