import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/document_models.dart';
import '../constants/app_theme.dart';
import '../providers/document_state.dart';
import '../services/content_loader.dart';
import 'annotation_widget.dart';
import 'document_background.dart';

class DocumentPageWidget extends StatelessWidget {
  final DocumentPage page;
  final ReadingMode readingMode;
  final bool isLeftPage;

  const DocumentPageWidget({
    super.key,
    required this.page,
    required this.readingMode,
    this.isLeftPage = false,
  });

  @override
  Widget build(BuildContext context) {
    final pageSize = PageDimensions.calculatePageSize(context, readingMode);
    final margins = PageDimensions.getPageMargins(pageSize);

    return Container(
      width: pageSize.width,
      height: pageSize.height,
      child: Stack(
        children: [
          // Layer 1: Document background
          DocumentBackground(pageSize: pageSize),
          
          // Layer 2: Main content
          Positioned.fill(
            child: Padding(
              padding: margins,
              child: _buildMainContent(context),
            ),
          ),
          
          // Layer 3: Fixed annotations (pre-2000)
          ...page.fixedAnnotations
              .take(PageDimensions.maxAnnotationsPerPage)
              .map((annotation) => AnnotationWidget(
                    annotation: annotation,
                    pageSize: pageSize,
                    margins: margins,
                  )),
          
          // Layer 4: Draggable annotations (post-2000)
          ...page.draggableAnnotations
              .take(PageDimensions.maxAnnotationsPerPage)
              .map((annotation) => AnnotationWidget(
                    annotation: annotation,
                    pageSize: pageSize,
                    margins: margins,
                  )),
          
          // Layer 5: Page number
          _buildPageNumber(pageSize),
          
          // Layer 6: Book effects (shadows, spine)
          if (readingMode == ReadingMode.bookSpread)
            _buildBookEffects(pageSize),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chapter title (if this is the first page of a chapter)
          if (_isFirstPageOfChapter())
            _buildChapterTitle(context),
          
          const SizedBox(height: 16),
          
          // Main document text
          _buildDocumentText(context),
        ],
      ),
    );
  }

  Widget _buildChapterTitle(BuildContext context) {
    final chapter = ContentLoader.getChapterForPage(page.pageNumber - 1);
    if (chapter == null) return const SizedBox.shrink();

    // Format chapter name for display
    final displayName = _formatChapterName(chapter.chapterName);

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

  Widget _buildDocumentText(BuildContext context) {
    return SelectableText(
      page.content,
      style: Theme.of(context).textTheme.bodyLarge,
      textAlign: TextAlign.justify,
    );
  }

  Widget _buildPageNumber(Size pageSize) {
    return Positioned(
      bottom: 16,
      left: isLeftPage ? 16 : null,
      right: isLeftPage ? null : 16,
      child: Text(
        '${page.pageNumber}',
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

  bool _isFirstPageOfChapter() {
    final chapter = ContentLoader.getChapterForPage(page.pageNumber - 1);
    if (chapter == null) return false;
    
    return chapter.pages.isNotEmpty && chapter.pages.first.pageNumber == page.pageNumber;
  }
}

// Helper widget for interactive page viewing with zoom/pan
class InteractiveDocumentPage extends StatelessWidget {
  final DocumentPage page;
  final ReadingMode readingMode;
  final bool isLeftPage;

  const InteractiveDocumentPage({
    super.key,
    required this.page,
    required this.readingMode,
    this.isLeftPage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<DocumentState>(
      builder: (context, documentState, child) {
        return InteractiveViewer(
          minScale: 0.8,
          maxScale: 3.0,
          onInteractionUpdate: (details) {
            // Update zoom and pan in state if needed
            // documentState.setZoomLevel(details.scale);
          },
          child: DocumentPageWidget(
            page: page,
            readingMode: readingMode,
            isLeftPage: isLeftPage,
          ),
        );
      },
    );
  }
}